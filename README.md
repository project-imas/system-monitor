system-monitor
==============

View active connections and current processes on device. *Note:* this library makes use of system calls; Apple will not accept any app built using it.

## Fetching Connection Info

`NSMutableArray* getActiveConnections(uint32_t proto, char *name, int af)`

Returns an array containing NSDictionaries with the following keys:
* "Foreign address"
* "Foreign port"
* "Local address"
* "Local port"
* "State"

Example call: `getActiveConnections(IPPROTO_TCP,"tcp",AF_INET)` to fetch active TCP connections.

Example entry in resulting array:

```
{
    "foreign address" = "mpr2.ngd.vip.bf1.yahoo.com";
    "foreign port" = "443 (https)";
    "local address" = "10.0.0.0";
    "local port" = 54000;
    state = "CLOSE_WAIT";
}
```

Use `printTCPConnections` and `printUDPConnections` to NSLog the active TCP or UDP connections, respectively.

## Fetching Process Info

`NSMutableArray* getProcessInfo()`

Returns an array containing NSDictionaries with the following keys:
* "PID"
* "Process name" (process name, up to the first 16 characters)
* "User"

## Filtering (blacklists and whitelists)

The `filter` method in the `Filter.m` class searches the specified list (connections or processes) for the provided blacklist and whitelist terms. It returns an alert if a blacklisted term is *found* or a whitelisted term is *not found* in the specified field, but can be modified to return a boolean or take some other action.

#### Creating a filter

```
- (id)initWithOptions:(NSString *)name
                 info:(NSString *)info
                 type:(NSString *)type
                field:(NSString *)field
                 list:(NSArray *)list
```

where `name` is the name you give the filter, `info` is the type of information you wish to search ("ProcessInfo" or "ConnectionInfo"), `type` is the type of filter ("blacklist" or "whitelist"), `field` is the field to search (see "Fetching Process Info" and "Fetching Connection Info" sections for details), and `list` is an NSArray of the terms you want to search for.

#### Using a filter

Once you have created a filter using `-initWithOptions`, you can run it by calling `- (void)filter`.

#### Example Usage
```
#import <Filter.h>
...
Filter *socialMediaFilter = [[Filter alloc] initWithOptions:@"Social Media Filter"
                                                       info:@"ConnectionInfo"
                                                       type:@"blacklist"
                                                      field:@"foreign address"
                                                       list:@[@"facebook",@"twitter"]];

[socialMediaFilter filter];
```

## TODO
* Update to use constants instead of strings
