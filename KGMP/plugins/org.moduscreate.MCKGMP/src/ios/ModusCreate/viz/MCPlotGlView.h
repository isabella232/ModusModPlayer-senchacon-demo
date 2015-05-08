//
//  RCEzPlotGlView.h
//  UIExplorer
//
//  Created by Jesus Garcia on 3/8/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "RCTView.h"
#import "EZAudioPlotGL.h"

@interface MCPlotGlView : RCTView {
    EZAudioPlotGL *plotter;
}

- (void) update:(float[])data withSize:(int)size;
- (void) react_updateClippedSubviewsWithClipRect;

@end
