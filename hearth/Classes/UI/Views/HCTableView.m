//
//  HCTableView.m
//  hearth
//
//  Created by Simon Andersson on 07/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "HCTableView.h"

@implementation HCTableView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setAction:@selector(doClick:)];
    [self setTarget:self];
}

- (void)doClick:(id)sender {
    NSInteger row = [self clickedRow];
    if (row >= 0 && _didClickRow) {
        _didClickRow(row);
    }
}

@end
