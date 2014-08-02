//
//  Echo.h
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import <Cordova/CDV.h>
#import "modplug.h"

#define PLAYBACK_FREQ 44100
#define SOUND_BUFFER_SIZE_SAMPLE (PLAYBACK_FREQ / 30)
#define SOUND_BUFFER_NB 32
#define MIDIFX_OFS 32



@interface ModPlyr : CDVPlugin {


}

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
