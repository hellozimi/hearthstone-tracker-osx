//
//  MatchCellView.m
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "MatchCellView.h"
#import "Hero.h"
#import "Match.h"
#import "HeroView.h"

#define kWinColor       [NSColor colorWithCalibratedRed:0.220 green:0.561 blue:0.184 alpha:1]
#define kLossColor      [NSColor colorWithCalibratedRed:0.678 green:0.200 blue:0.200 alpha:1]
#define kBlackColor     [NSColor colorWithCalibratedRed:0.200 green:0.200 blue:0.200 alpha:1]
#define kYellowColor    [NSColor colorWithCalibratedRed:0.698 green:0.655 blue:0.196 alpha:1]
#define kSeparatorColor [NSColor colorWithCalibratedRed:0.945 green:0.945 blue:0.945 alpha:1]

@interface MatchCellView ()

@property (weak) IBOutlet NSTextField *friendlyHeroLabel;
@property (weak) IBOutlet HeroView *friendlyHeroView;

@property (weak) IBOutlet NSTextField *opponentHeroLabel;
@property (weak) IBOutlet HeroView *opponentHeroView;
@property (weak) IBOutlet NSTextField *wlLabel;
@property (weak) IBOutlet NSTextField *durationLabel;

@end

@implementation MatchCellView

- (instancetype)init {
    NSString* nibName = NSStringFromClass([self class]);
    self = [super initWithFrame:NSMakeRect(0, 0, 480, 50)];
    if (self) {
        if ([[NSBundle mainBundle] loadNibNamed:nibName
                                          owner:self
                                topLevelObjects:nil]) {
            [self.view setFrame:[self bounds]];
            [self addSubview:self.view];
            
            NSView *separator = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 480, 1)];
            separator.wantsLayer = YES;
            separator.layer.backgroundColor = kSeparatorColor.CGColor;
            
            [self addSubview:separator];
        }
    }
    return self;
}

- (void)setMatch:(Match *)match {
    _match = match;
    
    if (_match.playing) {
        _wlLabel.stringValue = @"Playing";
        _wlLabel.textColor = kYellowColor;
        _wlLabel.toolTip = nil;
    }
    else if (!_match.victory && _match.conceded) {
        _wlLabel.stringValue = @"??";
        _wlLabel.toolTip = @"Someone conceded or you disconnected";
        _wlLabel.textColor = kBlackColor;
    }
    else if (_match.victory) {
        _wlLabel.stringValue = @"Win";
        _wlLabel.textColor = kWinColor;
        _wlLabel.toolTip = nil;
    }
    else {
        _wlLabel.stringValue = @"Loss";
        _wlLabel.textColor = kLossColor;
        _wlLabel.toolTip = nil;
    }
    
    CFTimeInterval startTime = [_match.startDate timeIntervalSince1970];
    CFTimeInterval endTime = [_match.endDate ?: [NSDate date] timeIntervalSince1970];
    
    CFTimeInterval durationInSeconds = endTime-startTime;
    int durationInMinutes = MIN(round(durationInSeconds / 60), 99);
    
    _durationLabel.stringValue = [NSString stringWithFormat:@"%imin", durationInMinutes];
    
    if (_match.friendlyHero.className) {
        _friendlyHeroLabel.stringValue = _match.friendlyHero.className;
    }
    _friendlyHeroView.backgroundColor = _match.friendlyHero.color;
    
    if (_match.opponentHero.className) {
        _opponentHeroLabel.stringValue = _match.opponentHero.className;
    }
    _opponentHeroView.backgroundColor = _match.opponentHero.color;
}

@end
