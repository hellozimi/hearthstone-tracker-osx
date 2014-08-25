//
//  DataMananger.m
//  hearth
//
//  Created by Simon Andersson on 06/08/14.
//  Copyright (c) 2014 hiddencode.me. All rights reserved.
//

#import "DataMananger.h"
#import "NSDictionary+Null.h"
#import "EGOCache.h"
#import "Match.h"

#import <sqlite3.h>

static NSString * kDataManagerMatchesArray = @"kDataManagerMatchesArray";
NSString * const kDataManagerDidRecieveNewGame = @"kDataManagerDidRecieveNewGame";

@interface DataMananger ()
@property sqlite3 *db;
@end

@implementation DataMananger

+ (instancetype)sharedManager {
    static DataMananger *INSTANCE = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        INSTANCE = [[[self class] alloc] init];
    });
    return INSTANCE;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        //[[EGOCache globalCache] removeCacheForKey:kDataManagerMatchesArray];
        
        
        _matches = (id)[[EGOCache globalCache] objectForKey:kDataManagerMatchesArray];
        
        if (!_matches) {
            _matches = [NSMutableArray new];
        }
        else {
            [self sortMatches];
        };
        
        [self setup];
        [self importData];
        [self resetCurrentSession];
    }
    return self;
}

- (void)fetch {
    for (Match *match in _matches) {
        [match fetch];
    }
}

- (void)addMatch:(Match *)match {
    if ([match.opponentHeroId rangeOfString:@"HERO"].location != NSNotFound && [match.friendlyHeroId rangeOfString:@"HERO"].location != NSNotFound) {
        [match fetch];
        [_matches addObject:match];
        [self sortMatches];
        [self store];
    }
    else { // Naxx and other
        //NSLog(@"Dont log this match");
    }
}


- (void)removeMatch:(Match *)match {
    if ([_matches containsObject:match]) {
        [_matches removeObject:match];
        
        [self sortMatches];
        [self store];
        
        if (_dataUpdateBlock) {
            _dataUpdateBlock();
        }
    }
}

- (void)sortMatches {
    [_matches sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO]]];
}

- (void)store {
    [[EGOCache globalCache] setAsyncObject:_matches forKey:kDataManagerMatchesArray complete:^{
        //NSLog(@"Stored");
    }];
    
    if (_dataUpdateBlock) {
        _dataUpdateBlock();
    }
}

#pragma mark - DB Setups

- (NSString *)storePath {
    NSString *applicationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *storePath = [applicationSupport stringByAppendingPathComponent:@"/me.hiddencode.hearth"];
    
    return storePath;
}

- (NSString *)databasePath {
    NSString *databaseFileName = @"hearth_db.sqlite";
    NSString *path = [[self storePath] stringByAppendingPathComponent:databaseFileName];
    return path;
}

#pragma mark - Setup

