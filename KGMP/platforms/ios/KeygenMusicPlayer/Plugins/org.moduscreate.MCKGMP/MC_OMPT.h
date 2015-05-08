//
//  MC_MP.h
//  TicTacToe
//
//  Created by Jesus Garcia on 4/13/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <libopenmpt.h>
#import <libopenmpt_stream_callbacks_file.h>

@interface MC_OMPT : NSObject {

    AudioQueueRef mAudioQueue;
    AudioQueueBufferRef *mBuffers;
    

    BOOL modPlugSettingsCommitted,
         patternDataReady,         // Used to detect when a pattern read thread is done
         audioShouldStop;          // Used to detect if a sound thread should exit
    
    NSThread *soundThread;

    // An Object to produce the JSON below.
    NSMutableDictionary *songPatterns;

}


@property openmpt_module *mod;

- (NSDictionary *) loadFile:(NSString *)path;

- (int32_t*) fillBuffer:(AudioQueueBuffer *)mBuffer;
- (NSDictionary *)getInfo:(NSString *)path;

- (NSDictionary *) getAllPatterns:(NSString *)path;
- (NSMutableDictionary *) getPatterns:(openmpt_module *)modFile;
- (NSArray *) getPatternData:(NSNumber *)patternNumber;

- (int) getCurrentOrder;
- (int) getCurrentPattern;
- (int) getCurrentRowNumber;
- (NSDictionary *) extractInfoFromModFile:(openmpt_module*) myLoadedMpFile withFileName:(NSString *)path;

char * getModTypeName(int modTypeInt);
@end
