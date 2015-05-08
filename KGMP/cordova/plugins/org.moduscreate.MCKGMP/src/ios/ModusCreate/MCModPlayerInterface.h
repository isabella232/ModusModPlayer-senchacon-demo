//
//  RCEGamePlayerInterface.h
//  UIExplorer
//
//  Created by Jesus Garcia on 3/7/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MCModPlayer.h"
#import "RCTBridgeModule.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"

@interface MCModPlayerInterface : NSObject <RCTBridgeModule>

@property NSDictionary *modInfo;

@property int currentRow;
@property int currentPattern;
@property int currentOrder;
@property double then;

- (void) audioRouteChanged:(NSNotification *)notification;


@end

