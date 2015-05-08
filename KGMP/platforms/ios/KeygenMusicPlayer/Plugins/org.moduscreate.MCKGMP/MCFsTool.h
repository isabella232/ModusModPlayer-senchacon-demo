//
//  MCFsTool.h
//
//  Created by Jesus Garcia on 3/5/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

// TODO: Convert to bridge module

#import <mach/mach.h>
#import <Cordova/CDV.h>

@interface MCFsTool : CDVPlugin

- (NSMutableArray *) getContentsOfDirectory:(NSString*)path;

@end
