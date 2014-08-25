//
//  MatchWindowController.m
//  hearth
//
//  Created by Simon Andersson on 07/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "MatchWindowController.h"
#import "HeroView.h"
#import "DataMananger.h"
#import "Match.h"
#import "Hero.h"
#import "Card.h"

#import "Hearthstone.h"

static const float offsetTop = 90;

#define kWinColor       [NSColor colorWithCalibratedRed:0.220 green:0.561 blue:0.184 alpha:1]
#define kLossColor      [NSColor colorWithCalibratedRed:0.678 green:0.200 blue:0.200 alpha:1]
#define kBlackColor     [NSColor colorWithCalibratedRed:0.200 green:0.200 blue:0.200 alpha:1]
#define kYellowColor    [NSColor colorWithCalibratedRed:0.698 green:0.655 blue:0.196 alpha:1]

@interface HCFlipView : NSView
@end

@implementation HCFlipView
- (BOOL)isFlipped {
    return YES;
}
@end

@interface MatchWindowController ()

@property (weak) IBOutlet NSView *friendlyHeroView;
@property (weak) IBOutlet NSView *opponentHeroView;
@property (weak) IBOutlet NSTextField *friendlyHeroClassLabel;
@property (weak) IBOutlet NSTextField *opponentHeroClassLabel;

@property HCFlipView *friendlyCardWrapper;
@property HCFlipView *opponentCardWrapper;

@property NSArray *friendlyCards;
@property NSArray *opponentCards;

@property (weak) IBOutlet NSTextField *statusLabel;

@end

@implementation MatchWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    //self.window.backgroundColor = [NSColor colorWithCalibratedRed:10 green:1.0 blue:1.0 alpha:1.0];
    
    _friendlyHeroView.wantsLayer = YES;
    _opponentHeroView.wantsLayer = YES;
    _friendlyHeroView.layer.backgroundColor = [NSColor redColor].CGColor;
    _opponentHeroView.layer.backgroundColor = [NSColor blueColor].CGColor;
    
    [[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
}

- (NSView *)cardItemViewForGroup:(NSArray *)group {
    HCFlipView *view = [[HCFlipView alloc] initWithFrame:NSMakeRect(0, 0, 180, 17)];
    
    NSImageView *hexaImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 2, 15, 13)];
    hexaImageView.image = [NSImage imageNamed:@"hexagon"];
    
    [view addSubview:hexaImageView];
    
    NSTextField *manaLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 1.5, 15, 13)];
    manaLabel.bordered = NO;
    manaLabel.drawsBackground = NO;
    manaLabel.selectable = NO;
    [manaLabel setFont:[NSFont fontWithName:@"Helvetica-Light" size:10]];
    manaLabel.textColor = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
    manaLabel.alignment = NSCenterTextAlignment;
    [view addSubview:manaLabel];
    
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 0, 160, 17)];
    label.bordered = NO;
    label.drawsBackground = NO;
    label.selectable = NO;
    [label setFont:[NSFont fontWithName:@"Helvetica-Light" size:12]];
    label.textColor = [NSColor colorWithCalibratedRed:0.200 green:0.200 blue:0.200 alpha:1];
    Card *card = [group firstObject];
    
    label.stringValue = [NSString stringWithFormat:@"%@%@", card.name, group.count > 1 ? [NSString stringWithFormat:@" x %ld", group.count] : @""];
    manaLabel.stringValue = [NSString stringWithFormat:@"%i", [card.cost intValue]];
    
    [view addSubview:label];
    return view;
}

- (void)setMatch:(Match *)match {
    _match = match;
    
    _friendlyHeroView.layer.backgroundColor = _match.friendlyHero.color.CGColor;
    _opponentHeroView.layer.backgroundColor = _match.opponentHero.color.CGColor;
    
    _friendlyHeroClassLabel.stringValue = _match.friendlyHero.className;
    _opponentHeroClassLabel.stringValue = _match.opponentHero.className;
    
    _friendlyCards = [self sortAndGroupCardArray:_match.friendlyCards];
    _opponentCards = [self sortAndGroupCardArray:_match.opponentCards];
    
    
    float highestCardList = MAX(_friendlyCards.count*17, _opponentCards.count*17);
    float wantedWindowHeight = offsetTop + highestCardList + 20;
    NSRect windowFrame = self.window.frame;
    windowFrame.size.height = wantedWindowHeight;
    
    windowFrame.origin.x = ([self.window screen].frame.size.width - windowFrame.size.width) / 2;
    windowFrame.origin.y = ([self.window screen].frame.size.height - windowFrame.size.height) / 2;
    windowFrame = [self.window frameRectForContentRect:windowFrame];
    [self.window setFrame:windowFrame display:YES animate:NO];
    
    
    [self updateCards];
    [self updateStatus];
}

- (void)updateStatus {
    if (_match.playing) {
        _statusLabel.stringValue = @"Playing";
        _statusLabel.textColor = kYellowColor;
    }
    else if (_match.conceded) {
        _statusLabel.stringValue = @"??";
        _statusLabel.textColor = kBlackColor;
    }
    else if (_match.victory) {
        _statusLabel.stringValue = @"Win";
        _statusLabel.textColor = kWinColor;
    }
    else {
        _statusLabel.stringValue = @"Loss";
        _statusLabel.textColor = kLossColor;
    }
}

