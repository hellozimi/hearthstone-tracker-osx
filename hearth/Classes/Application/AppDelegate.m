//
//  AppDelegate.m
//  hearth
//
//  Created by Simon Andersson on 05/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "AppDelegate.h"
#import "Hearthstone.h"
#import "DataMananger.h"

#import "WindowController.h"
@interface AppDelegate ()

@property WindowController *windowController;
@property NSStatusItem *statusItem;
@property NSMenu *statusMenu;
@end

@implementation AppDelegate
            
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [DataMananger sharedManager];
    [[DataMananger sharedManager] fetch];
    [Hearthstone defaultInstance];
    _windowController = [[WindowController alloc] initWithWindowNibName:@"MainWindow"];
    [_windowController showWindow:self];
    
    /*** Set up statusbar icon + menu */
    _statusMenu = [[NSMenu alloc] initWithTitle:@"Status"];
    [_statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Open" action:@selector(openMainWindow:) keyEquivalent:@""]];
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    [_statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Settings" action:@selector(openSettings:) keyEquivalent:@""]];
    [_statusMenu addItem:[NSMenuItem separatorItem]];
    [_statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""]];
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    _statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setImage:[NSImage imageNamed:@"status_bar_icon"]];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:_statusMenu];
    
    /*
    NSArray *ar = [[DataMananger sharedManager] performQuery:@"SELECT * FROM `cards`"];
    __block NSString *str = nil;;
    __block int len = 0;
    
    [ar enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        NSString *name = [obj objectForKey:@"name"];
        if (name && name.length > len && ([obj[@"type"] isEqualToString:@"Minion"] || [obj[@"type"] isEqualToString:@"Spell"])) {
            str = name;
            len = (int)name.length;
        }
    }];
    
    NSLog(@"%@ %i", str, len);
     */
}

- (void)openSettings:(id)sender {
    
}

- (void)openMainWindow:(id)sender {
    [_windowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [[Hearthstone defaultInstance] quit];
}


@end
