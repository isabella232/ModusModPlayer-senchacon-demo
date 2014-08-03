//
//
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import "ModPlyr.h"


@implementation ModPlyr : CDVPlugin {
    
    unsigned char *genVolData,
                  *playVolData;
	
    char *mp_data,
    *modMessage;
	
    int numPatterns,
        numSamples,
        numInstr,
        numChannels,
        lastPattern; // Used for determining if we already looked at this pattern. TODO: Delete
    
    ModPlugFile *loadedModPlugFile;
    ModPlug_Settings settings;
    
    AudioQueueRef mAudioQueue;
    AudioQueueBufferRef *mBuffers;
    
    char *loadedFileData;
    int loadedFileSize;
    char *modName;
    

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

static char note2charA[12]={'C','C','D','D','E','F','F','G','G','A','A','B'};
static char note2charB[12]={'-','#','-','#','-','-','#','-','#','-','#','-'};
static char dec2hex[16]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

- (ModPlugFile *) getMpFile {
    return self.mpFile;
}

- (void) stopMusic {
    if (self.mpFile) {
        AudioQueueStop( mAudioQueue, TRUE );
        AudioQueueReset( mAudioQueue );
        ModPlug_Unload(self.mpFile);
        free (loadedFileData);
    }
}

- (void) playSong {
    [self initModPlugSettings];

    
    ModPlug_SetMasterVolume(loadedModPlugFile, 128);
    ModPlug_Seek(loadedModPlugFile, 0);
    
    int len = ModPlug_GetLength(loadedModPlugFile);

    NSLog(@"Length: %i", len);
    NSLog(@"ModName: %s", modName);
    
    [self initSound];
    
//    [self playFile:firstFile];

}
- (void) loadFile:(NSString *)filePath  {
    FILE *file;
//    int fileSize;

    const char* fil = [filePath cStringUsingEncoding:NSASCIIStringEncoding];
    
    file = fopen(fil, "rb");
    
    if (file == NULL) {
      return;
    }
    
    fseek(file, 0L, SEEK_END);
    (loadedFileSize) = ftell(file);
    rewind(file);
    loadedFileData = (char*) malloc(loadedFileSize);
    
    fread(loadedFileData, loadedFileSize, sizeof(char), file);
    fclose(file);
    
    
    
    loadedModPlugFile = ModPlug_Load(loadedFileData, loadedFileSize);
    numPatterns       = ModPlug_NumPatterns(loadedModPlugFile);
    numChannels       = ModPlug_NumChannels(loadedModPlugFile);
    numSamples        = ModPlug_NumSamples(loadedModPlugFile);
    numInstr          = ModPlug_NumInstruments(loadedModPlugFile);
    modMessage        = ModPlug_GetMessage(loadedModPlugFile);
    modName           = (char *)ModPlug_GetName(loadedModPlugFile);
    
    self.mpFile = loadedModPlugFile;
    
    [self preLoadPatterns];

}

- (void) initModPlugSettings {
    ModPlug_GetSettings(&settings);

    settings.mFlags=MODPLUG_ENABLE_OVERSAMPLING;
    settings.mChannels=2;
    settings.mBits=16;
    settings.mFrequency=44100;
    settings.mResamplingMode=MODPLUG_RESAMPLE_NEAREST;
    settings.mReverbDepth=0;
    settings.mReverbDelay=100;
    settings.mBassAmount=0;
    settings.mBassRange=50;
    settings.mSurroundDepth=0;
    settings.mSurroundDelay=10;
    settings.mLoopCount=-1;
    settings.mStereoSeparation=64;
    
    ModPlug_SetSettings(&settings);
}


- (void) myMainThreadMethod {
    NSLog(@"Thread kicked off");
    
    while (1) {
        [NSThread sleepForTimeInterval:0.1];
    
        NSLog(@"Teh Thread is werking");
        NSLog(@"ModName: %s", ModPlug_GetName(self.mpFile));
    }

}



- (void) initSound {
    ModPlugFile *mpFile = self.mpFile;

    AudioStreamBasicDescription mDataFormat;
    UInt32 err;
    float mVolume = 1.0f;
    
    /* We force this format for iPhone */
    mDataFormat.mFormatID = kAudioFormatLinearPCM;
    mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	mDataFormat.mSampleRate = PLAYBACK_FREQ;
	mDataFormat.mBitsPerChannel = 16;
	mDataFormat.mChannelsPerFrame = 2;
    mDataFormat.mBytesPerFrame = (mDataFormat.mBitsPerChannel>>3) * mDataFormat.mChannelsPerFrame;
    mDataFormat.mFramesPerPacket = 1;
    mDataFormat.mBytesPerPacket = mDataFormat.mBytesPerFrame;

    err = AudioQueueNewOutput(&mDataFormat,
                         audioCallback,
                         CFBridgingRetain(self),
                         CFRunLoopGetCurrent(),
                         kCFRunLoopCommonModes,
                         0,
                         &mAudioQueue);

    /* Create associated buffers */
    mBuffers = (AudioQueueBufferRef*) malloc( sizeof(AudioQueueBufferRef) * SOUND_BUFFER_NB );
    
    int bytesRead;

    for (int i = 0; i < SOUND_BUFFER_NB; i++) {
		AudioQueueBufferRef mBuffer;
		err = AudioQueueAllocateBuffer(mAudioQueue, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2, &mBuffer );
		
		mBuffers[i] = mBuffer;
        mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE * 2 * 2;
        
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
        
        [self parsePattern];
        
        AudioQueueEnqueueBuffer(mAudioQueue, mBuffers[i], 0, NULL);
    }
    
    
    /* Set initial playback volume */
    err = AudioQueueSetParameter(mAudioQueue, kAudioQueueParam_Volume, mVolume );
    err = AudioQueueStart(mAudioQueue, NULL );
}


void audioCallback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {
    ModPlyr *modPlayer = (__bridge ModPlyr*)data;
    ModPlugFile *mpFile = modPlayer.mpFile;
    
    int bytesRead;
    
    mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE*2*2;
    bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);

    if (bytesRead < 1) {
        ModPlug_Seek(mpFile, 0);
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    }
  
    AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);
}


