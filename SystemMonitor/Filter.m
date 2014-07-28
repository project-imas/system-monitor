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

- (void) filter:(NSString *)infoType
          field:(NSString *)field
      blacklist:(NSArray *)blacklist
      whitelist:(NSArray *)whitelist {
    NSArray *array = [[NSArray alloc] init];
    
    if ([infoType isEqualToString:@"ConnectionInfo"])
        array = [NSArray arrayWithArray:getActiveConnections(IPPROTO_TCP,"tcp",AF_INET)];
    else if ([infoType isEqualToString:@"ProcessInfo"])
        array = [NSArray arrayWithArray:getProcessInfo()];
    else {
        NSLog(@"Info type %@ not supported",infoType);
        return;
    }
    
    if (![[array firstObject] objectForKey:field]) {
        NSLog(@"Field %@ not found",field);
        return;
    }
    
    /* whitelist */
    [self whitelist:whitelist inArray:array forInfoType:infoType fieldToSearch:field];
    
    
    /* blacklist */
    [self blacklist:blacklist inArray:array forInfoType:infoType fieldToSearch:field];
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
    // search for blacklist terms, one at a time (?) there's probably a way to do this more efficiently (sort array and list?)
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
