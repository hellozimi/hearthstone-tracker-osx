//
//  DataMananger.h
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Match;

@interface DataMananger : NSObject

@property NSMutableArray *matches;
@property (nonatomic, copy) void(^dataUpdateBlock)(void);

@property (nonatomic, readonly) int numberOfWinsCurrentSession;
@property (nonatomic, readonly) int numberOfLossesCurrentSession;

@property (nonatomic, readonly) int numberOfWinsLifetime;
@property (nonatomic, readonly) int numberOfLossesLifetime;

@property (nonatomic, strong, readonly) NSDate *currentSessionDate;

+ (instancetype)sharedManager;

- (void)addMatch:(Match *)match;
- (void)removeMatch:(Match *)match;

- (NSArray *)performQuery:(NSString *)query;
- (void)performQuery:(NSString *)query callback:(void(^)(NSArray *data))block;

- (void)fetch;
- (void)store;
- (void)resetCurrentSession;

@end
