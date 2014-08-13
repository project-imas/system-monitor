//
//  Filter.m
//  SystemMonitor
//
//  Created by Ren, Alice on 7/28/14.
//
//

#import "Filter.h"

#import "ProcessInfo.h"
#import "ConnectionInfo.h"

#import "otherConnectionHeaders.h"

@implementation Filter

- (id)initWithOptions:(NSString *)name
                 info:(NSString *)info
                 type:(NSString *)type
                field:(NSString *)field
                 list:(NSArray *)list {
    self = [super init];
    if (self) {
        _filterName = name;
        _infoType = info;
        _filterType = type;
        _field = field;
        _termList = [[NSMutableArray alloc] initWithArray:list];
    }
    return self;
}

- (NSMutableDictionary *)getFilterdict {
    return [[NSMutableDictionary alloc]
            initWithObjects:@[self.filterName, self.infoType, self.filterType, self.field, self.termList]
            forKeys:@[FILTER_NAME, FILTER_INFO_TYPE, FILTER_TYPE, FILTER_FIELD, FILTER_TERMS]];
}

- (id)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _filterName = [dict objectForKey:FILTER_NAME];
        _infoType = [dict objectForKey:FILTER_INFO_TYPE];
        _filterType = [dict objectForKey:FILTER_TYPE];
        _field = [dict objectForKey:FILTER_FIELD];
        _termList = [dict objectForKey:FILTER_TERMS];
    }
    return self;
}

- (void) filter {
    NSArray *array = [[NSArray alloc] init];
    
    if ([self.infoType isEqualToString:CONNECTION_INFO])
        array = [NSArray arrayWithArray:getActiveConnections(IPPROTO_TCP,"tcp",AF_INET)];
    else if ([self.infoType isEqualToString:PROCESS_INFO])
        array = [NSArray arrayWithArray:getProcessInfo()];
    else {
        NSLog(@"Info type %@ not supported",self.infoType);
        return;
    }
    
    if (![[array firstObject] objectForKey:self.field]) {
        NSLog(@"Field %@ not found",self.field);
        return;
    }
    
    if ([self.filterType isEqualToString:WHITELIST]) {
        [self whitelist:self.termList inArray:array forInfoType:self.infoType fieldToSearch:self.field];
    } else {
        [self blacklist:self.termList inArray:array forInfoType:self.infoType fieldToSearch:self.field];
    }
}

- (void) whitelist:(NSArray *)list inArray:(NSArray *)array forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field {
    // search for whitelist terms; if NOT found, raise an alert
    for (int i = 0; i < [list count]; i++) {
        BOOL found = NO;
        for (NSDictionary *dict in array) {
            @autoreleasepool {
                NSString *string = [dict objectForKey:field];
                if ([string rangeOfString:[list objectAtIndex:i] options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    NSLog(@"WHITELIST SUCESS: FOUND %@ IN LIST %@: %@",[list objectAtIndex:i],infoType,dict);
                    found = YES;
                }
            }
        }
        if (!found) {
            NSLog(@"WHITELIST ALERT: DID NOT FIND %@ IN LIST %@",[list objectAtIndex:i],infoType);
        }
    }
}

- (void) blacklist:(NSArray *)list inArray:(NSArray *)array forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field {
    int count = 0;
    for (NSDictionary *dict in array) {
        for (int i = 0; i < [list count]; i++) {
            @autoreleasepool {
                NSString *string = [dict objectForKey:field];
                if ([string rangeOfString:[list objectAtIndex:i] options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    // alert user
                    NSLog(@"BLACKLIST ALERT: FOUND %@ IN LIST %@: %@",[list objectAtIndex:i],infoType,dict);
                    count++;
                }
            }
        }
    }
    NSLog(@"FOUND %d BLACKLISTED INSTANCES",count);
}

@end