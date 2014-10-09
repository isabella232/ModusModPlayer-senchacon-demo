//
//  Echo.h
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import <mach/mach.h>
#import <Cordova/CDV.h>
#import "modplug.h"

#define PLAYBACK_FREQ 44100
#define SOUND_BUFFER_SIZE_SAMPLE (PLAYBACK_FREQ / 30)
#define NUM_BUFFERS 12
#define MIDIFX_OFS 32

@interface ModPlyr : CDVPlugin {

    unsigned char *genVolData,
                  *playVolData;
	
    char *mp_data,
         *modMessage;
	
    int numPatterns,
        numSamples,
        numInstr,
        numChannels;
    
    ModPlugFile *loadedModPlugFile;
    ModPlugFile *patternsModPlugFile;
    ModPlug_Settings settings;
    
    AudioQueueRef mAudioQueue;
    AudioQueueBufferRef *mBuffers;
    
    char *loadedFileData;
    int loadedFileSize;
    char *modName;
    
    BOOL modPlugSettingsCommitted,
         patternDataReady,         // Used to detect when a pattern read thread is done
         audioShouldStop;          // Used to detect if a sound thread should exit
    
    NSThread *soundThread;

    // An Object to produce the JSON below.
    NSMutableDictionary *songPatterns;
    /*
    {
        patternX : [
            "Pattern 1",
            "Pattern 2"
            "Pattern 3"
        ]
    
    }
    */


}

@property BOOL *generateAudioData;

@property ModPlugFile *mpFile;


- (NSMutableArray *) getFilesInDirectory;
- (NSMutableArray *) getModFileDirectories;
- (NSString *) getModDirectoriesAsJson;
- (NSArray *) getWaveFormData;
- (NSArray *) getSpectrumData;

#pragma mark - CORDOVA


- (void) cordovaGetModPaths;

- (void) cordovaGetFilesForPath;

- (void) cordovaLoadMod;
- (void) cordovaPlayMod;
- (void) cordovaStopMusic;
- (void) cordvoaGetWaveFormData;
- (void) cordovaGetSpectrumData;

- (void) echo;


@end
