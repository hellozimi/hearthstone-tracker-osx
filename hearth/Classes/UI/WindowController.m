//
//  WindowController.m
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "WindowController.h"
#import "DataMananger.h"
#import "Match.h"
#import "Hearthstone.h"
#import "MatchWindowController.h"
#import "MatchCellView.h"
#import "HCTableView.h"
#import "ClearButton.h"

@interface WindowController () <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>
@property (weak) IBOutlet HCTableView *tableView;
@property NSArray *data;
@property NSImageView *hearthstoneStatusImageView;
@property (weak) IBOutlet NSTextField *wlTitleLabel;
@property (weak) IBOutlet NSTextField *wlFriendlyScoreLabel;
@property (weak) IBOutlet NSTextField *wlOpponentScoreLabel;
@property (weak) IBOutlet NSTextField *wlPercentageLabel;
@property NSMutableArray *matchWindowControllers;
@property (weak) IBOutlet ClearButton *clearCurrentSessionButton;
@property (weak) IBOutlet NSView *leftPageIndicatorView;
@property (weak) IBOutlet NSView *rightPageIndicatorView;
@property BOOL wlLifetimeState;
@end

@implementation WindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    _matchWindowControllers = [NSMutableArray new];
    
    _wlLifetimeState = YES;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _data = [[DataMananger sharedManager] matches];
    [_tableView reloadData];
    
    self.window.title = @"Hearth";
    
    self.window.delegate = self;
    
    __weak typeof(self) ws = self;
    
    [[DataMananger sharedManager] setDataUpdateBlock:^{
        ws.data = [[DataMananger sharedManager] matches];
        [ws.tableView reloadData];
        [ws updateWLSForCurrentState];
        
        [ws.matchWindowControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [obj updateCards];
            [obj updateStatus];
        }];
    }];
    
    [_tableView setDidClickRow:^(NSInteger row) {
        Match *match = ws.data[row];
        
        MatchWindowController *mwc = nil;
        BOOL alreadyShowing = NO;
        
        for (MatchWindowController *amwc in ws.matchWindowControllers) {
            if ([amwc.match isEqual:match]) {
                alreadyShowing = YES;
                mwc = amwc;
                break;
            }
        }
        
        if (alreadyShowing) {
            [mwc updateCards];
            [mwc updateStatus];
            [mwc.window makeKeyAndOrderFront:ws];
        }
        else {
            mwc = [[MatchWindowController alloc] initWithWindowNibName:@"MatchWindowController"];
            [mwc showWindow:ws];
            mwc.match = ws.data[row];
            mwc.window.delegate = ws;
            [_matchWindowControllers addObject:mwc];
            [mwc.window makeKeyAndOrderFront:ws];
        }
    }];
    
    [[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    
    
    _leftPageIndicatorView.wantsLayer = _rightPageIndicatorView.wantsLayer = YES;
    _leftPageIndicatorView.layer.backgroundColor = _rightPageIndicatorView.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.259 green:0.259 blue:0.259 alpha:1].CGColor;
    
    _leftPageIndicatorView.layer.cornerRadius = _rightPageIndicatorView.layer.cornerRadius = 3;
    [self setupStatusIcon];
    [self updateWLSForCurrentState];
}

