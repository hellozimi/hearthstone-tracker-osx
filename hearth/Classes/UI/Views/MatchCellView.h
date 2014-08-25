//
//  MatchCellView.h
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Match;
@interface MatchCellView : NSView

@property (nonatomic, strong) Match *match;
@property (nonatomic, strong) IBOutlet NSView *view;

@end
