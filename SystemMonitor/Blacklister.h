//
//  Blacklister.h
//  ListInfo
//
//  Created by Ren, Alice on 7/25/14.
//
//

#import <Foundation/Foundation.h>

@interface Blacklister : NSObject

- (void) blacklist:(NSArray *)list forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field;

@end
