//
//  MCGmePlayer.m
//  UIExplorer
//
//  Created by Jesus Garcia on 3/6/15.
//

#import "MCModPlayer.h"

@implementation MCModPlayer



+ (id)sharedManager {
    static MCModPlayer *sharedMyManager = nil;
    static dispatch_once_t onceToken;
//    NSLog(@"MCModPlayer sharedManater()");
  
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id) init {
    NSLog(@"MCModPlayer init");
    
    if (self = [super init]) {
        self.floatDataLt = malloc(sizeof(float) * 512);
        self.floatDataRt = malloc(sizeof(float) * 512);
        
        
        // This is here to suppress messages from
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self
                               selector:@selector(appHasGoneInBackground)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
       
        [notificationCenter addObserver:self
                               selector:@selector(appHasGoneInForeground)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];

        return self;
    }
    return nil;
}

- (void) appHasGoneInBackground {
    self.appActive = false;
}

- (void) appHasGoneInForeground {
    self.appActive = true;
}


- (void) registerInfoCallback:(void(^)(int32_t *playerState))updateInterfaceBlock {
    NSLog(@"registerInfoCallback registerInfoCallback registerInfoCallback registerInfoCallback registerInfoCallback");
    self.updateInterfaceBlock = updateInterfaceBlock;
    
}

// Executed within a different context (not this class);
void audioCallback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {

    MCModPlayer *player = (__bridge MCModPlayer*)data;
    
    int32_t *playerState = [player.modPlayer fillBuffer:mBuffer];
    
    AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);
//    printf("+Ord: %i     Pat: %i     Row: %i\n", playerState[0], playerState[1], playerState[2]);

    
//    if (player.appActive) {
        // TODO: Should we use GCD to execute this method in the main queue??
        [player notifyInterface:playerState];
//    }
}



- (void) notifyInterface:(int32_t *) playerState {
    
    if (self.updateInterfaceBlock) {
        self.updateInterfaceBlock(playerState);
    }

}
- (BOOL) initAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];

  
    NSError *setCategoryError = nil;
    BOOL success = [session setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    if (! success) {
#if DEBUG
        NSLog(@"%@", [setCategoryError localizedFailureReason]);
#endif
        return NO;
    }
    
    
    
    NSError *activationError;
    success = [session setActive:YES error:&activationError];
    
    if (! success) {
#if DEBUG
        NSLog(@"%@", [activationError localizedFailureReason]);
#endif
        
        return NO;
    }


    return YES;
}


void interrruptCallback (void *inUserData, UInt32 interruptType ) {
//    MCModPlayer *player = (__bridge MCModPlayer *)inUserData;
//    
//    if (interruptType == kAudioSessionBeginInterruption) {
//        // TODO: Handle pause
//    }
//    else if (interruptType == kAudioSessionEndInterruption) {
//        // TODO: Handle resume
//    }
    

}



- (void) play {
    [self updateInfoCenter];

    AudioQueueSetParameter(mAudioQueue, kAudioQueueParam_Volume, 1.0f);
    AudioQueueStart(mAudioQueue, NULL);
    self.isPrimed = false;
}


