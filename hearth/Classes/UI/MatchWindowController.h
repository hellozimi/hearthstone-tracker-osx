//
//  MatchWindowController.h
//  hearth
//
//  Created by Simon Andersson on 07/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Match;
@interface MatchWindowController : NSWindowController

@property (nonatomic, strong) Match *match;

- (void)updateStatus;
- (void)updateCards;

@end
