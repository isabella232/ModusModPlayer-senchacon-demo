//
//  RCEzPlotGlViewManager.h
//  UIExplorer
//
//  Created by Jesus Garcia on 3/8/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "RCTViewManager.h"

#import "MCPlotGlView.h"
#import "MCGmePlayer.h"
#import <pthread.h>


@interface MCPlotGlViewManager : RCTViewManager {
    NSCondition *threadCondition;
    NSThread *updateThread;
    BOOL threadLock;
    
    SInt16 *bufferData;
    int numFrames;
}

@property MCPlotGlView *ltView;
@property MCPlotGlView *rtView;

-(void) updateBuffers:(SInt16*)inBuffer withSize:(int)numFrames;

@end
