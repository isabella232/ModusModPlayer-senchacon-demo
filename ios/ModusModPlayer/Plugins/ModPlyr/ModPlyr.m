//
//
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import "ModPlyr.h"


@implementation ModPlyr : CDVPlugin {
    

}

static char note2charA[12]={'C','C','D','D','E','F','F','G','G','A','A','B'};
static char note2charB[12]={'-','#','-','#','-','-','#','-','#','-','#','-'};
static char dec2hex[16]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};


#pragma mark - libModPlug Implementation
- (ModPlugFile *) getMpFile {
    return self.mpFile;
}

- (void) stopMusic {
    if (self.mpFile) {
        AudioQueueStop(mAudioQueue, TRUE);
        AudioQueueReset(mAudioQueue);
    }
}

- (void) unloadFile {
    if (self.mpFile) {
        ModPlug_Unload(self.mpFile);
        self.mpFile = nil;
        free(loadedFileData);
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
    [self unloadFile];
    FILE *file;
    
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
    
//    [self preLoadPatterns];
//    [myObj performSelectorInBackground:@selector(doSomething) withObject:nil];

    patternsModPlugFile = ModPlug_Load(loadedFileData, loadedFileSize);
    [self performSelectorInBackground:@selector(preLoadPatterns) withObject:nil];

}

- (void) initModPlugSettings {
    if (! modPlugSettingsCommitted) {
    
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
        modPlugSettingsCommitted = true;
    }
}


- (void) myMainThreadMethod {
    NSLog(@"Thread kicked off");
    
    while (1) {
        [NSThread sleepForTimeInterval:0.1];
    
        NSLog(@"Teh Thread is werking");
        NSLog(@"ModName: %s", ModPlug_GetName(self.mpFile));
    }
}


// TODO: Set this up so we can play another song.
// It currently crashes because we re-initialize sound every time the play button is pressed.
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
    
    int bufferSize = SOUND_BUFFER_SIZE_SAMPLE * 2 * 2,
        bytesRead;

    for (int i = 0; i < SOUND_BUFFER_NB; i++) {
		AudioQueueBufferRef mBuffer;
		err = AudioQueueAllocateBuffer(mAudioQueue, bufferSize, &mBuffer );
		
		mBuffers[i] = mBuffer;
        mBuffer->mAudioDataByteSize = bufferSize;
        
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, bufferSize);
        
        AudioQueueEnqueueBuffer(mAudioQueue, mBuffers[i], 0, NULL);
    }
    
    
    /* Set initial playback volume */
    err = AudioQueueSetParameter(mAudioQueue, kAudioQueueParam_Volume, mVolume );
    err = AudioQueueStart(mAudioQueue, NULL );
}


void audioCallback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {
    NSLog(@"Buffer is being filled");
    ModPlyr *modPlayer = (__bridge ModPlyr*)data;
    ModPlugFile *mpFile = modPlayer.mpFile;
    
    int bytesRead;
    
    mBuffer->mAudioDataByteSize = SOUND_BUFFER_SIZE_SAMPLE*2*2;
    bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, mBuffer->mAudioDataByteSize);

    if (bytesRead < 1) {
        ModPlug_Seek(mpFile, 0);
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, mBuffer->mAudioDataByteSize);
    }
  
    AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);
}


