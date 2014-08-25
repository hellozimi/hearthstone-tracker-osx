//
//  NSDictionary+Null.m
//  redbull-ss-ios
//
//  Created by Simon Andersson on 12/21/12.
//  Copyright (c) 2012 Monterosa. All rights reserved.
//

#import "NSDictionary+Null.h"

@implementation NSDictionary (Null)

- (id)nullCheckedObjectForKey:(id)key {
    id object = [self objectForKey:key];
    if ([object isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    return object;
}

@end
