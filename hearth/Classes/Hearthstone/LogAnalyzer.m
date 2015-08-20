//
//  LogAnalyzer.m
//  hearth
//
//  Created by Simon Andersson on 05/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "LogAnalyzer.h"

@interface NSRegularExpression (StringAtIndex)
- (NSString *)matchWithString:(NSString *)string atIndex:(int)idx;
@end

@implementation NSRegularExpression (StringAtIndex)

- (NSString *)matchWithString:(NSString *)string atIndex:(int)idx {
    NSArray *matches = [self matchesInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, string.length)];
    for (NSTextCheckingResult *match in matches) {
        if (match.numberOfRanges-1 < idx) {
            return nil;
        }
        
        NSRange matchRange = [match rangeAtIndex:idx];
        NSString *matchString = [string substringWithRange:matchRange];
        return matchString;
    }
    
    return nil;
}

@end

@interface NSString (Contains)
- (BOOL)contains:(NSString *)search;
@end

@implementation NSString (Contains)

- (BOOL)contains:(NSString *)search {
    return [self rangeOfString:search].location != NSNotFound;
}

@end

@implementation LogAnalyzer

- (void)analyzeLine:(NSString *)line {
    if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        return;
    }
    
    static NSString *pattern = @"ProcessChanges.*cardId=(\\w+).*zone from (.*) -> (.*)";
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    if ([regexp numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)] != 0) {
        
        NSString *cardId = [regexp matchWithString:line atIndex:1];
        NSString *from = [regexp matchWithString:line atIndex:2];
        NSString *to = [regexp matchWithString:line atIndex:3];
        
        BOOL draw = [from contains:@"DECK"] && [to contains:@"HAND"];
        BOOL mulligan = [from contains:@"HAND"] && [to contains:@"DECK"];
        BOOL discard = [from contains:@"HAND"] && [to contains:@"GRAVEYARD"];
        
        if(!draw && !mulligan && !discard) {
            if([from contains:@"FRIENDLY HAND"]) {
                _playerDidPlayCard(PlayerMe, cardId);
            } else if([from contains:@"OPPOSING HAND"]) {
                _playerDidPlayCard(PlayerOpponent, cardId);
            }
        }
        
        if([from contains:@"FRIENDLY PLAY"] && [to contains:@"FRIENDLY HAND"]) {
            _playerDidReturnCard(PlayerMe, cardId);
        }
        
        // Player died? (unfortunately there is no log entry when conceding)
        if([to contains:@"GRAVEYARD"] && [from contains:@"PLAY (Hero)"]) {
            if([to contains:@"FRIENDLY"]) {
                _playerDidDie(PlayerMe);
            }
            else if([to contains:@"OPPOSING"]) {
                _playerDidDie(PlayerOpponent);
            }
        }
        
        //NSLog(@"Card %s from %s -> %s. (draw: %d, mulligan %d, discard %d)", cardID.UTF8String, from.UTF8String, to.UTF8String, draw, mulligan, discard);
    }
	[self analyzeForPlayerName:line];
    [self analyzeForCoin:line];
    [self analyzeForHero:line];
	[self analyzeForWin:line];
}

- (void)analyzeForPlayerName:(NSString *)line {
	static NSString *pattern = @"GameState.DebugPrintPower\\(\\) - TAG_CHANGE Entity=(.*) tag=PLAYER_ID value=(.*)";
	NSError *error = nil;
	NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
	if (error) {
		NSLog(@"%@", [error localizedDescription]);
		return;
	}
	
	if ([regexp numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)] != 0) {
		//NSLog(@"%@", line);
		NSString *playerName = [regexp matchWithString:line atIndex:1];
		SInt32 playerID = (SInt32)[[regexp matchWithString:line atIndex:2] integerValue];
		NSAssert(playerID == 1 || playerID == 2, @"Invalid playerID");
		_playerName(playerID, playerName);
	}
}

- (void)analyzeForCoin:(NSString *)line {
    static NSString *pattern = @"ProcessChanges.*zonePos=5.*zone from  -> (.*)";
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    if ([regexp numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)] != 0) {
        NSString *to = [regexp matchWithString:line atIndex:1];
        if([to contains:@"FRIENDLY HAND"]) {
            _playerGotCoin(PlayerMe);
        } else if([to contains:@"OPPOSING HAND"]) {
            _playerGotCoin(PlayerOpponent);
        }
    }
}

- (void)analyzeForHero:(NSString *)line {
    static NSString *pattern = @"ProcessChanges.*TRANSITIONING card \\[name=(.*).*zone=PLAY.*cardId=(.*).*player=(\\d)\\] to (.*) \\(Hero\\)";
    NSError *error = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    if ([regexp numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)] != 0) {
        //NSLog(@"%@", line);
        //NSString *name = [regexp matchWithString:line atIndex:1];
        NSString *cardId = [regexp matchWithString:line atIndex:2];
        SInt32 playerID = (SInt32)[[regexp matchWithString:line atIndex:3] integerValue];
		NSAssert(playerID == 1 || playerID == 2, @"playerID invalid");
        NSString *to   = [regexp matchWithString:line atIndex:4];
        
        if([to isEqualToString:@"FRIENDLY PLAY"]) {
            _playerHero(PlayerMe, cardId, playerID);
        }
        else {
            _playerHero(PlayerOpponent, cardId, playerID);
        }
    }
}

- (void)analyzeForWin:(NSString *)line {
	static NSString *pattern = @"TAG_CHANGE Entity=(.*) tag=PLAYSTATE value=(.*)";
	NSError *error = nil;
	NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
	if (error) {
		NSLog(@"%@", [error localizedDescription]);
		return;
	}
	
	if ([regexp numberOfMatchesInString:line options:0 range:NSMakeRange(0, line.length)] != 0) {
		NSString *playerName = [regexp matchWithString:line atIndex:1];
		NSString *value   = [regexp matchWithString:line atIndex:2];
		
		if ([value isEqualToString:@"WON"]) {
			_playerWon(playerName);
		}
	}
}

@end
