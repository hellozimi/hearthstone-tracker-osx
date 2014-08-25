//
//  Hearthstone.m
//  hearth
//
//  Created by Simon Andersson on 05/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "Hearthstone.h"
#import "DataMananger.h"

#import "LogAnalyzer.h"
#import "LogObserver.h"
#import "Card.h"
#import "Match.h"

@interface Hearthstone ()
@property LogObserver *logObserver;
@property LogAnalyzer *logAnalyzer;
@end

@implementation Hearthstone

+ (instancetype)defaultInstance {
    static Hearthstone *INSTANCE = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        INSTANCE = [[[self class] alloc] init];
    });
    return INSTANCE;
}

+ (NSString *)configPath {
    /*
    [Zone]
    LogLevel=1
    FilePrinting=false
    ConsolePrinting=true
    ScreenPrinting=false
     */
    return [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/Blizzard/Hearthstone/log.config"];
}

+ (NSString *)logPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Logs/Unity/Player.log"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
        [self listener];
    }
    return self;
}

- (void)setup {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:[[self class] configPath]]) {
        NSMutableString *file = [NSMutableString new];
        [file appendString:@"[Zone]\n"];
        [file appendString:@"LogLevel=1\n"];
        [file appendString:@"FilePrinting=false\n"];
        [file appendString:@"ConsolePrinting=true\n"];
        [file appendString:@"ScreenPrinting=false\n"];
        
        NSString *dir = [[[self class] configPath] stringByDeletingLastPathComponent];
        
        [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        [file writeToFile:[[self class] configPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (void)listener {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceDidLaunchApplication:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceDidTerminateApplication:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    
    if ([self isHearthstoneRunning]) {
        [self startTracking];
    }
}

- (BOOL)isHearthstoneRunning {
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([[app localizedName] isEqualToString:@"Hearthstone"]) {
            return YES;
        }
    }
    return NO;
}

- (void)quit {
    if (_currentPlayingMatch.playing) {
        _currentPlayingMatch.playing = NO;
        _currentPlayingMatch.victory = NO;
        _currentPlayingMatch.conceded = YES;
        [_currentPlayingMatch endGame];
        [[DataMananger sharedManager] store];
    }
}

#pragma mark - Observer selectors for Hearthstone

- (void)workspaceDidLaunchApplication:(NSNotification *)notification {
    
    NSRunningApplication *application = [[notification userInfo] objectForKey:@"NSWorkspaceApplicationKey"] ?: nil;
    if (application) {
        NSString *applicationName = [application localizedName];
        if ([applicationName isEqualToString:@"Hearthstone"]) {
            [self startTracking];
            
            _statusDidUpdate(YES);
        }
    }
}

- (void)workspaceDidTerminateApplication:(NSNotification *)notification {
    
    NSRunningApplication *application = [[notification userInfo] objectForKey:@"NSWorkspaceApplicationKey"] ?: nil;
    if (application) {
        NSString *applicationName = [application localizedName];
        if ([applicationName isEqualToString:@"Hearthstone"]) {
            [self stopTracking];
            
            if (_currentPlayingMatch) {
                _currentPlayingMatch.conceded = YES;
                _currentPlayingMatch.victory = NO;
                [_currentPlayingMatch endGame];
                [[DataMananger sharedManager] store];
                _currentPlayingMatch = nil;
            }
            
            if (_statusDidUpdate) {
                _statusDidUpdate(NO);
            }
        }
    }
}

- (void)startTracking {
    __weak typeof(self) ws = self;
    _logObserver = [LogObserver new];
    _logAnalyzer = [LogAnalyzer new];
    
    [_logAnalyzer setPlayerHero:^(Player player, NSString *heroId) {
        
        if (ws.currentPlayingMatch && ws.currentPlayingMatch.friendlyHeroId && ws.currentPlayingMatch.opponentHeroId && ws.currentPlayingMatch.playing) { // Already playing a game and starting a new one
            ws.currentPlayingMatch.conceded = YES;
            ws.currentPlayingMatch.victory = NO;
            ws.currentPlayingMatch.playing = NO;
            [ws.currentPlayingMatch endGame];
            [[DataMananger sharedManager] store];
            
            // Reset current match
            ws.currentPlayingMatch = [Match new];
            ws.currentPlayingMatch.playing = YES;
            [[DataMananger sharedManager] addMatch:ws.currentPlayingMatch];
        }
        else if (!ws.currentPlayingMatch) { // new game
            ws.currentPlayingMatch = [Match new];
            ws.currentPlayingMatch.playing = YES;
            [[DataMananger sharedManager] addMatch:ws.currentPlayingMatch];
        }
        
        if (player == PlayerMe) {
            NSLog(@"----- Game Started -----");
            ws.currentPlayingMatch.friendlyHeroId = heroId;
        }
        else {
            ws.currentPlayingMatch.opponentHeroId = heroId;
        }
        
        [ws.currentPlayingMatch fetch];
        
        [[DataMananger sharedManager] store];
        NSLog(@"Player %u picked %@", player, heroId);
    }];
    
    [_logAnalyzer setPlayerDidPlayCard:^(Player player, NSString *cardId) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %u played card %@", player, cardId);
        
        Card *card = [Card new];
        card.cardId = cardId;
        card.player = player;
        
        [ws.currentPlayingMatch.cardHistory addObject:card];
        
        [ws.currentPlayingMatch fetch];
        [[DataMananger sharedManager] store];
    }];
    
    [_logAnalyzer setPlayerDidReturnCard:^(Player player, NSString *cardId) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %u return %@", player, cardId);
        Card *lastPlayedCard = [ws.currentPlayingMatch.cardHistory lastObject];
        if (lastPlayedCard != nil && lastPlayedCard.player == player && [lastPlayedCard.cardId isEqualToString:cardId]) {
            [ws.currentPlayingMatch.cardHistory removeLastObject];
        }
        
        [ws.currentPlayingMatch fetch];
        [[DataMananger sharedManager] store];
    }];
    
    [_logAnalyzer setPlayerGotCoin:^(Player player) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %u got the coin", player);
        ws.currentPlayingMatch.friendlyHeroHasCoin = (player == PlayerMe);
        
        [ws.currentPlayingMatch fetch];
        [[DataMananger sharedManager] store];
    }];
    
    [_logAnalyzer setPlayerDidDie:^(Player player) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %u died", player);
        ws.currentPlayingMatch.victory = (player != PlayerMe);
        [ws.currentPlayingMatch endGame];
        ws.currentPlayingMatch.playing = NO;
        [[DataMananger sharedManager] store];
        [ws.currentPlayingMatch fetch];
        //[[DataMananger sharedManager] addMatch:ws.currentPlayingMatch];
        ws.currentPlayingMatch = nil;
        
    }];
    
    _logObserver.didReadLine = ^(NSString *line) {
        [ws.logAnalyzer analyzeLine:line];
    };
    
    [_logObserver start];
}

- (void)stopTracking {
    [_logObserver stop];
    _logObserver = nil;
    _logAnalyzer = nil;
}

- (void)setStatusDidUpdate:(void (^)(BOOL isRunning))statusDidUpdate {
    _statusDidUpdate = statusDidUpdate;
    
    _statusDidUpdate([self isHearthstoneRunning]);
}

@end
