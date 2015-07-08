//
//  CircularBuffer.m
//  OnCueX
//
//  Created by Daniel Pourhadi on 7/8/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

#import "CircularBuffer.h"
#import "TPCircularBuffer.h"
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

- (id)init
{
    if (self = [super init]) {
        TPCircularBufferInit(&_buffer, kTotalBufferSize);
    }
    return self;
}

- (void)add:(const void*)bytes length:(int32_t)length {
    TPCircularBufferProduceBytes(&_buffer, bytes, length);
}

- (void)copy:(int32_t)length intoBuffer:(void*)buffer {
    int32_t availableBytes;
    void *bufferTail     = TPCircularBufferTail(&_buffer, &availableBytes);
//    memcpy(outSample, bufferTail, MIN(availableBytes, inNumberFrames * kUnitSize * 2) );
    memcpy(buffer, bufferTail, MIN(availableBytes, length) );
    TPCircularBufferConsume(&_buffer, MIN(availableBytes, length) );
}

- (void)reset
{
    TPCircularBufferClear(&_buffer);
    TPCircularBufferCleanup(&_buffer);
}

@end
