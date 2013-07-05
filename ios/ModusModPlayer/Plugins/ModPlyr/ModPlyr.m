//
//  Echo.m
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import "ModPlyr.h"
#import <Cordova/CDV.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>


#include "bass.h"

@implementation ModPlyr


- (NSMutableArray *) getModFileDirectories: (NSString *)modPath {
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    
    NSString *appUrl    = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl   = [appUrl stringByAppendingString:@"/mods"];
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:modsUrl] ;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSArray *directories = [fileManager
                 contentsOfDirectoryAtURL: directoryUrl
                 includingPropertiesForKeys : keys
                 options : 0
                 error:nil];
    
    for (NSURL *url in directories) {
        [paths addObject:url];
    }
    
    return paths;
}


- (NSMutableArray *) getFilesInDirectory: (NSString*)path {
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
    NSString *appUrl    = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl   = [appUrl stringByAppendingString:@"/mods/"];
    NSString *targetPath = [modsUrl stringByAppendingString: path];
    
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:targetPath];
    
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL : directoryUrl
                                         includingPropertiesForKeys : keys
                                         options : 0
                                         errorHandler : ^(NSURL *url, NSError *error) {
                                             //Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             NSLog(@"Error :: %@", error);
                                             return YES;
                                         }];
    
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            //handle error
        }
        else if (! [isDirectory boolValue]) {
//            NSLog(@"%@", [url lastPathComponent]);

            [files addObject:url];
        }
    }
    
    return files;
}


- (NSString *) getModDirectoriesAsJson {

    NSString *appUrl    = [[NSBundle mainBundle] bundlePath];
    NSString *modsUrl   = [appUrl stringByAppendingString:@"/mods"];
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:modsUrl] ;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSArray *directories = [fileManager
                             contentsOfDirectoryAtURL: directoryUrl
                             includingPropertiesForKeys : keys
                             options : 0
                             error:nil
                            ];

    NSMutableArray *pathDictionaries = [[NSMutableArray alloc] init];
    
    for (NSURL *url in directories) {
         NSDictionary *jsonObj = [[NSDictionary alloc]
                                    initWithObjectsAndKeys:
                                        [url lastPathComponent], @"dirName",
                                        [url path], @"path",
                                        nil
                                    ];
        
        
        [pathDictionaries addObject:jsonObj];
    }
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:pathDictionaries
                        options:NSJSONWritingPrettyPrinted
                        error:&jsonError
                       ];
    
    NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonDataString;
}



- (NSString *) getModFilesAsJson: (NSString*)path {
   
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:path];
    
    NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
    
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL : directoryUrl
                                         includingPropertiesForKeys : keys
                                         options : 0
                                         errorHandler : ^(NSURL *url, NSError *error) {
                                             //Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             NSLog(@"Error :: %@", error);
                                             return YES;
                                         }];
    
    NSMutableArray *pathDictionaries = [[NSMutableArray alloc] init];

    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
            //handle error
        }
        else if (! [isDirectory boolValue]) {
            NSDictionary *jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    [url lastPathComponent], @"fileName",
                    [url path], @"path",
                    nil
                ];
            [pathDictionaries addObject:jsonObj];

        }
    }
    
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:pathDictionaries
                        options:NSJSONWritingPrettyPrinted
                        error:&jsonError
                    ];
    
    NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonDataString;
}



#pragma mark - CORDOVA


- (void) cordovaGetModPaths:(CDVInvokedUrlCommand*)command {
    
    NSString* modPaths = [self getModDirectoriesAsJson];
    
    CDVPluginResult *pluginResult = [CDVPluginResult
                                    resultWithStatus:CDVCommandStatus_OK
                                    messageAsString:modPaths
                                ];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];    
}

- (void) cordovaGetModFiles:(CDVInvokedUrlCommand*)command {
    
    NSString* path = [command.arguments objectAtIndex:0];

    NSString* modPaths = [self getModFilesAsJson:path];
    
    CDVPluginResult *pluginResult = [CDVPluginResult
                                    resultWithStatus:CDVCommandStatus_OK
                                    messageAsString:modPaths
                                ];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];    
}


