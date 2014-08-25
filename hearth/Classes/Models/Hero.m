//
//  Hero.m
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "Hero.h"
#import "NSDictionary+Null.h"
#import "DataMananger.h"

@interface Hero ()
+ (NSDictionary *)heroDataFromId:(NSString *)heroId;
@end

@implementation Hero

+ (NSDictionary *)heroDataFromId:(NSString *)heroId {
    NSString *query = [NSString stringWithFormat:@"SELECT * FROM `cards` WHERE `card_id` = '%@' AND `type` = 'Hero' LIMIT 1", heroId];
    NSArray *data = [[DataMananger sharedManager] performQuery:query];
    
    if (data.count == 0) {
        return nil;
    }
    
    return [data firstObject];
}

+ (instancetype)heroWithId:(NSString *)heroId {
    NSDictionary *data = [self heroDataFromId:heroId];
    Hero *hero = [[Hero alloc] initWithDictionary:data];
    
    return hero;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _name = [dict nullCheckedObjectForKey:@"name"];
        _className = [dict nullCheckedObjectForKey:@"playerClass"];
        if ([[dict nullCheckedObjectForKey:@"card_id"] rangeOfString:@"NAX"].location != NSNotFound) {
            NSString *heroName = [[_name componentsSeparatedByString:@" "] firstObject];
            _className = heroName;
        }
        _color = [self colorForPlayerClass:_className];
    }
    return self;
}

- (NSColor *)colorForPlayerClass:(NSString *)playerClass {
    if ([playerClass isEqualToString:@"Rogue"]) {
        return [NSColor colorWithCalibratedRed:0.933 green:0.894 blue:0.408 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Warrior"]) {
        return [NSColor colorWithCalibratedRed:0.780 green:0.612 blue:0.431 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Shaman"]) {
        return [NSColor colorWithCalibratedRed:0.133 green:0.337 blue:0.969 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Paladin"]) {
        return [NSColor colorWithCalibratedRed:0.961 green:0.549 blue:0.729 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Hunter"]) {
        return [NSColor colorWithCalibratedRed:0.671 green:0.831 blue:0.451 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Druid"]) {
        return [NSColor colorWithCalibratedRed:1.000 green:0.490 blue:0.039 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Warlock"]) {
        return [NSColor colorWithCalibratedRed:0.580 green:0.510 blue:0.792 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Mage"]) {
        return [NSColor colorWithCalibratedRed:0.388 green:0.871 blue:0.933 alpha:1];
    }
    else if ([playerClass isEqualToString:@"Priest"]) {
        return [NSColor colorWithCalibratedRed:0.95 green:0.95 blue:0.95 alpha:1];
    }
    
    if ([_className rangeOfString:@"NAX"].location != NSNotFound) {
        return [NSColor colorWithCalibratedRed:0.435 green:0.627 blue:0.216 alpha:1];
    }
    
    return nil;
}

@end