- (NSDictionary *) initializeSound:(NSString *)path  {
    
//    int sample_rate = 44100; // number of samples per second
    if (self.modPlayer) {
        [self pause];

        AudioQueueStop(mAudioQueue, YES);
        AudioQueueReset(mAudioQueue);
        AudioQueueDispose(mAudioQueue, YES);
       
    }
    else {
        BOOL success = [self initAudioSession];
        if (! success) {
            return nil;
        }


        self.modPlayer = [[MC_OMPT alloc] init];
    }
    
    self.modInfo = [self.modPlayer loadFile:path];
    
    NSArray *pathParts = [path componentsSeparatedByString:@"/"];
    
    self.loadedFileName = [pathParts objectAtIndex:[pathParts count] - 1];
    
    AudioStreamBasicDescription mDataFormat;
    UInt32 err;

  /*
        (AudioStreamBasicDescription) mDataFormat = {
          mSampleRate = 44100
          mFormatID = 1819304813
          mFormatFlags = 12
          mBytesPerPacket = 4
          mFramesPerPacket = 1
          mBytesPerFrame = 4
          mChannelsPerFrame = 2
          mBitsPerChannel = 16
          mReserved = 1
        }
    */
    
    mDataFormat.mFormatID         = kAudioFormatLinearPCM;
    mDataFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mDataFormat.mSampleRate       = PLAYBACK_FREQ;
    mDataFormat.mBitsPerChannel   = 16;
    mDataFormat.mChannelsPerFrame = 2;
    mDataFormat.mBytesPerFrame    = (mDataFormat.mBitsPerChannel >> 3) * mDataFormat.mChannelsPerFrame;
    mDataFormat.mFramesPerPacket  = 1;
    mDataFormat.mBytesPerPacket   = mDataFormat.mBytesPerFrame;
    
    err = AudioQueueNewOutput(&mDataFormat,
                             audioCallback,
                             CFBridgingRetain(self),
                             CFRunLoopGetMain(),
                             kCFRunLoopCommonModes,
                             0,
                             &mAudioQueue);
    
    int bufferSize = 4096 * 2;

    
    /* Create associated buffers */
    mBuffers = (AudioQueueBufferRef*) malloc( sizeof(AudioQueueBufferRef) * NUM_BUFFERS );
    
    static int zeros[4096 * 2] = {0};
    
    for (int i = 0; i < NUM_BUFFERS; i++) {
        
        AudioQueueBufferRef mBuffer;
		
        AudioQueueAllocateBuffer(mAudioQueue, bufferSize, &mBuffer);
		
		mBuffers[i] = mBuffer;
        mBuffer->mAudioDataByteSize = bufferSize;
        
        memcpy(mBuffer->mAudioData, zeros, bufferSize);
        
//        [self.modPlayer fillBuffer:mBuffer];
        
        AudioQueueEnqueueBuffer(mAudioQueue, mBuffer, 0, NULL);
    }

    self.isPrimed = true;


    return self.modInfo;
}



- (NSArray *) getPatternData:(NSNumber *)patternNumber {
    if (! self.modPlayer) {
        self.modPlayer = [[MC_OMPT alloc]init];
    }
    
    return [self.modPlayer getPatternData:patternNumber];

}

- (NSDictionary *) getAllPatterns:(NSString *)path {
    MC_OMPT *modPlayer = [[MC_OMPT alloc]init];
    
    NSDictionary *patternData = [modPlayer getAllPatterns:path];
    
    return patternData;
}

- (NSDictionary *) getInfo:(NSString *)path {
    MC_OMPT *modPlayer = [[MC_OMPT alloc]init];
    
    self.modInfo = [modPlayer getInfo:path];
    
    return self.modInfo;
}

- (void) updateInfoCenter {

    MPNowPlayingInfoCenter *infoCenter = [MPNowPlayingInfoCenter defaultCenter];
    
    NSDictionary *modInfo = self.modInfo;
    
    NSDictionary *nowPlayingInfo = @{
        MPMediaItemPropertyAlbumArtist      : [modInfo valueForKey:@"artist"],
        MPMediaItemPropertyGenre            : [modInfo valueForKey:@"type"],
        MPMediaItemPropertyTitle            : [modInfo valueForKey:@"name"] ?: @"Mod file",
        MPMediaItemPropertyPlaybackDuration : [modInfo valueForKey:@"length"],
        MPMediaItemPropertyBeatsPerMinute   : [modInfo valueForKey:@"bpm"],
        MPMediaItemPropertyAlbumTitle       : self.loadedFileName
    };
    
    infoCenter.nowPlayingInfo = nowPlayingInfo;
}

- (float *) floatDataLt {
    return _floatDataLt;
}

- (float *) floatDataRt {
    return _floatDataRt;
}

- (void) pause {
    AudioQueuePause(mAudioQueue);
    AudioQueueFlush(mAudioQueue);

}

- (void) resume {
    AudioQueueStart(mAudioQueue, NULL);
}





@end