- (void)setupStatusIcon {
    _hearthstoneStatusImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 22, 22)];
    _hearthstoneStatusImageView.autoresizingMask = (NSViewMinYMargin);
    _hearthstoneStatusImageView.image = [NSImage imageNamed:@"status_bar_error_icon"];
    NSView *themeFrame = [[self.window contentView] superview];
    NSRect c = [themeFrame frame];
    NSRect aV = [_hearthstoneStatusImageView frame];
    NSRect newFrame = NSMakeRect(
                                 c.size.width - aV.size.width,
                                 c.size.height - aV.size.height,
                                 aV.size.width,
                                 aV.size.height);
    [_hearthstoneStatusImageView setFrame:newFrame];
    [themeFrame addSubview:_hearthstoneStatusImageView];
    
    
    __weak typeof(self) ws = self;
    [[Hearthstone defaultInstance] setStatusDidUpdate:^(BOOL isRunning) {
        if (isRunning) {
            ws.hearthstoneStatusImageView.image = [NSImage imageNamed:@"status_bar_icon"];
            [ws.hearthstoneStatusImageView setToolTip:@"Hearthstone is running"];
        }
        else {
            ws.hearthstoneStatusImageView.image = [NSImage imageNamed:@"status_bar_error_icon"];
            [ws.hearthstoneStatusImageView setToolTip:@"Hearthstone is not running"];
        }
    }];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MatchCellView *view = [MatchCellView new];
    view.match = _data[row];
    return view;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _data.count;
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 50;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    return NO;
}

- (void)windowWillClose:(NSNotification *)notification {
    NSWindow *window = notification.object;
    if ([_matchWindowControllers containsObject:window.windowController]) {
        [_matchWindowControllers removeObject:window.windowController];
    }
}

- (IBAction)wlButtonTap:(id)sender {
    _wlLifetimeState = !_wlLifetimeState;
    [self updateWLSForCurrentState];
}

- (void)updateWLSForCurrentState {
    if (_wlLifetimeState) {
        //_leftPageIndicatorView.alphaValue = 1.0;
        //_rightPageIndicatorView.alphaValue = 0.3;
        [[_leftPageIndicatorView animator] setAlphaValue:1.0];
        [[_rightPageIndicatorView animator] setAlphaValue:0.3];
        
        _wlTitleLabel.stringValue = @"Win - Loss Lifetime";
        int wins = [[DataMananger sharedManager] numberOfWinsLifetime];
        int losses = [[DataMananger sharedManager] numberOfLossesLifetime];
        int total = wins + losses;
        if (total == 0) {
            _wlPercentageLabel.stringValue = @"-";
        }
        else {
            float ratio = (float)wins/total;
            int percentage = round(ratio*100);
            _wlPercentageLabel.stringValue = [NSString stringWithFormat:@"%i%% Wins", percentage];
        }
        _wlFriendlyScoreLabel.stringValue = [NSString stringWithFormat:@"%i", wins];
        _wlOpponentScoreLabel.stringValue = [NSString stringWithFormat:@"%i", losses];
        
        
        _clearCurrentSessionButton.hidden = YES;
        _clearCurrentSessionButton.enabled = NO;
    }
    else {
        [[_leftPageIndicatorView animator] setAlphaValue:0.3];
        [[_rightPageIndicatorView animator] setAlphaValue:1.0];
        
        _wlTitleLabel.stringValue = @"Win - Loss Current Session";
        int wins = [[DataMananger sharedManager] numberOfWinsCurrentSession];
        int losses = [[DataMananger sharedManager] numberOfLossesCurrentSession];
        int total = wins + losses;
        if (total == 0) {
            _wlPercentageLabel.stringValue = @"-";
        }
        else {
            float ratio = (float) wins/total;
            int percentage = round(ratio*100);
            _wlPercentageLabel.stringValue = [NSString stringWithFormat:@"%i%% Wins", percentage];
        }
        _wlFriendlyScoreLabel.stringValue = [NSString stringWithFormat:@"%i", wins];
        _wlOpponentScoreLabel.stringValue = [NSString stringWithFormat:@"%i", losses];
        
        _clearCurrentSessionButton.hidden = NO;
        _clearCurrentSessionButton.enabled = YES;
    }
}

- (IBAction)didPressClearButton:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Yes, reset it"];
    [alert addButtonWithTitle:@"No, keep it"];
    [alert setMessageText:@"Are you sure you reset your current session?"];
    [alert setInformativeText:@"This action cannot be restored."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[DataMananger sharedManager] resetCurrentSession];
    }
}

@end
