//
//  Echo.h
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import <Cordova/CDV.h>

#include "bass.h"


@interface ModPlyr : CDVPlugin {
    HMUSIC currentModFile;


}

//- (NSString)echo:(CDVInvokedUrlCommand*)command;



- (NSMutableArray *) getFilesInDirectory;
- (NSMutableArray *) getModFileDirectories;
- (NSString *) getModDirectoriesAsJson;

#pragma mark - CORDOVA


- (void) cordovaGetModPaths;

- (void) cordovaGetFilesForPath;

- (void) cordovaLoadMod;
- (void) cordovaPlayMod;
- (void) cordovaStopMusic;
- (void) cordovaGetModStats;

- (void) echo;


@end
