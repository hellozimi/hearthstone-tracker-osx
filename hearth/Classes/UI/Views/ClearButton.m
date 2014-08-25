//
//  ClearButton.m
//  hearth
//
//  Created by Simon Andersson on 08/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "ClearButton.h"
#import <QuartzCore/QuartzCore.h>
@implementation ClearButton

- (void)awakeFromNib {
    [super awakeFromNib];
    self.image = [NSImage imageNamed:@"clear"];
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc]
                                    initWithRect:[self bounds]
                                    options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                    owner:self userInfo:nil];
    self.alphaValue = 0.2;
    [self addTrackingArea:trackingArea];
    
    self.wantsLayer = YES;
}

- (void)animateFromAlpha:(float)fAlpha toAlpha:(float)tAlpha duration:(float)dur {
    
    CABasicAnimation *ba = [CABasicAnimation animationWithKeyPath:@"opacity"];
    ba.fromValue = @(fAlpha);
    ba.toValue = @(tAlpha);
    ba.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    ba.duration = dur;
    ba.fillMode = kCAFillModeForwards;
    ba.removedOnCompletion = NO;
    
    [[self layer]addAnimation:ba forKey:@"opacity.animation"];
}

- (void)mouseEntered:(NSEvent *)theEvent {
    [self animateFromAlpha:0.2 toAlpha:1.0 duration:0.15];
}

- (void)mouseExited:(NSEvent *)theEvent {
    [self animateFromAlpha:1.0 toAlpha:0.2 duration:0.15];
}

@end