- (void) cordovaLoadMod:(CDVInvokedUrlCommand*) command {
    BASS_Free();

    if (!BASS_Init(-1,44100,0,NULL,NULL)) {
		NSLog(@"Can't initialize device");
    }
    
    NSString *file = [command.arguments objectAtIndex:0];
    currentModFile = BASS_MusicLoad(FALSE, [file UTF8String],0,0,BASS_SAMPLE_LOOP|BASS_MUSIC_RAMPS|BASS_MUSIC_PRESCAN,1);

//    int errNo = BASS_ErrorGetCode();
    
  
    NSDictionary *jsonObj;
        
    if (! currentModFile) {
        NSLog(@"Could not load file: %@", file);
        
        
        jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    @"false", @"success",
                    nil
                ];
          
    }
    else {
        NSString *songName = [[NSString alloc] initWithCString: BASS_ChannelGetTags(currentModFile,BASS_TAG_MUSIC_NAME)];
    
        NSLog(@"PLAYING : %s", BASS_ChannelGetTags(currentModFile,BASS_TAG_MUSIC_NAME));
        
        // This needs to be moved to a separate method;
        jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    @"true", @"success",
                    songName, @"songName",
                    nil
                ];
    }


     
    CDVPluginResult *pluginResult = [CDVPluginResult
                                        resultWithStatus:CDVCommandStatus_OK
                                        messageAsDictionary:jsonObj
                                    ];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) cordovaPlayMod:(CDVInvokedUrlCommand*)command {
    
    NSDictionary *jsonObj  = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    @"true", @"success",
                    nil
                ];

    BASS_ChannelPlay(currentModFile, FALSE); // play the stream

        
    CDVPluginResult *pluginResult = [CDVPluginResult
                                        resultWithStatus:CDVCommandStatus_OK
                                        messageAsDictionary:jsonObj
                                    ];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


}



- (void) cordovaGetSongStatus:(CDVInvokedUrlCommand*)command {
    int level, pos, time, act;
    float *buf;
    float cpu;
    
    BASS_CHANNELINFO ci;
    BASS_ChannelGetInfo(currentModFile, &ci); // get number of channels

    
    NSDictionary *jsonObj;
    
    if ((act = BASS_ChannelIsActive(currentModFile)) ) {
    
        level = BASS_ChannelGetLevel(currentModFile);
        pos   = BASS_ChannelGetPosition(currentModFile, BASS_POS_MUSIC_ORDER);
        time  = BASS_ChannelBytes2Seconds(currentModFile, pos);
        cpu   = BASS_GetCPU();
        
        
        buf = alloca(ci.chans * 368 * sizeof(float)); // allocate buffer for data
		
        BASS_ChannelGetData(currentModFile, buf, (ci.chans * 368 * sizeof(float)) | BASS_DATA_FLOAT); // get the sample data (floating-point to avoid 8 & 16 bit processing)

        NSNumber *nsPosition = [[NSNumber alloc] initWithInt:pos];
        NSNumber *nsLevel    = [[NSNumber alloc] initWithInt:level];
        NSNumber *nsTime     = [[NSNumber alloc] initWithInt:time];
        NSNumber *nsCpu      = [[NSNumber alloc] initWithFloat: cpu];
        NSNumber *nsBuf      = [[NSNumber alloc] initWithFloat: *buf];
        
        jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    nsLevel, @"level",
                    nsPosition, @"position",
                    nsTime, @"time",
                    nsBuf, @"buff",
                    nsCpu, @"cpu",
                    nil
                ];
    
    }
    else {
    
          
         jsonObj = [[NSDictionary alloc]
            initWithObjectsAndKeys:
                @"false", @"success",
                nil
            ];

    }
    
    
    CDVPluginResult *pluginResult = [CDVPluginResult
                                    resultWithStatus:CDVCommandStatus_OK
                                    messageAsDictionary:jsonObj
                                ];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

- (void) cordovaStopMusic:(CDVInvokedUrlCommand*)command {
    BASS_Free();
    NSLog(@"STOPPING MUSIC");
    
}

- (void) echo:(CDVInvokedUrlCommand*)command {
    
    CDVPluginResult* pluginResult = nil;
    NSArray* modPaths = [self getModPaths];
    
    NSString* echo = [command.arguments objectAtIndex:0];
    
    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:modPaths];
        NSLog(@"ECHO: %@", echo);
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];    
}





@end