- (void)setup {
    
    NSString *storePath = [self storePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSError *error = nil;
    
    //[fm removeItemAtPath:storePath error:nil]; // TO CLEAR DATABASE
    
    if (![fm fileExistsAtPath:storePath]) {
        [fm createDirectoryAtPath:storePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
        }
    }
    
    NSString *path = [self databasePath];
    sqlite3 *connection = nil;
    if (sqlite3_open([path UTF8String], &connection) != SQLITE_OK) {
        NSLog(@"Error");
        return;
    }
    _db = connection;
}

#pragma mark - Reset current settings

- (void)resetCurrentSession {
    _currentSessionDate = [NSDate date];
    
    if (_dataUpdateBlock) {
        _dataUpdateBlock();
    }
}

#pragma mark - Getters

- (int)numberOfLossesCurrentSession {
    return (int)[[_matches filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(victory = 0) AND (conceded = 0) AND (startDate > %@) AND (playing = 0)", _currentSessionDate]] count];
}

- (int)numberOfWinsCurrentSession {
    return (int)[[_matches filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(victory = 1) AND (conceded = 0) AND (startDate > %@) AND (playing = 0)", _currentSessionDate]] count];
}

- (int)numberOfLossesLifetime {
    return (int)[[_matches filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(victory = 0) AND (conceded = 0) AND (playing = 0)"]] count];
}

- (int)numberOfWinsLifetime {
    return (int)[[_matches filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(victory = 1) AND (conceded = 0) AND (playing = 0)"]] count];
}

#pragma mark - Import data functions

- (BOOL)cardsTableExists {
    NSArray *data = [self performQuery:@"SELECT name FROM sqlite_master WHERE type='table' AND name='cards'"];
    return data.count >= 1;
}

- (void)importData {
    
    if ([self cardsTableExists]) { // Only import once
        return;
    }
    
    NSString *dataFilePath = [[NSBundle mainBundle] pathForResource:@"AllSets" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:dataFilePath];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    const char *sql_stmt =
    "CREATE TABLE IF NOT EXISTS `cards` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `name` TEXT, `card_id` TEXT, `cost` INTEGER, `type` TEXT, `rarity` TEXT, `faction` TEXT, `text` TEXT, `flavor` TEXT, `artist` TEXT, `playerClass` TEXT, attack INTEGER, `health` INTEGER, `collectible` INTEGER, `elite` INTEGER)";
    
    char *errMsg;
    
    if (sqlite3_exec(_db, sql_stmt, NULL, NULL, &errMsg) == SQLITE_OK) {
        for (NSString *key in json) {
            for (id obj in json[key]) {
                NSString *name = [obj nullCheckedObjectForKey:@"name"];
                NSString *cardId = [obj nullCheckedObjectForKey:@"id"];
                NSNumber *cost = [obj nullCheckedObjectForKey:@"cost"] ?: @0;
                NSString *type = [obj nullCheckedObjectForKey:@"type"];
                NSString *rarity = [obj nullCheckedObjectForKey:@"rarity"];
                NSString *faction = [obj nullCheckedObjectForKey:@"faction"];
                NSString *text = [obj nullCheckedObjectForKey:@"text"];
                NSString *flavor = [obj nullCheckedObjectForKey:@"flavor"];
                NSString *artist = [obj nullCheckedObjectForKey:@"artist"];
                NSString *playerClass = [obj nullCheckedObjectForKey:@"playerClass"];
                NSNumber *attack = [obj nullCheckedObjectForKey:@"attack"] ?: @0;
                NSNumber *health = [obj nullCheckedObjectForKey:@"health"] ?: @0;
                NSNumber *collectible = [obj nullCheckedObjectForKey:@"collectible"] ?: @0;
                NSNumber *elite = [obj nullCheckedObjectForKey:@"elite"] ?: @0;
                
                char *sql_insert_stmt = sqlite3_mprintf("INSERT INTO `cards`(name, card_id, cost, type, rarity, faction, text, flavor, artist, playerClass, attack, health, collectible, elite) VALUES('%q', '%q', %i, '%q', '%q', '%q', '%q', '%q', '%q', '%q', %i, %i, %i, %i)", [name UTF8String], [cardId UTF8String], [cost intValue], [type UTF8String], [rarity UTF8String], [faction UTF8String], [text UTF8String], [flavor UTF8String], [artist UTF8String], [playerClass UTF8String], [attack intValue], [health intValue], [collectible intValue], [elite intValue]);
                
                sqlite3_stmt *statement;
                sqlite3_prepare_v2(_db, sql_insert_stmt,
                                   -1, &statement, NULL);
                
                if (sqlite3_step(statement) != SQLITE_DONE) {
                    NSLog(@"%s", sql_insert_stmt);
                    NSLog(@"Error: %s", sqlite3_errmsg(_db));
                    return;
                }
                sqlite3_free(sql_insert_stmt);
                sqlite3_finalize(statement);
            }
        }
    }
    else {
        NSLog(@"%s", errMsg);
    }
}

#pragma mark - SQL fetch helper

- (void)performQuery:(NSString *)query callback:(void (^)(NSArray *))block {
    dispatch_async(dispatch_queue_create("me.hiddencode.hearth.sql.fetch", 0), ^{
        NSArray *result = [self performQuery:query];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            block(result);
        });
    });
}

- (NSArray *)performQuery:(NSString *)query {
    sqlite3_stmt *statement = nil;
    const char *sql = [query UTF8String];
    if (sqlite3_prepare_v2(_db, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSLog(@"[SQLITE] Error when preparing query!");
    } else {
        NSMutableArray *result = [NSMutableArray array];
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            for (int i=0; i<sqlite3_column_count(statement); i++) {
                int col_type = sqlite3_column_type(statement, i);
                const char *col_name = sqlite3_column_name(statement, i);
                id value;
                if (col_type == SQLITE_TEXT) {
                    const unsigned char *col = sqlite3_column_text(statement, i);
                    value = [NSString stringWithFormat:@"%s", col];
                } else if (col_type == SQLITE_INTEGER) {
                    int col = sqlite3_column_int(statement, i);
                    value = [NSNumber numberWithInt:col];
                } else if (col_type == SQLITE_FLOAT) {
                    double col = sqlite3_column_double(statement, i);
                    value = [NSNumber numberWithDouble:col];
                } else if (col_type == SQLITE_NULL) {
                    value = [NSNull null];
                } else {
                    NSLog(@"[SQLITE] UNKNOWN DATATYPE");
                }
                
                NSString *key = [NSString stringWithCString:col_name encoding:NSUTF8StringEncoding];
                dict[key] = value;
            }
            [result addObject:dict];
        }
        return result;
    }
    return nil;
}

@end
