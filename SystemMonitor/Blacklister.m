//
//  Blacklister.m
//  ListInfo
//
//  Created by Ren, Alice on 7/25/14.
//
//

#import "Blacklister.h"

#import "ProcessInfo.h"
#import "ConnectionInfo.h"

#import "otherConnectionHeaders.h"

@implementation Blacklister

- (void) blacklist:(NSArray *)list forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field {
    NSArray *array = [[NSArray alloc] init];
    
    if ([infoType isEqualToString:@"ConnectionInfo"])
        array = [NSArray arrayWithArray:getActiveConnections(IPPROTO_TCP,"tcp",AF_INET)];
    else if ([infoType isEqualToString:@"ProcessInfo"])
        array = [NSArray arrayWithArray:getProcessInfo()];
    else {
        NSLog(@"Info type %@ not supported",infoType);
        return;
    }
    
    // sort array by field
    if (![[array firstObject] objectForKey:field]) {
        NSLog(@"Field %@ not found",field);
        return;
    }
    
    // search for blacklist terms, one at a time (?) there's probably a way to do this more efficiently (sort array and list?)
    int count = 0;
    for (NSDictionary *dict in array) {
        for (id key in dict) {
            for (int i = 0; i < [list count]; i++) {
                @autoreleasepool {
                    NSString *string = [dict objectForKey:key];
                    if ([string rangeOfString:[list objectAtIndex:i] options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        // alert user
                        NSLog(@"BLACKLIST ALERT: FOUND %@ IN LIST %@: %@",[list objectAtIndex:i],infoType,dict);
                        count++;
                    }
                }
            }
        }
    }
    NSLog(@"FOUND %d BLACKLISTED INSTANCES",count);
}

@end