- (void) preLoadPatterns  {

    if (songPatterns == nil) {
        songPatterns = [[NSMutableDictionary alloc]init];
    }

    // Clear the existing song patterns
    [songPatterns removeAllObjects];

    NSLog(@"preLoadPatterns for %s", modName);
    NSDate *start = [NSDate date];
    
    // do stuff...
    ModPlugFile *mpFile = self.mpFile;
    
    int bytesRead,
        currPattrn,
        currRow,
        currOrder,
        prevOrder,
        prevPattrn,
        prevRow;
    
    prevOrder = prevPattrn = prevRow =  -1;
    
    ModPlug_GetSettings(&settings);
    settings.mLoopCount = 0;
    ModPlug_SetSettings(&settings);
    ModPlug_GetSettings(&settings);
    
    
    char *buffer = malloc(sizeof(char) * SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    bytesRead = ModPlug_Read(mpFile, buffer, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    
    NSMutableDictionary *orderMapper = [[NSMutableDictionary alloc] init];
    
    // We're going to stuff row strings in here.
    NSMutableArray *patternStrings;
    BOOL isOkToContinue = true;
    
    while (bytesRead > 0 && isOkToContinue) {
        currOrder  = ModPlug_GetCurrentOrder(mpFile);
        currPattrn = ModPlug_GetCurrentPattern(mpFile);
        currRow    = ModPlug_GetCurrentRow(mpFile);
        
        
//       NSLog(@"O %i \t P %i \t R %i", currOrder, currPattrn, currRow);
       
      
        // When we hit a new pattern, create a new array so that we can stuff strings into it.
        if (currPattrn != prevPattrn) {
//                NSLog(@"New pattern :: #%i", currPattrn);

           // This is a hacky way of testing to see if the fucking mod looped.
           // Even though we set mLoopCount to 0 (see above this while loop),
           // modPlug still loops on some mods. Fucker.
           if (prevOrder != -1) {
                NSString *orderKey = [NSString stringWithFormat:@"%d_", prevPattrn];

                if (orderMapper[orderKey]) {
                    isOkToContinue = false; // Set this so the loop can end!
                    
                    continue; // Break out of this loop fast!
                }
                else {
                    // TODO: Turn to integer so we can see if we have seen it more than once.
                    [orderMapper setObject:@"" forKey:orderKey];
                }
               
                // Add new pattern
                if (patternStrings) {
                    NSString *key = [NSString stringWithFormat:@"%d", prevPattrn];
                    [songPatterns setValue:patternStrings forKey:key];
                    
    //                NSLog(@"%i", [songPatterns count]);
                }

               
           }

            
            patternStrings = [[NSMutableArray alloc] init];
        }
    
        // Skip to the next row so we don't get duplicate patterns in the array.
        if (currPattrn == prevPattrn && currRow == prevRow) {
            
            memset(buffer, 0, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
            bytesRead = ModPlug_Read(mpFile, buffer, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);

            continue;
        }
        
        NSString *rowString = [self parsePattern];
        [patternStrings addObject:rowString];
        
        NSLog(@"Total items in patternStrings :: %i", [songPatterns count]);

        prevPattrn = currPattrn;
        prevRow    = currRow;
        prevOrder  = currOrder;
        
        memset(buffer, 0, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
        bytesRead = ModPlug_Read(mpFile, buffer, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    }
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    
    // Is this memset really needed?
    memset(buffer, 0, SOUND_BUFFER_SIZE_SAMPLE * 2 * 2);
    free(buffer);
    
    NSString *message = [[NSString alloc] initWithFormat:@"Done pre-buffering patterns %f(ms)", timeInterval];
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"DONE!" message:message delegate:nil cancelButtonTitle:@"sweet" otherButtonTitles:nil, nil];
//    [alert show];

    NSLog(@"%@", message);
    
}


- (NSString *) parsePattern {
    
    ModPlugFile *mpFile = self.mpFile;

    unsigned int rowsToGet,
                 patternNote,
                 instrument,
                 volumeEffect,
                 effect,
                 volume,
                 parameter;

    
    // todo: optimize (by reusing previous data);
    int currentPatternNumber = ModPlug_GetCurrentPattern(mpFile),
        currRow              = ModPlug_GetCurrentRow(mpFile);

    ModPlugNote *pattern = ModPlug_GetPattern(mpFile, currentPatternNumber, &rowsToGet);

    int index,
        curPatPosition,
        k = 0;
    
    char stringData[200];
    
    if (! pattern) {
        NSLog(@"No Pattern for pattern# %i!!", currentPatternNumber);
        return @"";
    }
    

    // The following for loop was inspired by the Modizer project: https://github.com/yoyofr/modizer
    for (index = 0; index < numChannels; index++) {
        curPatPosition = index + (numChannels * currRow);
        
        patternNote  = pattern[curPatPosition].Note;
        instrument   = pattern[curPatPosition].Instrument;
        volumeEffect = pattern[curPatPosition].VolumeEffect;
        effect       = pattern[curPatPosition].Effect;
        volume       = pattern[curPatPosition].Volume;
        parameter    = pattern[curPatPosition].Parameter;
 
        if (patternNote) {
            stringData[k++] = note2charA[(patternNote - 13) % 12];
            stringData[k++] = note2charB[(patternNote - 13) % 12];
            stringData[k++] = (patternNote - 13) / 12 + '0';
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        if (instrument) {
            stringData[k++]=dec2hex[ (instrument >> 4) & 0xF ];
            stringData[k++]=dec2hex[ instrument & 0xF ];
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        if (volume) {
            stringData[k++] = dec2hex[ (volume >> 4) & 0xF ];
            stringData[k++] = dec2hex[ volume & 0xF ];
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        if (effect) {
            stringData[k++]='A' + effect;
        }
        else {
            stringData[k++]='.';
        }
        
        if (parameter) {
            stringData[k++] = dec2hex[(parameter >> 4) & 0xF];
            stringData[k++] = dec2hex[parameter & 0xF];
        }
        else {
            stringData[k++]='.';
            stringData[k++]='.';
        }
        
        stringData[k++]=' ';
        stringData[k++]=' ';
    }
    
    return [[NSString alloc] initWithCString:stringData];
}



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
    
    NSURL *directoryUrl = [[NSURL alloc] initFileURLWithPath:modsUrl];
    
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
//    int x,y;
//
//
//    // TODO: Use width and height parameters here. Need to figure out how to cast from NSInteger to int!!!!
//    int SPECHEIGHT = 213;
//    int SPECWIDTH =  500;
//
//    DWORD specbuf[SPECHEIGHT * SPECWIDTH];
//
//    NSMutableArray *channelData    = [[NSMutableArray alloc] init];
//    NSMutableArray *channelOneData = [[NSMutableArray alloc] init];
//    NSMutableArray *channelTwoData = [[NSMutableArray alloc] init];
//
//    int c;
//    float *buf;
//
//    BASS_CHANNELINFO channelInfo;
//    
//    memset(specbuf, 0, sizeof(specbuf));
//    
//    BASS_ChannelGetInfo(currentModFile, &channelInfo); // get number of channels
//    
//    buf = alloca(channelInfo.chans * SPECWIDTH * sizeof(float)); // allocate buffer for data
//    
////    short dataSize = channelInfo.chans * SPECWIDTH * sizeof(float);
////    printf("data size %hd \n", dataSize);
//    
//    // get the sample data (floating-point to avoid 8 & 16 bit processing)
//    BASS_ChannelGetData(currentModFile, buf, ( channelInfo.chans * SPECWIDTH * sizeof(float) ) |BASS_DATA_FLOAT);
//    
//    
//    for ( c = 0; c < channelInfo.chans;c ++) {
//        NSNumber *plotItem;
//        for (x=0;x<SPECWIDTH;x++) {
//            int v = ( 1 - buf[ x * channelInfo.chans + c]) * SPECHEIGHT /2; // invert and scale to fit display
//        
//            if (v < 0) {
//                v = 0;
//            }
//            else if (v >= SPECHEIGHT) {
//                v = SPECHEIGHT - 1;
//            }
//
//            if (!x) {
//                y = v;
//            }
//            do { // draw line from previous sample...
//                if (y < v) {
//                    y++;
//                }
//                else if (y > v) {
//                    y--;
//                }
//                
//                
//                plotItem = [[NSNumber alloc] initWithInt:v];
//
//                
//                specbuf[ y * SPECWIDTH + x] = 1; // left=green, right=red (could add more colours to palette for more chans)
//            } while (y!=v);
//    
//            if (c == 0) {
//                [channelOneData addObject: plotItem];
//            }
//            else {
//                [channelTwoData addObject: plotItem];
//            }
//        }
//    }
//
//    [channelData addObject:channelOneData];
//    [channelData addObject:channelTwoData];
//    
//    return channelData;
    return [[NSArray alloc] init];
}


- (NSArray *) getSpectrumData {
//    int SPECHEIGHT = 310;
//    
//    float fft[1024]; // get the FFT data
//    BASS_ChannelGetData(currentModFile, fft, BASS_DATA_FFT1024);
//
//    int x, y;
//    
//    
//    NSMutableArray *channelData = [[NSMutableArray alloc] init];
//    
//    
//    
//    for (x = 0; x < SPECHEIGHT; x++) {
//        y = 0;
//        y = sqrt(fft[ x + 1]) * 3 * 127; // scale it (sqrt to make low values more visible)
////        NSLog(@"x=%i\n",  x);
//        if (y > 127) {
//            y = 127; // cap it
//        }
//        
//        NSNumber *plotItem = [[NSNumber alloc] initWithInt:y];
//        [channelData addObject:plotItem];
////        specbuf[(SPECHEIGHT-1-x)*SPECWIDTH+specpos]=palette[128+y]; // plot it
//    }
//    // move marker onto next position
////    specpos = ( specpos + 1 ) % SPECWIDTH;
//    
////    for (x=0;x<SPECHEIGHT;x++) {
//        // Draws white line
////        specbuf[ x * SPECWIDTH + specpos] = palette[255];
////    }
//
//    
//    return channelData;
    return [[NSArray alloc] init]; 

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
    // Todo : Clear existing song
    // Todo : Initialize sound
    
    NSString *file = [command.arguments objectAtIndex:0];
    
    if (self.mpFile) {
        [self stopMusic];
    }
    
    [self loadFile:file];
    
    ModPlugFile *currentModFile = self.mpFile;
    
//    currentModFile = BASS_MusicLoad(FALSE, [file UTF8String],0,0,BASS_SAMPLE_LOOP|BASS_MUSIC_RAMPS|BASS_MUSIC_PRESCAN,1);

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
        NSString *songName = [[NSString alloc] initWithCString: modName];
    
        NSLog(@"PLAYING : %s", modName);
        
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

    [self playSong]; // play the stream

        
    CDVPluginResult *pluginResult = [CDVPluginResult
                                        resultWithStatus:CDVCommandStatus_OK
                                        messageAsDictionary:jsonObj
                                    ];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) cordovaGetPatternData:(CDVInvokedUrlCommand*)command {

    NSError *jsonError;
//    
    NSData *jsonData = [NSJSONSerialization
                            dataWithJSONObject:songPatterns
                            options:NSJSONWritingPrettyPrinted
                            error:&jsonError
                       ];
//

//    NSDictionary *myDictionary = [NSDictionary dictionaryWithObject:@"Hello" forKey:@"World"];
//    NSError *error;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:myDictionary
//                                                           options:0
//                                                         error:&error];
// 
    NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    
    CDVPluginResult *pluginResult = [CDVPluginResult
                                    resultWithStatus:CDVCommandStatus_OK
                                    messageAsString:jsonDataString
                                ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


}


- (void) cordovaGetWaveFormData:(CDVInvokedUrlCommand*)command {
//    int level, pos, time, act;
//    float *buf;
//    float cpu;
//    
//    BASS_CHANNELINFO ci;
//    BASS_ChannelGetInfo(currentModFile, &ci); // get number of channels
//
//    
//    NSDictionary *jsonObj;
//    
//    
//    if ((act = BASS_ChannelIsActive(currentModFile)) ) {
//        NSString *wavDataType = [command.arguments objectAtIndex:0];
//    
//        level = BASS_ChannelGetLevel(currentModFile);
//        pos   = BASS_ChannelGetPosition(currentModFile, BASS_POS_MUSIC_ORDER);
//        time  = BASS_ChannelBytes2Seconds(currentModFile, pos);
//        cpu   = BASS_GetCPU();
//        
//        
//        buf = alloca(ci.chans * 368 * sizeof(float)); // allocate buffer for data
//		
//        BASS_ChannelGetData(currentModFile, buf, (ci.chans * 368 * sizeof(float)) | BASS_DATA_FLOAT); // get the sample data (floating-point to avoid 8 & 16 bit processing)
//
//
//
//        NSString *nsPattern  = [NSString  stringWithFormat:@"%03u", LOWORD(pos)];
//        NSString *nsRow  = [NSString  stringWithFormat:@"%03u", HIWORD(pos)];
//        NSNumber *nsLevel    = [[NSNumber alloc] initWithInt:level];
//        NSNumber *nsTime     = [[NSNumber alloc] initWithInt:time];
//        NSNumber *nsCpu      = [[NSNumber alloc] initWithFloat: cpu];
//        NSNumber *nsBuf      = [[NSNumber alloc] initWithFloat: *buf];
//        
//        
//        NSInteger *canvasWidth = (NSInteger *)[command.arguments objectAtIndex:0];
//        NSInteger *canvasHeight = (NSInteger *)[command.arguments objectAtIndex:1];
//
////        NSLog(@"CanvasSize %@x%@", canvasWidth, canvasHeight);
//
//        
//        NSArray *wavData;
//        
//        if ([wavDataType isEqual:@"wavform"]) {
////            NSLog(@"%@", wavDataType);
//            wavData = [self getWaveFormData:(NSInteger *)canvasWidth andHeight:(NSInteger *)canvasHeight];
//     
//        }
//        else if ([wavDataType isEqual:@"spectrum"]) {
////            NSLog(@"%@", wavDataType);
//
//            wavData = [self getSpectrumData];
//
//        }
//        else {
//            wavData = @[];
//        }
//        
//        jsonObj = [[NSDictionary alloc]
//                initWithObjectsAndKeys:
//                    nsLevel, @"level",
//                    nsPattern, @"pattern",
//                    nsRow, @"row",
//                    nsTime, @"time",
//                    nsBuf, @"buff",
//                    nsCpu, @"cpu",
//                    wavData, @"waveData",
//                    nil
//                ];
//    
//    }
//    else {
//    
//          
//         jsonObj = [[NSDictionary alloc]
//            initWithObjectsAndKeys:
//                @"false", @"success",
//                nil
//            ];
//
//    }
//    
//    
//    CDVPluginResult *pluginResult = [CDVPluginResult
//                                    resultWithStatus:CDVCommandStatus_OK
//                                    messageAsDictionary:jsonObj
//                                ];
//
//    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) cordovaGetSpectrumData:(CDVInvokedUrlCommand*)command{
//
//    CDVPluginResult* pluginResult;
//    
//    
//    NSArray *spectrumData = [self getSpectrumData];
//    
//    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:spectrumData];
//    
//
//    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

- (void) cordovaStopMusic:(CDVInvokedUrlCommand*)command {
    [self stopMusic];
//    BASS_ChannelStop(currentModFile);
////    BASS_Channel
//    BASS_ChannelSetPosition(currentModFile, 0, 0);
//    NSLog(@"STOPPING MUSIC");
    
}




@end

