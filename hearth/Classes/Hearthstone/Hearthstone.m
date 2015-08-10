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
#import "Hero.h"

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
		
		[file appendString:@"[Power]\n"];
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

- (NSString*) getMeOrOpponent_ID:(SInt32)playerID {
	__weak typeof(self) ws = self;
	return (playerID == ws.currentPlayingMatch.friendlyPlayerID) ? @"Me" : @"Opponent";
}

- (NSString*) getMeOrOpponent_Enum:(Player)player {
	return (player == PlayerMe) ? @"Me" : @"Opponent";
}

- (void) createCurrentPlayingMatchIfNeeded {
	__weak typeof(self) ws = self;
	if (ws.currentPlayingMatch && ws.currentPlayingMatch.friendlyHeroId && ws.currentPlayingMatch.opponentHeroId && ws.currentPlayingMatch.playing) { // Already playing a game and starting a new one
		ws.currentPlayingMatch.conceded = YES;
		ws.currentPlayingMatch.victory = NO;
		ws.currentPlayingMatch.playing = NO;
		[ws.currentPlayingMatch endGame];
		[[DataMananger sharedManager] store];
		
		// Reset current match
		NSLog(@"----- Game Started (after unfinished one) -----");
		ws.currentPlayingMatch = [Match new];
		ws.currentPlayingMatch.playing = YES;
		[[DataMananger sharedManager] addMatch:ws.currentPlayingMatch];
	}
	else if (!ws.currentPlayingMatch) { // new game
		NSLog(@"----- Game Started -----");
		ws.currentPlayingMatch = [Match new];
		ws.currentPlayingMatch.playing = YES;
		[[DataMananger sharedManager] addMatch:ws.currentPlayingMatch];
	}
}

- (void) assignMeOrOppPlayerName:(NSString*)playerName ForPlayerID:(SInt32)playerID {
	NSCAssert(playerName != nil && (playerID == 1 || playerID == 2), @"Invalid parameters");
	__weak typeof(self) ws = self;
	if (ws.currentPlayingMatch.friendlyPlayerID == playerID) {
		NSCAssert(ws.currentPlayingMatch.friendlyPlayerName == nil, @"Friendly player already has a name");
		NSLog(@"Player Me (ID %d) name is %@", playerID, playerName);
		ws.currentPlayingMatch.friendlyPlayerName = playerName;
	}
	else {
		NSCAssert(ws.currentPlayingMatch.opponentPlayerName == nil, @"Opponent player already has a name");
		NSCAssert(ws.currentPlayingMatch.friendlyPlayerID == (playerID == 1) ? 2 : 1, @"FriendlyPlayerID not coherent");
		NSLog(@"Player Opponent (ID %d) name is %@", playerID, playerName);
		ws.currentPlayingMatch.opponentPlayerName = playerName;
	}
}

