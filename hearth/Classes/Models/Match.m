//
//  Match.m
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "Match.h"
#import "Hero.h"
#import "Card.h"

@implementation Match

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.startDate = [NSDate date];
        self.cardHistory = [NSMutableArray new];
    }
    return self;
}

- (void)fetch {
    self.friendlyHero = [Hero heroWithId:_friendlyHeroId];
    self.opponentHero = [Hero heroWithId:_opponentHeroId];
    
    for (Card *card in self.friendlyCards) {
        [card fetch];
    }
    
    for (Card *card in self.opponentCards) {
        [card fetch];
    }
}

- (void)endGame {
    self.endDate = [NSDate date];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        
        _victory = [[coder decodeObjectForKey:@"victory"] boolValue];
        _conceded = [[coder decodeObjectForKey:@"conceded"] boolValue];
        
        _startDate = [coder decodeObjectForKey:@"startDate"];
        _endDate = [coder decodeObjectForKey:@"endDate"];
        
        _friendlyHeroHasCoin = [[coder decodeObjectForKey:@"friendlyHeroHasCoin"] boolValue];
        
        _friendlyHeroId = [coder decodeObjectForKey:@"friendlyHeroId"];
        _opponentHeroId = [coder decodeObjectForKey:@"opponentHeroId"];
        
        _cardHistory = [coder decodeObjectForKey:@"cardHistory"];
    }
    return self;
}

- (void)setFriendlyHeroId:(NSString *)friendlyHeroId {
    _friendlyHeroId = [friendlyHeroId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)setOpponentHeroId:(NSString *)opponentHeroId {
    _opponentHeroId = [opponentHeroId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSArray *)friendlyCards {
    return [_cardHistory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"player = 0"]];
}

- (NSArray *)opponentCards {
    return [_cardHistory filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"player = 1"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(_victory) forKey:@"victory"];
    [aCoder encodeObject:@(_conceded) forKey:@"conceded"];
    [aCoder encodeObject:@(_friendlyHeroHasCoin) forKey:@"friendlyHeroHasCoin"];
    [aCoder encodeObject:_startDate forKey:@"startDate"];
    [aCoder encodeObject:_endDate forKey:@"endDate"];
    [aCoder encodeObject:_friendlyHeroId forKey:@"friendlyHeroId"];
    [aCoder encodeObject:_opponentHeroId forKey:@"opponentHeroId"];
    [aCoder encodeObject:_cardHistory forKey:@"cardHistory"];
}

@end
