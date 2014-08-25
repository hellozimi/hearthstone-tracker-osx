//
//  Card.h
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Card : NSObject <NSCoding>

- (void)fetch;

@property (nonatomic, assign) NSInteger player;
@property (nonatomic, strong) NSString *cardId;
@property (nonatomic, strong) NSDate *playedAt;

@property NSString *name;
@property NSNumber *cost;
@property NSString *type;
@property NSString *rarity;
@property NSString *faction;
@property NSString *text;
@property NSString *flavor;
@property NSString *artist;
@property NSString *playerClass;
@property NSNumber *attack;
@property NSNumber *health;
@property NSNumber *collectible;
@property NSNumber *elite;

@end