- (void)startTracking {
    __weak typeof(self) ws = self;
    _logObserver = [LogObserver new];
    _logAnalyzer = [LogAnalyzer new];
	
    [_logAnalyzer setPlayerHero:^(Player player, NSString *heroId, SInt32 playerID) {
		
		NSCAssert(playerID == 1 || playerID == 2, @"Invalid playerID");
		
		[ws createCurrentPlayingMatchIfNeeded];
		
        if (player == PlayerMe) {
            ws.currentPlayingMatch.friendlyHeroId = heroId;
			if (ws.currentPlayingMatch.friendlyPlayerID == -1) {
				NSCAssert(ws.currentPlayingMatch.opponentPlayerID == -1, @"We should always assign both playerID at the same time");
				ws.currentPlayingMatch.friendlyPlayerID = playerID;
				ws.currentPlayingMatch.opponentPlayerID = (playerID == 1) ? 2 : 1;
			}
        }
        else {
            ws.currentPlayingMatch.opponentHeroId = heroId;
			if (ws.currentPlayingMatch.opponentPlayerID == -1) {
				NSCAssert(ws.currentPlayingMatch.friendlyPlayerID == -1, @"We should always assign both playerID at the same time");
				ws.currentPlayingMatch.opponentPlayerID = playerID;
				ws.currentPlayingMatch.friendlyPlayerID = (playerID == 1) ? 2 : 1;
			}
        }
		
		for (UInt32 playerID = 1; playerID <= 2; playerID++) {
			NSString *playerName = (playerID == 1) ? ws.currentPlayingMatch.player1Name : ws.currentPlayingMatch.player2Name;
			
			if (playerName != nil) {
				
				[ws assignMeOrOppPlayerName:playerName ForPlayerID:playerID];
				
				if (playerID == 1) {
					ws.currentPlayingMatch.player1Name = nil;
				} else {
					ws.currentPlayingMatch.player2Name = nil;
				}
			}
		}
		
        [ws.currentPlayingMatch fetch];
        
        [[DataMananger sharedManager] store];
		NSLog(@"Player %@ picked %@", [ws getMeOrOpponent_ID:playerID], heroId);
    }];
	
	[_logAnalyzer setPlayerName:^(SInt32 playerID, NSString *playerName) {
		
		[ws createCurrentPlayingMatchIfNeeded];
		
		if (ws.currentPlayingMatch.friendlyPlayerID == -1) {
			NSCAssert(ws.currentPlayingMatch.opponentPlayerID == -1, @"We should always assign both playerID at the same time");
			
			if (playerID == 1) {
				ws.currentPlayingMatch.player1Name = playerName;
			}
			else {
				NSCAssert(playerID == 2, @"Invalid playerID");
				ws.currentPlayingMatch.player2Name = playerName;
			}
		}
		else {
			
			[ws assignMeOrOppPlayerName:playerName ForPlayerID:playerID];
		}
	}];
    
    [_logAnalyzer setPlayerDidPlayCard:^(Player player, NSString *cardId) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %@ played card %@", [ws getMeOrOpponent_Enum:player], cardId);
        
        Card *card = [Card new];
        card.cardId = cardId;
        card.player = player;
        
        [ws.currentPlayingMatch.cardHistory addObject:card];
        
        [ws.currentPlayingMatch fetch];
        [[DataMananger sharedManager] store];
    }];
    
    [_logAnalyzer setPlayerDidReturnCard:^(Player player, NSString *cardId) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %@ return %@", [ws getMeOrOpponent_Enum:player], cardId);
        Card *lastPlayedCard = [ws.currentPlayingMatch.cardHistory lastObject];
        if (lastPlayedCard != nil && lastPlayedCard.player == player && [lastPlayedCard.cardId isEqualToString:cardId]) {
            [ws.currentPlayingMatch.cardHistory removeLastObject];
        }
        
        [ws.currentPlayingMatch fetch];
        [[DataMananger sharedManager] store];
    }];
    
    [_logAnalyzer setPlayerGotCoin:^(Player player) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %@ got the coin", [ws getMeOrOpponent_Enum:player]);
        ws.currentPlayingMatch.friendlyHeroHasCoin = (player == PlayerMe);
        
        [ws.currentPlayingMatch fetch];
        [[DataMananger sharedManager] store];
    }];
    
    [_logAnalyzer setPlayerDidDie:^(Player player) {
        if (!ws.currentPlayingMatch) { return; }
        NSLog(@"Player %@ died", [ws getMeOrOpponent_Enum:player]);
        ws.currentPlayingMatch.victory = (player != PlayerMe);
        [ws.currentPlayingMatch endGame];
        ws.currentPlayingMatch.playing = NO;
        [[DataMananger sharedManager] store];
        [ws.currentPlayingMatch fetch];
        //[[DataMananger sharedManager] addMatch:ws.currentPlayingMatch];
        ws.currentPlayingMatch = nil;
        
    }];
	
	[_logAnalyzer setPlayerWon:^(NSString *playerName) {
		if (!ws.currentPlayingMatch) { return; }
		BOOL playerMeWon = [playerName isEqualToString:ws.currentPlayingMatch.friendlyPlayerName];
		NSLog(@"%@", playerMeWon ? @"Player Me won" : @"Player Opponent won");
		ws.currentPlayingMatch.victory = playerMeWon;
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
