//
//  Filter.h
//  SystemMonitor
//
//  Created by Ren, Alice on 7/28/14.
//
//

#import <Foundation/Foundation.h>

@interface Filter : NSObject

- (void) filter:(NSString *)infoType
          field:(NSString *)field
      blacklist:(NSArray *)blacklist
      whitelist:(NSArray *)whitelist;

- (void) blacklist:(NSArray *)list inArray:(NSArray *)array forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field;
- (void) whitelist:(NSArray *)list inArray:(NSArray *)array forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field;

@end