//
//  EZPlotGlView.m
//  UIExplorer
//
//  Created by Jesus Garcia on 3/8/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MCPlotGlView.h"

@implementation MCPlotGlView


- (id)initWithFrame:(CGRect)frame {
    NSLog(@"%@ %@() %p",  NSStringFromClass([self class]), NSStringFromSelector(_cmd), self);
    self = [super initWithFrame:frame];
    
           
    self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:1];

    
    return self;
}

// Called via manager
- (void) update:(float[])data withSize:(int)size {
    
    NSLog(@"update() %f", data[0]);
    
    
    if (! plotter) {
        NSLog(@"%@ created an EZAudioPlotGL",  NSStringFromClass([self class]));
        plotter = [[EZAudioPlotGL alloc] initWithFrame:self.bounds];
        plotter.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:1];
        plotter.plotType = EZPlotTypeBuffer;
        [self addSubview:plotter];
        
    }
    
    [plotter updateBuffer:data withBufferSize:size];
}


@end
