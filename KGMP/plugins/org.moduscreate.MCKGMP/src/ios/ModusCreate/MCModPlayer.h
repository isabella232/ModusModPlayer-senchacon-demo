//
//  MCGmePlayer.h
//  UIExplorer
//
//  Created by Jesus Garcia on 3/6/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <xmp.h>
#import <UIKit/UIApplication.h>

//#import "MC_XMP.h"
//#import "MC_MP.h"
#import "MC_OMPT.h"



#define PLAYBACK_FREQ 44100
#define SOUND_BUFFER_SIZE_SAMPLE (PLAYBACK_FREQ / 30)
#define NUM_BUFFERS 8
#define MIDIFX_OFS 32

@interface MCModPlayer : NSObject {
    AudioQueueRef mAudioQueue;
    AudioQueueBufferRef *mBuffers;
    
    char *loadedFileData;
    int loadedFileSize;
    
    BOOL audioShouldStop;
    NSThread *soundThread;
    
    int waveFormDataSize;
    
    BOOL appInForeground;
}

@property NSDictionary *modInfo;
@property NSString *loadedFileName;
@property BOOL isPrimed;


//@property xmp_context xmpContext;

@property id modPlayer;
//
@property (nonatomic, copy) void (^updateInterfaceBlock)(int32_t *playerState);

@property BOOL appActive;
@property BOOL copyingFloatData;



@property float* floatDataLt;
@property float* floatDataRt;
@property int renderedAudioBuffSize;


+ (instancetype) sharedManager;


void interrruptCallback (void *inUserData,UInt32 interruptionState );

- (NSDictionary *) initializeSound:(NSString *)path;


- (float *) getBufferData:(NSString *)channel;
- (NSMutableDictionary *) getInfo:(NSString *)path;

- (NSDictionary *)getAllPatterns:(NSString *)path;
- (NSArray *) getPatternData:(NSNumber *)patternNumber;

- (void) pause;
- (void) resume;
- (void) play;

- (void) setDelegate:(id)someDelegate;
- (void) registerInfoCallback:(void(^)(int32_t *playerState))updateInterfaceBlock;

- (void) appHasGoneInBackground;
- (void) appHasGoneInForeground;

@end
