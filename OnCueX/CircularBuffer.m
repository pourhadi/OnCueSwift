//
//  CircularBuffer.m
//  OnCueX
//
//  Created by Daniel Pourhadi on 7/8/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

#import "CircularBuffer.h"
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"
@import CoreAudio;

#define kUnitSize sizeof(Float32)
#define kBufferUnit 655360
#define kTotalBufferSize kBufferUnit * kUnitSize

@interface CircularBuffer()
{
    TPCircularBuffer _buffer;
}
@end

@implementation CircularBuffer

- (BOOL)add:(AudioBufferList*)bufferList frames:(UInt32)frames description:(AudioStreamBasicDescription)description
{
    return TPCircularBufferCopyAudioBufferList(&_buffer, bufferList, nil, kTPCircularBufferCopyAll, NULL);
}

- (UInt32)getFrames:(UInt32)numOfFrames format:(AudioStreamBasicDescription)format buffer:(AudioBufferList*)buffer {
    UInt32 frames = numOfFrames;
    TPCircularBufferDequeueBufferListFrames(&_buffer, &frames, buffer, NULL, &format);
    return frames;
}

- (AudioBufferList*)getNextBuffer {
    AudioBufferList *list = TPCircularBufferNextBufferList(&_buffer, nil);
    return list;
}

- (void)consumeBufferList {
    TPCircularBufferConsumeNextBufferList(&_buffer);
}

- (id)init
{
    if (self = [super init]) {
        TPCircularBufferInit(&_buffer, kTotalBufferSize);
    }
    return self;
}

- (void)add:(const void*)bytes length:(int32_t)length {
    if (!(TPCircularBufferProduceBytes(&_buffer, bytes, length))) {
        NSLog(@"error reading into buffer");
    }
}

- (int32_t)copy:(int32_t)length intoBuffer:(void*)buffer {
    int32_t availableBytes;
    void *bufferTail     = TPCircularBufferTail(&_buffer, &availableBytes);
//    memcpy(outSample, bufferTail, MIN(availableBytes, inNumberFrames * kUnitSize * 2) );
    memcpy(buffer, bufferTail, MIN(availableBytes, length) );
    TPCircularBufferConsume(&_buffer, MIN(availableBytes, length) );
    return MIN(availableBytes, length);
}

- (void)reset
{
    TPCircularBufferClear(&_buffer);
    TPCircularBufferCleanup(&_buffer);
    TPCircularBufferInit(&_buffer, kTotalBufferSize);
}

@end
