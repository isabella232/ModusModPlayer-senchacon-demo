//
//  RCEGamePlayerInterface.m
//  UIExplorer
//
//  Created by Jesus Garcia on 3/7/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MCModPlayerInterface.h"

@implementation MCModPlayerInterface
//@synthesize bridge = _bridge;


- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView {
    if (self = [super initWithWebView:theWebView]) {
//        [self configureCommandCenter];
        NSLog(@"MCModPlayerInterface pluginInitialize");
        
        MCModPlayerInterface *interface = self;
        NSString *eformatString = @"window.updatePlayerViewPattern(%i, %i, %i);";
        
        
        self.then = CACurrentMediaTime();
        
        [[MCModPlayer sharedManager] registerInfoCallback:^(int32_t *playerState) {
            int ord     = (int)playerState[0];
            int pat     = (int)playerState[1];
            int row     = (int)playerState[2];
            int numRows = (int)playerState[3];
            
            double now = CACurrentMediaTime();
            int diff = (now - interface.then) * 1000;
            
            if (interface.currentOrder != ord || interface.currentPattern != pat || interface.currentRow != row) {
//                printf("Emitting event O:%i P:%i R:%i    Time Diff: %i(ms)\n", ord, pat, row, diff);
                fflush(stdout);
                interface.then = now;
                
                NSString* jsString = [NSString stringWithFormat:eformatString, ord, pat, row];
                [self.webView stringByEvaluatingJavaScriptFromString:jsString];

//                [_bridge.eventDispatcher sendDeviceEventWithName:@"rowPatternUpdate" body:@[
//                    
//                    [[NSNumber alloc] initWithInt:ord],
//                    [[NSNumber alloc] initWithInt:pat],
//                    [[NSNumber alloc] initWithInt:row],
//                    [[NSNumber alloc] initWithInt:numRows]
//                    
//                ]];
                
                
                self.currentRow     = row;
                self.currentOrder   = ord;
                self.currentPattern = pat;
            
            }
            
        }];

        return self;
    }

    return nil;
}

- (void) boot:(CDVInvokedUrlCommand*)command {
    [self respond:command withData:@{}];
}

- (void) respond:(CDVInvokedUrlCommand*)command withData:(id)resultData {
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:resultData
                        options:NSJSONWritingPrettyPrinted
                        error:&jsonError
                       ];
    
    NSString *jsonDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];


    
    CDVPluginResult *pluginResult = [CDVPluginResult
                                    resultWithStatus:CDVCommandStatus_OK
                                    messageAsString:jsonDataString
                                ];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}



- (void) loadFile:(CDVInvokedUrlCommand*)command {
    
    NSString *path = [command.arguments objectAtIndex:0];
    
    MCModPlayer *player = [MCModPlayer sharedManager];
    
    NSDictionary *modInfo = [player initializeSound:path];
    printf("                  ---------\n");

    self.currentRow     = nil;
    self.currentPattern = nil;
    self.currentOrder   = nil;
    
    
    NSArray *result;
    if (modInfo == nil) {
        result = @[@"Could not initialize audio."];
    }
    else {
        result = @[modInfo];
    }


    [self respond:command withData:result];
    
}


- (void) getPattern:(CDVInvokedUrlCommand*)command {

    NSNumber *patternNumber = [command.arguments objectAtIndex:0];

    
    NSArray *patternData = [[MCModPlayer sharedManager] getPatternData:patternNumber];
    
    NSArray *result;
    if (patternData == nil) {
        result = @[];
    }
    else {
        result = @[patternData];
    }

    [self respond:command withData:result];

}



- (void) getAllPatterns:(CDVInvokedUrlCommand*)command {
    NSString *path = [command.arguments objectAtIndex:0];

    NSDictionary *patternData = [[MCModPlayer sharedManager] getAllPatterns:path];
    
    
    NSArray *result;
    if (patternData == nil) {
        result = @[@"Could not initialize audio."];
    }
    else {
        result = @[patternData];
    }


   [self respond:command withData:result];
    
}

- (void) pause:(CDVInvokedUrlCommand*)command {
    [[MCModPlayer sharedManager] pause];
    [self respond:command withData:@{}];

}

- (void) resume:(CDVInvokedUrlCommand*)command {


    MCModPlayer *player = [MCModPlayer sharedManager];
    
    if (player.isPrimed) {
        [player play];
    }
    else {
        [player resume];
    }
    
    [self respond:command withData:@{}];
    
}


- (void) getFileInfo:(CDVInvokedUrlCommand*)command {

    
    NSString *path = [command.arguments objectAtIndex:0];

    NSMutableDictionary *gameObject = [[MCModPlayer sharedManager] getInfo:path];
    
    NSArray *result;
    if (gameObject == nil) {
       
        result = @[];
    }
 
    else {
        result = @[gameObject];
    }
    
    [self respond:command withData:result];
}




// TODO: Configure for cordova
- (void) configureCommandCenter {
//    MCModPlayer *player = [MCModPlayer sharedManager];
//    
//    /** Remote control management**/
//    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
//    
//    [[commandCenter playCommand] setEnabled:YES];
//    [[commandCenter pauseCommand] setEnabled:YES];
//    [[commandCenter seekForwardCommand] setEnabled:YES];
//    [[commandCenter seekBackwardCommand] setEnabled:YES];
//    [[commandCenter nextTrackCommand] setEnabled:YES];
//    [[commandCenter previousTrackCommand] setEnabled:YES];
//    
////    [[commandCenter stopCommand] setEnabled:YES];
//    
//    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
//        [player resume];
//        
//        NSLog(@"playCommand");
//        [[commandCenter playCommand] setEnabled:NO];
//        [[commandCenter pauseCommand] setEnabled:YES];
//        
//        
//        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
//            @"eventType" : @"play"
//        }];
//        
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//    
//    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
//        [player pause];
//        
//        NSLog(@"pauseCommand");
//        
//        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
//            @"eventType" : @"pause"
//        }];
//        
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//
//    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
//        //TODO: Handle next track (have no idea what to do here atm);
//        NSLog(@"nextTrackCommand");
//        
//        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
//            @"eventType" : @"nextTrack"
//        }];
//        
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//    
//    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
//        //TODO: Handle previous track (have no idea what to do here atm);
//        NSLog(@"previousTrackCommand");
//        
//       [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
//            @"eventType" : @"previousTrack"
//        }];
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//    
//    [commandCenter.seekBackwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
//        //TODO: Handle reverse seek.  Is this called continuously?
//        NSLog(@"seek backward");
//        
//        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
//            @"eventType" : @"seekBackward"
//        }];
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//    
//    [commandCenter.seekForwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent *event) {
//        //TODO: Handle forward seek.  Is this called continuously?
//        NSLog(@"seek forward");
//        
//        [_bridge.eventDispatcher sendDeviceEventWithName:@"commandCenterEvent" body:@{
//            @"eventType" : @"seekForward"
//        }];
//        
//        return MPRemoteCommandHandlerStatusSuccess;
//    }];
//
//
//    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//
//    [notificationCenter addObserver:self
//                           selector:@selector(audioRouteChanged:)
//                               name:AVAudioSessionRouteChangeNotification
//                             object:nil];

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