- (void) preLoadPatterns  {
    patternDataReady = false;

    // Thread shit.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];

    if (songPatterns == nil) {
        songPatterns = [[NSMutableDictionary alloc]init];
    }

    // Clear the existing song patterns
    [songPatterns removeAllObjects];

    NSLog(@"START preLoadPatterns for %s", modName);
    NSDate *start = [NSDate date];
    
    // do stuff...
    ModPlugFile *mpFile = patternsModPlugFile;
    
    int bytesRead,
        currOrder,
        currPattrn,
        currRow,
        prevOrder,
        prevPattrn,
        prevRow;
    
    prevOrder = prevPattrn = prevRow =  -1;
    
    ModPlug_GetSettings(&settings);
    settings.mLoopCount = 0;
    ModPlug_SetSettings(&settings);
    
    int bufferSize = SOUND_BUFFER_SIZE_SAMPLE * 2 * 2;
    
    char *buffer = malloc(sizeof(char) * bufferSize);
    bytesRead = ModPlug_Read(mpFile, buffer, bufferSize);
    
    NSMutableString *orderMapper = [[NSMutableString alloc] init];
    
    // We're going to stuff row strings in here.
    NSMutableArray *patternStrings = [[NSMutableArray alloc]init];
    BOOL isOkToContinue = true;
    
    while (bytesRead > 0 && isOkToContinue) {
        
//        [NSThread sleepForTimeInterval: .1];
        
        currOrder  = ModPlug_GetCurrentOrder(mpFile);
        currPattrn = ModPlug_GetCurrentPattern(mpFile);
        currRow    = ModPlug_GetCurrentRow(mpFile);
        
//         if (currPattrn == 29) {
//            [NSThread sleepForTimeInterval:0.1];
//            printf("dafuq!\n");
//        }
        
        // This detects duplicate patterns, and prevents us from having to loop over them again.
        NSString *currPattrnKey = [NSString stringWithFormat:@"%d", currPattrn];
        if ([songPatterns objectForKey:currPattrnKey]) {
            printf("skipping O %i \t P %i  \n", currOrder, currPattrn);
            
           // This is a hacky way of testing to see if the fucking mod looped.
           // Even though we set mLoopCount to 0 (see above this while loop),
           // modPlug still loops on some mods. Fucker.
            NSString *currOrderString = [[NSString alloc] initWithFormat:@"%i,", currOrder];
           
            // TODO: Get pre-load detection working properly.
            unsigned int itemLocation = [orderMapper rangeOfString:currOrderString].location;
           
            if (itemLocation != NSNotFound) {
                NSLog(@"Song is looping! Aborting query for pattern data");
                isOkToContinue = false; // Set this so the loop can end!
                
                continue; // Break out of this loop fast!
            }

            bytesRead = ModPlug_Read(mpFile, buffer, bufferSize);
            
            continue;
        };
        
       
        // When we hit a new pattern, create a new array (patternStrings)
        // so that we can stuff strings (result of parsePattern) into it.
        if (currOrder != prevOrder && prevOrder != -1) {
          
            printf(" * Adding *    O %i \t P %i \t #Rows:%i\n", prevOrder, prevPattrn, [patternStrings count]);

            // Add new pattern
            NSString *key = [NSString stringWithFormat:@"%d", prevPattrn];
            [songPatterns setObject:patternStrings forKey:key];
            
            NSString *prevOrderString = [[NSString alloc] initWithFormat:@"%i,", prevOrder];
            [orderMapper appendString: prevOrderString];

//            printf("Adding >> Ord: %i\t pat: %i\t row: %i\n", currOrder, currPattrn, currRow);

            patternStrings = [[NSMutableArray alloc] init];
            NSMutableArray *rowData = [self parsePattern];
            [patternStrings addObject:rowData];
        }
    
        // Move along in the song so we don't get duplicate patterns in the array.
        else if (currPattrn == prevPattrn && currRow == prevRow) {
            bytesRead = ModPlug_Read(mpFile, buffer, bufferSize);
            continue;
        }
        
        // Add the patternData
        else {
//            printf("Adding -> Ord: %i\t pat: %i\t row: %i\n", currOrder, currPattrn, currRow);
            NSMutableArray *rowData = [self parsePattern];
            [patternStrings addObject:rowData];
        }
        
        prevPattrn = currPattrn;
        prevRow    = currRow;
        prevOrder  = currOrder;
        
        bytesRead = ModPlug_Read(mpFile, buffer, bufferSize);
    }
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    
    // Is this memset really needed?
    free(buffer);
    
    NSString *message = [[NSString alloc] initWithFormat:@"Done pre-buffering patterns %f(ms)", timeInterval];

    NSLog(@"%@", message);
    
    patternDataReady = true;
    
    //*** Thread stuff
    [pool release];
    [threadDictionary setValue:[NSNumber numberWithBool:1] forKey:@"ThreadShouldExitNow"];
    [NSThread exit];
}


