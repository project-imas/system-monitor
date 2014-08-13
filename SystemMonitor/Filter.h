//
//  Filter.h
//  SystemMonitor
//
//  Created by Ren, Alice on 7/28/14.
//
//

#import <Foundation/Foundation.h>

@interface Filter : NSObject

@property NSString *filterName;
@property NSString *infoType;
@property NSString *filterType;
@property NSString *field;
@property NSMutableArray *termList;
@property NSMutableDictionary *filterDict;

- (id)initWithOptions:(NSString *)name
                 info:(NSString *)info
                 type:(NSString *)type
                field:(NSString *)field
                 list:(NSArray *)list;
- (id)initWithDict:(NSDictionary *)dict;

- (NSMutableDictionary *)getFilterdict;

- (void) filter;

- (void) blacklist:(NSArray *)list inArray:(NSArray *)array forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field;
- (void) whitelist:(NSArray *)list inArray:(NSArray *)array forInfoType:(NSString *)infoType fieldToSearch:(NSString *)field;

@end