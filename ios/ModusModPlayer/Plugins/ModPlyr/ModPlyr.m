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


// This method was copied from libbass spectrum.c :: UpdateSpectrum example
- (NSArray*) getWaveFormData:(NSInteger*)width  andHeight:(NSInteger*)height {
    int x,y;


    // TODO: Use width and height parameters here. Need to figure out how to cast from NSInteger to int!!!!
    int SPECHEIGHT = 173;
    int SPECWIDTH =  320;

    DWORD specbuf[SPECHEIGHT * SPECWIDTH];

    NSMutableArray *channelData  = [[NSMutableArray alloc] init];
    NSMutableArray *channelOneData = [[NSMutableArray alloc] init];
    NSMutableArray *channelTwoData = [[NSMutableArray alloc] init];

    int c;
    float *buf;

    BASS_CHANNELINFO channelInfo;
    
    memset(specbuf, 0, sizeof(specbuf));
    
    BASS_ChannelGetInfo(currentModFile, &channelInfo); // get number of channels
    
    buf = alloca(channelInfo.chans * SPECWIDTH * sizeof(float)); // allocate buffer for data
    
    short dataSize = channelInfo.chans * SPECWIDTH * sizeof(float);
//    printf("data size %hd \n", dataSize);
    
    // get the sample data (floating-point to avoid 8 & 16 bit processing)
    BASS_ChannelGetData(currentModFile, buf, ( channelInfo.chans * SPECWIDTH * sizeof(float) ) |BASS_DATA_FLOAT);
    
    
    for ( c = 0; c < channelInfo.chans;c ++) {
        for (x=0;x<SPECWIDTH;x++) {
            int v = ( 1 - buf[ x * channelInfo.chans + c]) * SPECHEIGHT /2; // invert and scale to fit display
//            printf ("v = %i\n", v);
            
        
            if (v < 0) {
                v = 0;
            }
            else if (v >= SPECHEIGHT) {
                v = SPECHEIGHT - 1;
            }

            if (!x) {
                y = v;
            }
            do { // draw line from previous sample...
                if (y < v) {
                    y++;
                }
                else if (y > v) {
                    y--;
                }
                
                
                NSNumber *plotItem = [[NSNumber alloc]initWithInt: v];
                
                if (c == 0) {
                    [channelOneData addObject: plotItem];
                }
                else {
                    [channelTwoData addObject: plotItem];
                }
                
                specbuf[ y * SPECWIDTH + x] = 1; // left=green, right=red (could add more colours to palette for more chans)
            } while (y!=v);
        }
//        [data addObject:specbuf];
    }

    [channelData addObject:channelOneData];
    [channelData addObject:channelTwoData];
    
    return channelData;

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
    
        NSLog(@"PLAYING : %s", BASS_ChannelGetTags(currentModFile, BASS_TAG_MUSIC_NAME));
        
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



- (void) cordovaGetModStats:(CDVInvokedUrlCommand*)command {
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



        NSString *nsPosition = [NSString  stringWithFormat:@"(%03u:%03u)", LOWORD(pos),HIWORD(pos)];
        NSNumber *nsLevel    = [[NSNumber alloc] initWithInt:level];
        NSNumber *nsTime     = [[NSNumber alloc] initWithInt:time];
        NSNumber *nsCpu      = [[NSNumber alloc] initWithFloat: cpu];
        NSNumber *nsBuf      = [[NSNumber alloc] initWithFloat: *buf];
        
        
        NSInteger *canvasWidth = (NSInteger *)[command.arguments objectAtIndex:0];
        NSInteger *canvasHeight = (NSInteger *)[command.arguments objectAtIndex:1];

//        NSLog(@"CanvasSize %@x%@", canvasWidth, canvasHeight);

        
        NSArray *waveData = [self getWaveFormData:(NSInteger *)canvasWidth andHeight:(NSInteger *)canvasHeight];
        
        jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    nsLevel, @"level",
                    nsPosition, @"position",
                    nsTime, @"time",
                    nsBuf, @"buff",
                    nsCpu, @"cpu",
                    waveData, @"waveData",
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
    BASS_ChannelStop(currentModFile);
//    BASS_Channel
    BASS_ChannelSetPosition(currentModFile, 0, 0);
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