- (NSMutableArray *) parsePattern {
//    printf("    parsePattern \n");
    NSMutableArray *row = [[NSMutableArray alloc] init];
    
    ModPlugFile *mpFile = self.mpFile;

    unsigned int rowsToGet;
    int currentPatternNumber = ModPlug_GetCurrentPattern(mpFile);

    ModPlugNote *pattern = ModPlug_GetPattern(mpFile, currentPatternNumber, &rowsToGet);
    
    if (! pattern) {
//        NSLog(@"No Pattern for pattern# %i!!", currentPatternNumber);
        return row;
    }
    
    // todo: optimize (by reusing previous data);
    int currRow = ModPlug_GetCurrentRow(mpFile),
        k       = 0,
        index,
        curPatPosition;
    
    unsigned int patternNote,
                 instrument,
                 volumeEffect,
                 effect,
                 volume,
                 parameter;
     /*
        static char note2charA[12]={'C','C','D','D','E','F','F','G','G','A','A','B'};
        static char note2charB[12]={'-','#','-','#','-','-','#','-','#','-','#','-'};
        static char dec2hex[16]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
    
    */

    // TODO: Fix this. (for some fucking reason, it's not actually reflecting real note data).
    // The following for loop was inspired by the Modizer project: https://github.com/yoyofr/modizer
    for (index = 0; index < numChannels; index++) {
        char stringData[50];
        k = 0;

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
            stringData[k++] = '.';
            stringData[k++] = '.';
            stringData[k++] = '.';
        }
        stringData[k++] = '|';
        
        if (instrument) {
            stringData[k++] = dec2hex[ (instrument >> 4) & 0xF ];
            stringData[k++] = dec2hex[ instrument & 0xF ];
        }
        else {
            stringData[k++] = '.';
            stringData[k++] = '.';
        }
        stringData[k++] = '|';

        
        if (volume) {
            stringData[k++] = dec2hex[ (volume >> 4) & 0xF ];
            stringData[k++] = dec2hex[ volume & 0xF ];
        }
        else {
            stringData[k++] = '.';
            stringData[k++] = '.';
        }
        stringData[k++] = '|';
        
        if (effect) {
            stringData[k++] = 'A' + effect;
        }
        else {
            stringData[k++] = '.';
        }
        stringData[k++] = '|';
        
        if (parameter) {
            stringData[k++] = dec2hex[(parameter >> 4) & 0xF];
            stringData[k++] = dec2hex[parameter & 0xF];
        }
        else {
            stringData[k++] = '.';
            stringData[k++] = '.';
        }
        
        NSString *rowString = [[NSString alloc] initWithFormat:@"%s", stringData];

        // This bit adds almost a full second of processing.
        // TODO: Migrate to a separate thread.
//        NSArray *parts = [rowString componentsSeparatedByString:@"|"];
//        
//        NSDictionary *rowObject = [[NSDictionary alloc] initWithObjectsAndKeys:
//                [parts objectAtIndex: 0], @"instrument",
//                [parts objectAtIndex: 1], @"volume",
//                [parts objectAtIndex: 2], @"effect",
//                [parts objectAtIndex: 3], @"parameter",
//                [parts objectAtIndex: 4], @"instrument",
//                nil
//            ];
        
        
        [row addObject: rowString];
    }
    
    return row;
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
        NSString *message = [[NSString alloc] initWithFormat: @"Could not load file: %@", file];
        NSLog(@"%@", message);
        
        
        jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    false,   @"success",
                    message, @"message",
                    nil
                ];
        
    }
    else {
        NSString *songName = [[NSString alloc] initWithCString: modName];
    
        NSLog(@"PLAYING : %s", modName);
        NSNumber *nsNumChannels = [[NSNumber alloc] initWithInt:numChannels];
        
        // This needs to be moved to a separate method;
        jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    @"true",       @"success",
                    nsNumChannels, @"numChannels",
                    songName,      @"songName",
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

    NSString *jsonDataString;
    
    if (patternDataReady) {
        NSError *jsonError;
       
        NSData *jsonData;
        
        jsonData = [NSJSONSerialization
                        dataWithJSONObject: (patternDataReady) ? songPatterns : @[]
                        options:NSJSONWritingPrettyPrinted
                        error:&jsonError
                   ];
        
       
        
        jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    }
    else {
        jsonDataString = @"notready";
    }
    
    
    CDVPluginResult *pluginResult = [CDVPluginResult
                                    resultWithStatus:(patternDataReady) ? CDVCommandStatus_OK : CDVCommandStatus_ERROR
                                    messageAsString: jsonDataString
                                ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];


}

// Copied from: http://stackoverflow.com/questions/8223348/ios-get-cpu-usage-from-application
- (float) getCpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;

    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;

    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;

    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads

    basic_info = (task_basic_info_t)tinfo;

    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;

    long tot_sec  = 0,
         tot_usec = 0;
    
    float tot_cpu = 0;
    int j;

    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }

        basic_info_th = (thread_basic_info_t)thinfo;

        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }

    } // for each thread

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);

    return tot_cpu;
}


- (void) cordovaGetStats:(CDVInvokedUrlCommand *)command {
    float cpuUsage   = [self getCpuUsage];
    int   currOrder  = ModPlug_GetCurrentOrder(self.mpFile);
    int   currPattrn = ModPlug_GetCurrentPattern(self.mpFile);
    int   currRow    = ModPlug_GetCurrentRow(self.mpFile);


    NSNumber *nsPattern  = [[NSNumber alloc] initWithInt:currPattrn];
    NSNumber *nsRow      = [[NSNumber alloc] initWithInt:currRow];
    NSNumber *nsOrder    = [[NSNumber alloc] initWithInt:currOrder];
    NSNumber *nsCpu      = [[NSNumber alloc] initWithFloat:cpuUsage];


    NSDictionary *jsonObj;


    jsonObj = [[NSDictionary alloc]
            initWithObjectsAndKeys:
                nsPattern, @"pattern",
                nsRow,     @"row",
                nsOrder,   @"order",
                nsCpu,     @"cpu",
                nil
            ];
    
    CDVPluginResult *pluginResult = [CDVPluginResult
                        resultWithStatus:CDVCommandStatus_OK
                        messageAsDictionary:jsonObj
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

