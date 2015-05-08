//
//  RCEGamePlayerInterface.m
//  UIExplorer
//
//  Created by Jesus Garcia on 3/7/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MCModPlayerInterface.h"

@implementation MCModPlayerInterface
@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (instancetype) init {
    if (self = [super init]) {
        [self configureCommandCenter];
            NSLog(@"MCModPlayerInterface init");
        
        MCModPlayerInterface *interface = self;
        NSString *formatString = @"%i";
        
        
        self.then = CACurrentMediaTime();
        
        [[MCModPlayer sharedManager] registerInfoCallback:^(int32_t *playerState) {
            int ord     = (int)playerState[0];
            int pat     = (int)playerState[1];
            int row     = (int)playerState[2];
            int numRows = (int)playerState[3];
            
            double now = CACurrentMediaTime();
            int diff = (now - interface.then) * 1000;
            
            if (interface.currentOrder != ord || interface.currentPattern != pat || interface.currentRow != row) {
                printf("Emitting event O:%i P:%i R:%i    Time Diff: %i(ms)\n", ord, pat, row, diff);
                fflush(stdout);
                interface.then = now;
                
                
                [_bridge.eventDispatcher sendDeviceEventWithName:@"rowPatternUpdate" body:@[
                    
                    [[NSNumber alloc] initWithInt:ord],
                    [[NSNumber alloc] initWithInt:pat],
                    [[NSNumber alloc] initWithInt:row],
                    [[NSNumber alloc] initWithInt:numRows]
                    
                ]];
                
                
                interface.currentRow     = row;
                interface.currentOrder   = ord;
                interface.currentPattern = pat;
            
            }
            
        }];

        return self;
    }

    return nil;
}


// DEPRECATED
RCT_EXPORT_METHOD(playFile:(NSString *)path
                 errorCallback:(RCTResponseSenderBlock)errorCallback
                 callback:(RCTResponseSenderBlock)callback) {
    
    printf("                  ---------          \n");
    MCModPlayer *player = [MCModPlayer sharedManager];
    
    NSDictionary *modInfo = [player initializeSound:path];
    
    self.currentRow     = nil;
    self.currentPattern = nil;
    self.currentOrder   = nil;
    
    if (modInfo == nil) {
        errorCallback(@[@"Could not initialize audio."]);
    }
    else {
        callback(@[@""]);
    }
    
    
}


RCT_EXPORT_METHOD(loadFile:(NSString *)path
                 errorCallback:(RCTResponseSenderBlock)errorCallback
                 callback:(RCTResponseSenderBlock)callback) {
    
    
    MCModPlayer *player = [MCModPlayer sharedManager];
    
    NSDictionary *modInfo = [player initializeSound:path];
    printf("                  ---------          \n");

    self.currentRow     = nil;
    self.currentPattern = nil;
    self.currentOrder   = nil;
    
    if (modInfo == nil) {
        errorCallback(@[@"Could not initialize audio."]);
    }
    else {
        callback(@[modInfo]);
    }

}



RCT_EXPORT_METHOD(getPattern:(NSNumber *)patternNumber
                   errorCallback:(RCTResponseSenderBlock)errorCallback
                        callback:(RCTResponseSenderBlock)callback) {

    NSArray *patternData = [[MCModPlayer sharedManager] getPatternData:patternNumber];
    
    if (patternData == nil) {
        errorCallback(@[]);
    }
    else {
        callback(@[patternData]);
    }
    
}



RCT_EXPORT_METHOD(getAllPatterns:(NSString *)path
                   errorCallback:(RCTResponseSenderBlock)errorCallback
                        callback:(RCTResponseSenderBlock)callback) {

    NSDictionary *patternData = [[MCModPlayer sharedManager] getAllPatterns:path];
    
    if (patternData == nil) {
        errorCallback(@[]);
    }
    else {
        callback(@[patternData]);
    }
    
}




RCT_EXPORT_METHOD(pause:(RCTResponseSenderBlock)callback) {
    [[MCModPlayer sharedManager] pause];
    
    callback(@[]);
}


RCT_EXPORT_METHOD(resume:(RCTResponseSenderBlock)callback) {
    MCModPlayer *player = [MCModPlayer sharedManager];
    
    if (player.isPrimed) {
        [player play];
    }
    else {
        [player resume];
    }
    
    callback(@[]);
    
    
    
}

RCT_EXPORT_METHOD(getFileInfo:(NSString *)path
            errorCallback:(RCTResponseSenderBlock)errorCallback
             callback:(RCTResponseSenderBlock)callback) {
    
    
    NSMutableDictionary *gameObject = [[MCModPlayer sharedManager] getInfo:path];
    
    if (gameObject == nil) {
       
        errorCallback(@[]);
    }
 
    else {
        callback(@[gameObject]);
    }
}





- (void) configureCommandCenter {
    MCModPlayer *player = [MCModPlayer sharedManager];
    
    /** Remote control management**/
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    [[commandCenter playCommand] setEnabled:YES];
    [[commandCenter pauseCommand] setEnabled:YES];
    [[commandCenter seekForwardCommand] setEnabled:YES];
    [[commandCenter seekBackwardCommand] setEnabled:YES];
    [[commandCenter nextTrackCommand] setEnabled:YES];
    [[commandCenter previousTrackCommand] setEnabled:YES];
    
//    [[commandCenter stopCommand] setEnabled:YES];
    
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [player resume];
        
        NSLog(@"playCommand");
        [[commandCenter playCommand] setEnabled:NO];
        [[commandCenter pauseCommand] setEnabled:YES];
        
        
        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
            @"eventType" : @"play"
        }];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        [player pause];
        
        NSLog(@"pauseCommand");
        
        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
            @"eventType" : @"pause"
        }];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        //TODO: Handle next track (have no idea what to do here atm);
        NSLog(@"nextTrackCommand");
        
        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
            @"eventType" : @"nextTrack"
        }];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        //TODO: Handle previous track (have no idea what to do here atm);
        NSLog(@"previousTrackCommand");
        
       [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
            @"eventType" : @"previousTrack"
        }];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.seekBackwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        //TODO: Handle reverse seek.  Is this called continuously?
        NSLog(@"seek backward");
        
        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
            @"eventType" : @"seekBackward"
        }];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.seekForwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
        //TODO: Handle forward seek.  Is this called continuously?
        NSLog(@"seek forward");
        
        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
            @"eventType" : @"seekForward"
        }];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];


    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(audioRouteChanged:)
                               name:AVAudioSessionRouteChangeNotification
                             object:nil];

}


// TODO: Is there anything to do here? Pause/resume?
- (void) audioRouteChanged:(NSNotification *)notification {
    NSInteger routeChangeReason = [notification.userInfo[AVAudioSessionRouteChangeReasonKey] integerValue];
    
    if (routeChangeReason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        [[MCModPlayer sharedManager] pause];
    };
    
    NSLog(@"Route change, %ld", (long)routeChangeReason);
}


@end
