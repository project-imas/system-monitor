//
//  ProcessInfo.h
//  SystemMonitor
//
//  Created by Ren, Alice on 7/24/14.
//
//

#import <Foundation/Foundation.h>

#include <sys/sysctl.h>

/* for PID information */
#include <pwd.h>

@interface ProcessInfo : NSObject

NSMutableArray* getProcessInfo();
- (void) printProcessInfo;

@end
