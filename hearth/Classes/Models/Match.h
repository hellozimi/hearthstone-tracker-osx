//
//  Match.h
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Hero;

@interface Match : NSObject <NSCoding>

@property BOOL victory;
@property BOOL conceded;
@property BOOL playing;

@property NSDate *startDate;
@property NSDate *endDate;

@property BOOL friendlyHeroHasCoin;

@property (nonatomic) NSString *friendlyHeroId;
@property (nonatomic) NSString *opponentHeroId;

@property NSMutableArray *cardHistory;

@property Hero *friendlyHero;
@property Hero *opponentHero;

@property (nonatomic, readonly) NSArray *friendlyCards;
@property (nonatomic, readonly) NSArray *opponentCards;

- (void)endGame;
- (void)fetch;

@end
