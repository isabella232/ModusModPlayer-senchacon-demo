//
//  MCPlotGlViewManager.m
//  UIExplorer
//
//  Created by Jesus Garcia on 3/8/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MCPlotGlViewManager.h"

@implementation MCPlotGlViewManager

- (UIView *)view {
//   NSLog(@"%@ %@",  NSStringFromClass([self class]),  NSStringFromSelector(_cmd));

    return [[MCPlotGlView alloc] init];
}


pthread_mutex_t myMutex = PTHREAD_MUTEX_INITIALIZER;

RCT_EXPORT_MODULE();

RCT_CUSTOM_VIEW_PROPERTY(plotterRegistered, BOOL, MCPlotGlView *) {
//    NSLog(@"%@ %@",  NSStringFromClass([self class]),  NSStringFromSelector(_cmd));
   
    if (! updateThread) {
        NSLog(@"------ creating update thread");
        updateThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadLoop:) object:*view];
        threadCondition = [[NSCondition alloc]init];
        
        [updateThread start];
    }
    
//    MCPlotGlView *theView = *view;
    NSLog(@"%@ view %p", json, view[0]);
    if (view[1]) {
        NSLog(@"view[1] %p", view[1]);
    }
    
    
    NSLog(@"%@ %p",  NSStringFromClass([self class]), view);
    
   
   
    [[MCGmePlayer sharedManager] setDelegate:self];
   

}


-(void) threadLoop:(MCPlotGlView *)view {
    NSLog(@"----- STARTING THREAD LOOP ----- ");
//    return;
    
    while ([[NSThread currentThread] isCancelled] == NO) {
//        [threadCondition lock];
        
//        
        while(threadLock) {
            NSLog(@" ----- will wait -----");
            sleep(.025);
//            [threadCondition wait];
            
            NSLog(@"Did wait");
            
        }
        
//        
         if (view && numFrames) {
            SInt16 *frames = bufferData;
            float splitter = 32768.0f;
            
//            MCPlotGlView *ltView = self.ltView;
            
            
            int index = 0;
            
            float *floatDataLt = malloc(sizeof(float) * numFrames / 2),
                  *floatDataRt = malloc(sizeof(float) * numFrames / 2);
            
            
            for (int x = 0; x < numFrames; x++) {
                float value = (frames[x] * 1.15) / splitter;
                
                if (x % 2) {
                    index++;
                    floatDataLt[index] = value;
                }
                else {
                    floatDataRt[index] = value;
                }
            }
            
//            [ltView[0] update:floatDataLt withSize:numFrames / 2];

//            [self.ltView update:floatDataLt withSize:numFrames / 2];
            [view update:floatDataRt withSize:numFrames / 2];
        }

    
        
        
//        threadLock = YES;
//        [threadCondition unlock];
    }
    
    


}

-(void) updateBuffers:(SInt16*)inBuffer withSize:(int)nFrames {

//    NSLog(@"%@  %@ %p",  NSStringFromClass([self class]),  NSStringFromSelector(_cmd), self);

    if (! bufferData) {
        bufferData = malloc(nFrames);
    }
    
    if (! threadLock) {
        threadLock = YES;
//        [threadCondition lock];

        
        memcpy(bufferData, inBuffer, nFrames);
        numFrames = nFrames;
//        [threadCondition signal];
        
        
        threadLock = NO;
//        [threadCondition unlock];

    }

}

@end
