//
//
//  ModPlyr
//
//  Created by Jesus Garcia on 6/28/13.
//
//

#import "ModPlyr.h"

@implementation ModPlyr : CDVPlugin {
    int waveFormDataSize;
    
    
    SInt16 *sampleData;
    
    BOOL processingSampleData;
    
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
        if (sampleData) {
            printf(">> stopMusic free(sampleData);\n");

//            free(sampleData);
        }
    }
}

- (void) unloadFile {
    if (self.mpFile) {
        ModPlug_Unload(self.mpFile);
        self.mpFile = nil;
        free(loadedFileData);
//        free(sampleData);
    }
}

- (void) playSong {
    [self initModPlugSettings];

    ModPlug_SetMasterVolume(loadedModPlugFile, 256);
    ModPlug_Seek(loadedModPlugFile, 0);
    
    int len = ModPlug_GetLength(loadedModPlugFile);

    NSLog(@"Length: %i", len);
    NSLog(@"ModName: %s", modName);
    
    [self initSound];
    
//    [self playFile:firstFile];

}
- (void) loadFile:(NSString *)filePath  {
    [self unloadFile];
    self.generateAudioData = true;
    
    // TODO: Make waveFormDataSizeLimit Dynamic
    waveFormDataSize = 500;

    
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

    // TODO: Better exception handling.
    patternsModPlugFile = ModPlug_Load(loadedFileData, loadedFileSize);
    [self performSelectorInBackground:@selector(preLoadPatterns) withObject:nil];

}

- (void) initModPlugSettings {
    if (! modPlugSettingsCommitted) {
     
        ModPlug_GetSettings(&settings);

        settings.mFlags            = MODPLUG_ENABLE_OVERSAMPLING;
        settings.mChannels         = 2;
        settings.mBits             = 16;
        settings.mFrequency        = 44100;
        settings.mResamplingMode   = MODPLUG_RESAMPLE_NEAREST;
        settings.mReverbDepth      = 0;
        settings.mReverbDelay      = 100;
        settings.mBassAmount       = 0;
        settings.mBassRange        = 50;
        settings.mSurroundDepth    = 0;
        settings.mSurroundDelay    = 10;
        settings.mLoopCount        = -1;
        settings.mStereoSeparation = 64;
        
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

- (void) initSound {
    ModPlugFile *mpFile = self.mpFile;

    AudioStreamBasicDescription mDataFormat;
    UInt32 err;
    float mVolume = 1.0f;
    
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
                             CFRunLoopGetCurrent(),
                             kCFRunLoopCommonModes,
                             0,
                             &mAudioQueue);

    /* Create associated buffers */
    mBuffers = (AudioQueueBufferRef*) malloc( sizeof(AudioQueueBufferRef) * NUM_BUFFERS );
    
    int bufferSize = SOUND_BUFFER_SIZE_SAMPLE * 2 * 2,
//    int bufferSize = 1024,
//    int bufferSize = 512,
        bytesRead;


    for (int i = 0; i < NUM_BUFFERS; i++) {
		AudioQueueBufferRef mBuffer;
		err = AudioQueueAllocateBuffer(mAudioQueue, bufferSize, &mBuffer );
		
		mBuffers[i] = mBuffer;
        mBuffer->mAudioDataByteSize = bufferSize;
        
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, bufferSize);
        
//        printf("bytes read: %i\n", bytesRead);
        
        AudioQueueEnqueueBuffer(mAudioQueue, mBuffers[i], 0, NULL);
        
        SInt16 *frames = mBuffer->mAudioData;
        
        [self copyBufferData:frames withBufferSize:bufferSize];
    }
    
    
    
    
    /* Set initial playback volume */
    err = AudioQueueSetParameter(mAudioQueue, kAudioQueueParam_Volume, mVolume );
    err = AudioQueueStart(mAudioQueue, NULL );
    
//    AudioQueueProcessingTapRef tapRef;
//
//    
//    OSStatus tapStatus = AudioQueueProcessingTapNew(
//        mAudioQueue,
//        CFBridgingRetain(self),
//        audioTap,
//        kAudioQueueProcessingTap_Siphon,
//        (unsigned long*)bufferSize,
//        &mDataFormat,
//        &tapRef
//    );
//    
    
//    NSLog(@"Audio Tap Status: %u", (int)tapStatus);
    
    
}


