//
//  ProcessInfo.m
//  ListInfo
//
//  Created by Ren, Alice on 7/24/14.
//
//

#import "ProcessInfo.h"

@implementation ProcessInfo

NSMutableArray* getProcessInfo() {
    NSMutableArray *info;
    
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    
    do {
        size += size / 10;
        newprocess = realloc(process, size);
        
        if (!newprocess){
            if (process){
                free(process);
            }
        }
        
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
    } while (st == -1 && errno == ENOMEM);
    
    if (st == 0){
        if (size % sizeof(struct kinfo_proc) == 0){
            int nprocess = size / sizeof(struct kinfo_proc);
            
            if (nprocess){
                
                info = [[NSMutableArray alloc] init];
                
                for (int i = nprocess - 1; i >= 0; i--){
                    NSString *pid = [[NSString alloc] initWithFormat:@"%d", process[i].kp_proc.p_pid];
                    NSString *pName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    uid_t uid = process[i].kp_eproc.e_ucred.cr_uid;
                    struct passwd *user = getpwuid(uid);
                    NSString *uname = [[NSString alloc] initWithFormat:@"%s",user->pw_name];
                    
                    NSDictionary * dict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:pid, pName, uname, nil]
                                                                        forKeys:[NSArray arrayWithObjects:@"PID", @"PName", @"User", nil]];
                    [info addObject:dict];
                }
                
                free(process);
            }
        }
    }
    return info;
}

- (void) printProcessInfo {
    NSArray *info = [NSArray arrayWithArray:getProcessInfo()];
    NSLog(@"%@",info);
}

@end
