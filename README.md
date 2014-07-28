system-monitor
==============

View active connections and current processes on device. *Note:* this library makes use of system calls; Apple will not accept any app built using it.

## Connection Info

`NSMutableArray* getActiveConnections(uint32_t proto, char *name, int af)`

Returns an array containing NSDictionaries with the following fields:
* Foreign address
* Foreign port
* Local address
* Local port
* State

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

## Process Info

`getProcessInfo` returns an array containing NSDictionaries with the following fields:
* PID
* PName (process name, up to the first 16 characters)
* User

## Blacklists and whitelists

```
- (void) filter:(NSString *)infoType
          field:(NSString *)field
      blacklist:(NSArray *)blacklist
      whitelist:(NSArray *)whitelist;
```

The `filter` method in the `Filter.m` class searches the specified list (connections or processes) for the provided blacklist and whitelist terms. It returns an alert if a blacklisted term is *found* or a whitelisted term is *not found*, but can be modified to return a boolean or take some other action.

Example call: 
```
NSArray *bl = [NSArray arrayWithObjects:@"facebook",@"yahoo",nil];
NSArray *wl = [NSArray arrayWithObjects:@"cats",nil];
[Filterer filter:@"ConnectionInfo" field:@"foreign address" blacklist:bl whitelist:wl];
```
