//
//  HCTableView.h
//  hearth
//
//  Created by Simon Andersson on 07/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HCTableView : NSTableView

@property (nonatomic, copy) void(^didClickRow)(NSInteger row);

@end
