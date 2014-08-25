//
//  Card.m
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "Card.h"
#import "NSDictionary+Null.h"
#import "DataMananger.h"

@implementation Card

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.playedAt = [NSDate date];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        _playedAt = [coder decodeObjectForKey:@"playedAt"];
        _cardId = [coder decodeObjectForKey:@"cardId"];
        _player = [[coder decodeObjectForKey:@"player"] integerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_playedAt forKey:@"playedAt"];
    [aCoder encodeObject:_cardId forKey:@"cardId"];
    [aCoder encodeObject:@(_player) forKey:@"player"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%p> { cardId: %@, player: %ld }", self, _cardId, _player];
}

- (NSUInteger)hash {
    return [[NSString stringWithFormat:@"%f.%@.%ld", [_playedAt timeIntervalSince1970], _cardId, _player] hash];
}

- (BOOL)isEqualTo:(id)object {
    return [object isKindOfClass:[Card class]] ? [[object cardId] isEqualToString:self.cardId] : NO;
}

- (void)fetch {
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM `cards` WHERE `card_id` = '%@' LIMIT 1", _cardId];
    NSDictionary *data = [[[DataMananger sharedManager] performQuery:query] firstObject];
    
//    NSLog(@"Data: %@", data);
    _name = [data nullCheckedObjectForKey:@"name"];
    _cost = [data nullCheckedObjectForKey:@"cost"];
    _type = [data nullCheckedObjectForKey:@"type"];
    _rarity = [data nullCheckedObjectForKey:@"rarity"];
    _faction = [data nullCheckedObjectForKey:@"faction"];
    _text = [data nullCheckedObjectForKey:@"text"];
    _flavor = [data nullCheckedObjectForKey:@"flavor"];
    _artist = [data nullCheckedObjectForKey:@"artist"];
    _playerClass = [data nullCheckedObjectForKey:@"playerClass"];
    _attack = [data nullCheckedObjectForKey:@"attack"];
    _health = [data nullCheckedObjectForKey:@"health"];
    _collectible = [data nullCheckedObjectForKey:@"collectible"];
    _elite = [data nullCheckedObjectForKey:@"elite"];
}

@end