void audioTap(void *                          inClientData,
              AudioQueueProcessingTapRef      inAQTap,
              UInt32                          inNumberFrames,
              AudioTimeStamp *                ioTimeStamp,
              UInt32 *                        ioFlags,
              UInt32 *                        outNumberFrames,
              AudioBufferList *               ioData) {
    
    // Nothing to do here yet
    
}

// Executed within a different context (not this class);
void audioCallback(void *data, AudioQueueRef mQueue, AudioQueueBufferRef mBuffer) {
    
    ModPlyr *modPlayer = (__bridge ModPlyr*)data;
    ModPlugFile *mpFile = modPlayer.mpFile;
    
    int bytesRead;
    
    
    ModPlug_GetChannelData(mpFile);
    bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, mBuffer->mAudioDataByteSize);

    if (bytesRead < 1) {
        ModPlug_Seek(mpFile, 0);
        bytesRead = ModPlug_Read(mpFile, (char*)mBuffer->mAudioData, mBuffer->mAudioDataByteSize);
    }
  
  // Convert the signed int to float
    if (modPlayer.generateAudioData) {
        SInt16 *frames = mBuffer->mAudioData;
        [modPlayer copyBufferData:frames withBufferSize:bytesRead];
    }
    
    AudioQueueEnqueueBuffer(mQueue, mBuffer, 0, NULL);
}


- (void) preLoadPatterns {

   patternDataReady = false;

    // Thread shit.
//    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];


    ModPlugFile *mpFile = self.mpFile;
    
    
    int numPatterns = (int) ModPlug_NumPatterns(mpFile),
        orderNum  = 0;
    
    unsigned int numRows;
    
    ModPlugNote *currentPattern;
    
    
    if (songPatterns == nil) {
        songPatterns = [[NSMutableDictionary alloc]init];
    }

    // Clear the existing song patterns
    [songPatterns removeAllObjects];


    NSLog(@"START preLoadPatterns for %s", modName);
    NSDate *start = [NSDate date];
    
    int totalPatterns = (int)numPatterns;
    int patternNum;

    while (orderNum != totalPatterns) {
        patternNum = ModPlug_GetPatternNumberAtOrder(mpFile, orderNum);
        
        currentPattern = ModPlug_GetPattern(mpFile, patternNum, &numRows);
//        NSLog(@">> %i", orderNum);
        
        int totalRows = (int)numRows;
        
        
        NSMutableArray *patternData = [self parsePattern:currentPattern withNumRows:totalRows];
        
        // Add new pattern
        NSString *key = [NSString stringWithFormat:@"%d", patternNum];
        [songPatterns setObject:patternData forKey:key];

        ++orderNum;
    }

//    NSLog(@"here");
    
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    NSString *message = [[NSString alloc] initWithFormat:@"Done pre-buffering patterns %f(ms)", timeInterval];
    NSLog(@"%@", message);
    
    patternDataReady = true;
    
    //*** Thread stuff
//    [pool release];
    [threadDictionary setValue:[NSNumber numberWithBool:1] forKey:@"ThreadShouldExitNow"];
    [NSThread exit];

}

