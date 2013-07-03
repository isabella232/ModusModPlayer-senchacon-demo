//
//  Echo.h
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import <Cordova/CDV.h>

#include "bass.h"


@interface ModPlyr : CDVPlugin

//- (NSString)echo:(CDVInvokedUrlCommand*)command;



- (NSMutableArray *) getFilesInDirectory;
- (NSMutableArray *) getModFileDirectories;
- (NSString *) getModDirectoriesAsJson;

#pragma mark - CORDOVA




- (void) cordovaGetModPaths;

- (void) cordovaGetFilesForPath;

- (void) cordovaPlayMod;

- (void) echo;


@end