- (void)updateCards {
    
    _friendlyCards = [self sortAndGroupCardArray:_match.friendlyCards];
    _opponentCards = [self sortAndGroupCardArray:_match.opponentCards];
    
    NSRect windowFrame = self.window.frame;
    
    float highestCardList = MAX(_friendlyCards.count*17, _opponentCards.count*17);
    float wantedWindowHeight = offsetTop + highestCardList + 20;
    
    windowFrame.size.height = wantedWindowHeight;
    windowFrame = [self.window frameRectForContentRect:windowFrame];
    [self.window setFrame:windowFrame display:YES animate:NO];
    
    NSRect wframe = self.window.frame;
    wframe = [self.window contentRectForFrameRect:wframe];
    
    
    [_friendlyCardWrapper setSubviews:@[]];
    [_opponentCardWrapper setSubviews:@[]];
    
    [_friendlyCardWrapper removeFromSuperview];
    _friendlyCardWrapper = nil;
    [_opponentCardWrapper removeFromSuperview];
    _opponentCardWrapper = nil;
    
    // Friendly
    float h = _friendlyCards.count*17;
    float y = wframe.size.height-h-offsetTop;
    _friendlyCardWrapper = [[HCFlipView alloc] initWithFrame:NSMakeRect(20, y, 180, h)];
    
    [self.window.contentView addSubview:_friendlyCardWrapper];
    
    [_friendlyCards enumerateObjectsUsingBlock:^(NSArray *arr, NSUInteger idx, BOOL *stop) {
        NSView *cardItemView = [self cardItemViewForGroup:arr];
        NSRect rect = cardItemView.frame;
        rect.origin.y = (idx * rect.size.height);
        cardItemView.frame = rect;
        
        [_friendlyCardWrapper addSubview:cardItemView];
    }];
    
    // Opposite
    h = _opponentCards.count*17;
    y = wframe.size.height-h-offsetTop;
    _opponentCardWrapper = [[HCFlipView alloc] initWithFrame:NSMakeRect(_opponentHeroView.frame.origin.x, y, 180, h)];
    
    [self.window.contentView addSubview:_opponentCardWrapper];
    
    [_opponentCards enumerateObjectsUsingBlock:^(NSArray *arr, NSUInteger idx, BOOL *stop) {
        NSView *cardItemView = [self cardItemViewForGroup:arr];
        NSRect rect = cardItemView.frame;
        rect.origin.y = (idx * rect.size.height);
        cardItemView.frame = rect;
        
        [_opponentCardWrapper addSubview:cardItemView];
    }];
}

- (IBAction)settingsMenuClick:(id)sender {
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Settings"];
    
    if (_match.playing || _match.conceded) {
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Claim win" action:@selector(claimWin:) keyEquivalent:@""]];
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Claim loss" action:@selector(claimLoss:) keyEquivalent:@""]];
    }
    else if (_match.victory) {
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Claim loss" action:@selector(claimLoss:) keyEquivalent:@""]];
    }
    else {
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Claim win" action:@selector(claimWin:) keyEquivalent:@""]];
    }
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Delete this match" action:@selector(removeCurrentMatch:) keyEquivalent:@""]];
    
    
    // For later
    //[menu addItem:[[NSMenuItem alloc] initWithTitle:@"Claim win" action:nil keyEquivalent:@""]];
    
    [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:sender withFont:[NSFont fontWithName:@"HelveticaNeue" size:15]];
}

- (void)claimWin:(id)sender {
    _match.conceded = NO;
    _match.victory = YES;
    _match.playing = NO;
    [_match endGame];
    [[DataMananger sharedManager] store];
    if ([Hearthstone defaultInstance].currentPlayingMatch == _match) {
        [Hearthstone defaultInstance].currentPlayingMatch = nil;
    }
}

- (void)claimLoss:(id)sender {
    _match.conceded = NO;
    _match.playing = NO;
    _match.victory = NO;
    [_match endGame];
    [[DataMananger sharedManager] store];
    if ([Hearthstone defaultInstance].currentPlayingMatch == _match) {
        [Hearthstone defaultInstance].currentPlayingMatch = nil;
    }
}

- (void)removeCurrentMatch:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Yes, delete it"];
    [alert addButtonWithTitle:@"No, keep it"];
    [alert setMessageText:@"Are you sure you want to delete this match?"];
    [alert setInformativeText:@"Deleted matches cannot be restored."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[DataMananger sharedManager] removeMatch:_match];
        
        [self.window close];
    }
}

- (NSArray *)sortAndGroupCardArray:(NSArray *)cards {
    NSSortDescriptor *sortCost = [[NSSortDescriptor alloc] initWithKey:@"cost" ascending:YES];
    NSSortDescriptor *sortName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortCost, sortName, nil];
    
    NSArray *ar = [cards sortedArrayUsingDescriptors:sortDescriptors];
    
    NSMutableArray *groupedArray = [NSMutableArray new];
    for (int i = 0; i < [ar count]; i++) {
        NSMutableArray *objArray = [NSMutableArray new];
        id obj1 = ar[i];
        [objArray addObject:obj1];
        for (int y = 0; y < [ar count]; y++) {
            id obj2 = ar[y];
            if ([obj1 isEqualTo:obj2] && i != y) {
                [objArray addObject:obj2];
                i++;
            }
        }
        [groupedArray addObject:objArray];
    }
    return groupedArray;
}

@end
