//
//  NSDictionary+Null.h
//  redbull-ss-ios
//
//  Created by Simon Andersson on 12/21/12.
//  Copyright (c) 2012 Monterosa. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Null)

/**
 *  Null check key in dictionary
 *
 *  @param key the key of the wanted object
 *
 *  @return object or nil
 */
- (id)nullCheckedObjectForKey:(id)key;

@end