//
//  CSBrowserCaptureTaskManager.m
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSBrowserTaskManager.h"
#import "CSRemoteBrowserProtocol.h"

@implementation CSBrowserTaskManager

+(id) sharedBrowserTaskManager
{
    static CSBrowserTaskManager *sharedBrowserTaskManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedBrowserTaskManager = [[self alloc] init];
    });
    
    return sharedBrowserTaskManager;
}



-(instancetype)init
{
    if (self = [super init])
    {
        _browserPid = 0;
    }
    
    return self;
}


-(IOSurfaceID)loadURL:(NSString *)url
{
    [self createRemoteObject];
    
    return [_remoteObject loadURL:url];
}

-(void)closeURL:(NSString *)url
{
    [self createRemoteObject];
    
    [_remoteObject closeURL:url];
}


-(void)createRemoteObject
{
    if (_remoteObject)
    {
        return;
    }
    
    if (!_browserTask || !_browserTask.running)
    {
        [self launchBrowserTask];
    }
    
    _remoteObject = (NSObject<CSRemoteBrowserProtocol> *)[NSConnection rootProxyForConnectionWithRegisteredName:_connectionName host:nil];
}


-(void)launchBrowserTask
{
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    _connectionName = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
    NSBundle *mybundle = [NSBundle bundleForClass:self.class];
    
    NSString *supportPath = mybundle.sharedSupportPath;
    
    NSString *browserPath = [supportPath stringByAppendingPathComponent:@"CefWithIOSurface.app"];
    
    NSBundle *browserBundle = [NSBundle bundleWithPath:browserPath];
    NSString *executablePath = [browserBundle executablePath];
    /*
    NSString *oargs = [NSString stringWithFormat:@"--cs_connection_name=%@", _connectionName];
    char *args[1];
    args[0] = (char *)[oargs UTF8String];
    
    const char *epath = [executablePath UTF8String];
    NSLog(@"BROWSER PATH IS %@", executablePath);
    
    pid_t npid = vfork();
    
    if (!npid)
    {
        //in child
        execve(epath, NULL, NULL);
    } else {
        _browserPid = npid;
    }
    */
    
    NSLog(@"MY PID IS %d", getpid());
    
    _browserTask = [NSTask launchedTaskWithLaunchPath:executablePath arguments:@[[NSString stringWithFormat:@"--cs_connection_name=%@", _connectionName]]];
    
}


@end
