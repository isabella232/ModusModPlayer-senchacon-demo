//
//  MC_XMP.h
//  TicTacToe
//
//  Created by Jesus Garcia on 4/13/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <xmp.h>
#import <AudioToolbox/AudioToolbox.h>



@interface MC_XMP : NSObject

@property xmp_context xmpContext;


- (NSDictionary *) loadFile:(NSString *)path;

- (void) fillBuffer:(AudioQueueBuffer *)mBuffer;
- (NSDictionary *)getInfo:(NSString *)path;

@end