- (NSMutableArray *) parsePattern:(ModPlugNote *)pattern withNumRows:(int)totalRows {
    
    
    NSMutableArray *patternData = [[NSMutableArray alloc] init],
                   *rowData;

    
    int currRow = 0;
    
    
    while (currRow < totalRows) {
        printf("Current row %i\n", currRow);
        rowData = [[NSMutableArray alloc] init];
        
        // todo: optimize (by reusing previous data);
        int k = 0,
            chanIdx;
        
        unsigned int patternNote,
                     instrument,
                     volumeEffect,
                     effect,
                     volume,
                     parameter,
                     curPatPosition;

         /*
            static char note2charA[12]={'C','C','D','D','E','F','F','G','G','A','A','B'};
            static char note2charB[12]={'-','#','-','#','-','-','#','-','#','-','#','-'};
            static char dec2hex[16]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
        */

        // TODO: Fix this. (for some fucking reason, it's not actually reflecting real note data).
        // The following for loop was inspired by the Modizer project: https://github.com/yoyofr/modizer
        for (chanIdx = 0; chanIdx < numChannels; chanIdx++) {
            char stringData[14],
                 *sd = stringData;
            
//            NSLog(@"sizeof(char) == %lu", sizeof(char));
            
            curPatPosition = chanIdx + (numChannels *  (int)currRow);

            patternNote  = pattern[curPatPosition].Note;
            instrument   = pattern[curPatPosition].Instrument;
            volumeEffect = pattern[curPatPosition].VolumeEffect;
            effect       = pattern[curPatPosition].Effect;
            volume       = pattern[curPatPosition].Volume;
            parameter    = pattern[curPatPosition].Parameter;

            if (patternNote) {
                *sd++ = note2charA[(patternNote - 13) % 12];
                *sd++ = note2charB[(patternNote - 13) % 12];
                *sd++ = (patternNote - 13) / 12 + '0';
            }
            else {
                *sd++ = '.';
                *sd++ = '.';
                *sd++ = '.';
            }
            *sd++ = ' ';
            
            if (instrument) {
                *sd++ = dec2hex[ (instrument >> 4) & 0xF ];
                *sd++ = dec2hex[ instrument & 0xF ];
            }
            else {
                *sd++ = '.';
                *sd++ = '.';
            }
            *sd++ = ' ';

            
            if (volume) {
                *sd++ = dec2hex[ (volume >> 4) & 0xF ];
                *sd++ = dec2hex[ volume & 0xF ];
            }
            else {
                *sd++ = '.';
                *sd++ = '.';
            }
            *sd++ = ' ';
            
            if (effect) {
                *sd++ = 'A' + effect;
            }
            else {
                *sd++ = '.';
            }
            *sd++ = ' ';
            
            if (parameter) {
                *sd++ = dec2hex[(parameter >> 4) & 0xF];
                *sd++ = dec2hex[parameter & 0xF];
            }
            else {
                *sd++ = '.';
                *sd++ = '.';
            }
            
            // Null terminate the string.
            *sd++ = '\0';
            
            
//            printf("%lu\n", strlen(stringData));
            
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
            
            [rowData addObject: rowString];
        }

    
    
        [patternData addObject:rowData];
        ++currRow;
    }


    return [[NSMutableArray alloc]init];
//    return patternData;
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
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
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

- (void) pauseMusic {
    NSLog(@"pauseMusic()");

}

- (void) copyBufferData:(SInt16 *)frames withBufferSize:(int)size {
//    ltFrameVal = (frames[0] / 32767.5);
//    rtFrameVal = (frames[1] / 32767.5);
//    
    
    if (! processingSampleData) {
        if (sampleData) {
//            printf(">> copyBufferData free(sampleData);\n");
            free(sampleData);
        }
        sampleData = malloc(sizeof(SInt16) * size);
    
        memcpy(sampleData, frames, size);
    }
// TODO: calculate the audio data

}


- (NSMutableArray*) getWaveFormData:(NSInteger*)width  andHeight:(NSInteger*)height {
    int x,y;

    processingSampleData = true;
    // TODO: Use width and height parameters here. Need to figure out how to cast from NSInteger to int!!!!
    int SPECHEIGHT = 213;
    int SPECWIDTH =  1000;


    NSMutableArray *channelData    = [[NSMutableArray alloc] init];
    NSMutableArray *channelOneData = [[NSMutableArray alloc] init];
    NSMutableArray *channelTwoData = [[NSMutableArray alloc] init];

    int c;
    
    SInt16 *buf = sampleData;
    
    for ( c = 0; c < 2;c ++) {
        for (x = 0; x < SPECWIDTH; x++) {
            NSNumber *plotItem;

            int val = x * 2 + c;
            SInt16 itemRaw = buf[ val ];
            
            float item = itemRaw / 32767.5;
            
            
//            printf("%f\n", item);
            int v = ( 1 - item) * SPECHEIGHT /2; // invert and scale to fit display
        
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
                
                
                plotItem = [[NSNumber alloc] initWithInt:v];

            } while (y!=v);
    
            if (c == 0) {
                [channelOneData addObject: plotItem];
            }
            else {
                [channelTwoData addObject: plotItem];

            }
        }
    }

    [channelData addObject:channelOneData];
    [channelData addObject:channelTwoData];
    
    processingSampleData = false;
    return channelData;

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

    NSString *dataType = [command.arguments objectAtIndex:0];


//    NSLog(@"cordovaGetStats :: %@", dataType);

    NSDictionary *jsonObj;

//    NSMutableArray *waveData;
 
    if ([dataType isEqualToString:@"pattern"]) {
        NSNumber *nsPattern = [[NSNumber alloc] initWithInt:ModPlug_GetCurrentPattern(self.mpFile)];
        NSNumber *nsRow     = [[NSNumber alloc] initWithInt:ModPlug_GetCurrentRow(self.mpFile)];
        NSNumber *nsOrder   = [[NSNumber alloc] initWithInt:ModPlug_GetCurrentOrder(self.mpFile)];
        NSNumber *nsCpu     = [[NSNumber alloc] initWithFloat:[self getCpuUsage]];

        jsonObj = [[NSDictionary alloc]
                initWithObjectsAndKeys:
                    nsPattern, @"pattern",
                    nsRow,     @"row",
                    nsOrder,   @"order",
                    nsCpu,     @"cpu",
                    nil
                ];
    

    }
    else if ([dataType isEqualToString:@"spectrum"]) {

//        NSInteger *canvasWidth  = (NSInteger *)[command.arguments objectAtIndex:1];
//        NSInteger *canvasHeight = (NSInteger *)[command.arguments objectAtIndex:2];
        NSInteger *canvasWidth  = 500;
        NSInteger *canvasHeight = 233;

//        NSString  *waveDataType = [command.arguments objectAtIndex:3];
        NSString *waveDataType = @"waveform";
        
        NSMutableArray *waveData;
        
        if ([waveDataType isEqual:@"waveform"]) {
//            [self getWaveFormData:(NSInteger *)canvasWidth andHeight:(NSInteger *)canvasHeight];
            
            waveData = [self getWaveFormData:(NSInteger *)canvasWidth andHeight:(NSInteger *)canvasHeight];
        }
        else if ([waveDataType isEqual:@"spectrum"]) {
//            waveData = [[[NSMutableArray alloc] init] autorelease];
//            waveData = [self getSpectrumData];
        }
        else {
//            waveData = [[[NSMutableArray alloc] init] autorelease];
        }
        
//        NSNumber *lt = [[[NSNumber alloc] initWithInt:ltChannelPlot] autorelease];
//        NSNumber *rt = [[[NSNumber alloc] initWithInt:rtChannelPlot] autorelease];
        
//        NSLog(@"lt : %i \t\t rt : %i", ltChannelPlot, rtChannelPlot);
        
        jsonObj = [[NSDictionary alloc]
            initWithObjectsAndKeys:
                waveData, @"waveData",
                nil
            ];
        
//        [waveData release];


    }
    
    else {
        jsonObj = [[NSDictionary alloc] initWithObjectsAndKeys:
            false, @"success",
            nil];
    
    }
    
    
    CDVPluginResult *pluginResult = [CDVPluginResult
        resultWithStatus:CDVCommandStatus_OK
        messageAsDictionary:jsonObj
    ];

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
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
}



- (void) cordovaPauseMusic:(CDVInvokedUrlCommand*)command {
    [self pauseMusic];
}


@end

