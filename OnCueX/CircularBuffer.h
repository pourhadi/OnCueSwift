//
//  CircularBuffer.h
//  OnCueX
//
//  Created by Daniel Pourhadi on 7/8/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreAudio;
@interface CircularBuffer : NSObject

- (void)add:(const void*)bytes length:(int32_t)length;
- (int32_t)copy:(int32_t)length intoBuffer:(void*)buffer;

- (void)add:(AudioBufferList*)bufferList frames:(UInt32)frames description:(AudioStreamBasicDescription)description;
- (AudioBufferList*)getNextBuffer;

- (UInt32)getFrames:(UInt32)numOfFrames format:(AudioStreamBasicDescription)format buffer:(AudioBufferList*)buffer;

- (void)consumeBufferList;
- (void)reset;

@end
