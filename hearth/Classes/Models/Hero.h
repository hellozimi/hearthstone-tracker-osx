//
//  Hero.h
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Hero : NSObject

+ (instancetype)heroWithId:(NSString *)heroId;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *className;
@property (nonatomic, strong, readonly) NSColor *color;

@end
