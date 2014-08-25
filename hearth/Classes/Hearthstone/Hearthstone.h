//
//  Hearthstone.h
//  hearth
//
//  Created by Simon Andersson on 05/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Card.h"
@class Match;
typedef enum {
    PlayerMe,
    PlayerOpponent
} Player;

@interface Hearthstone : NSObject

@property (nonatomic, copy) void(^statusDidUpdate)(BOOL isRunning);
@property Match *currentPlayingMatch;

+ (instancetype)defaultInstance;

+ (NSString *)logPath;

- (BOOL)isHearthstoneRunning;
- (void)quit;

@end
