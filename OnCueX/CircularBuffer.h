//
//  CircularBuffer.h
//  OnCueX
//
//  Created by Daniel Pourhadi on 7/8/15.
//  Copyright © 2015 Daniel Pourhadi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CircularBuffer : NSObject

- (void)add:(const void*)bytes length:(int32_t)length;
- (void)copy:(int32_t)length intoBuffer:(void*)buffer;

- (void)reset;

@end
