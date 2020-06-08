//
//  CSBrowserCaptureTaskManager.m
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSBrowserTaskManager.h"
#import "CSRemoteBrowserProtocol.h"
#import "CSBrowserCapture.h"


NSString *const CSBrowserCaptureNotificationURLResized = @"CSBrowserCaptureNotificationURLResized";

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
        _captureMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}


-(void)setTaskConnection:(NSXPCConnection *)connection
{
    NSLog(@"SETTING TASK CONNECTION!");
    _taskConnection = connection;
    NSXPCInterface *taskInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CSRemoteBrowserProtocol)];
    [_taskConnection setRemoteObjectInterface:taskInterface];
    [_taskConnection resume];
    _taskConnection.exportedInterface = taskInterface;
    _taskConnection.exportedObject = self;
    _remoteObject = [_taskConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error connecting to browser task");
    }];
    
    
}

-(void)browserCheckin:(NSString *)uuid
{
    NSLog(@"BROWSER CHECKIN FOR %@", uuid);
}

-(void)resizeURL:(NSString *)url width:(int)width height:(int)height withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;
{
    
    [_remoteObject resizeURL:url width:width height:height withReply:replyBlock];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CSBrowserCaptureNotificationURLResized object:url];
    
}

-(void)loadURL:(NSString *)url width:(int)width height:(int)height  withCapture:(CSBrowserCapture *)capture withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;
{
    //[self createRemoteObject];
    
    if (!replyBlock || !capture || !capture.urlUUID)
    {
        return;
    }
    
    [_captureMap setObject:capture forKey:capture.urlUUID];
    NSLog(@"CALLING REMOTE LOAD URL %@ -> %@", url, _remoteObject);
    [_remoteObject loadURL:url width:width height:height withUUID:capture.urlUUID withReply:replyBlock];
}


-(void)closeURL:(NSString *)url
{
    [_remoteObject closeURL:url];
}


-(void)createRemoteObject
{
    
    int retrycnt = 0;
    if (_remoteObject)
    {
        return;
    }
    
    if (!_browserTask || !_browserTask.isRunning)
    {
        [self launchBrowserTask];
    }
    
    while (!_remoteObject && retrycnt <= 100)
    {
        _remoteObject = (NSObject<CSRemoteBrowserProtocol> *)[NSConnection rootProxyForConnectionWithRegisteredName:_connectionName host:nil];
        usleep(1000);
        
    }
    
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
    _browserTask = [NSTask launchedTaskWithLaunchPath:executablePath arguments:@[[NSString stringWithFormat:@"--cs_connection_name=%@", self.xpcUUID]]];
    
}

-(void)setupAudioStream:(int)sampleRate withChannelCount:(int)channelCount forUUID:(NSString *)uuid
{
    CSBrowserCapture *capture = [_captureMap objectForKey:uuid];
    if (capture)
    {
        [capture setupAudioStream:sampleRate withChannelCount:channelCount ];
    }
}


-(void)receiveAudioData:(NSData *)audioData frameCount:(int)frameCount forUUID:(NSString *)uuid
{
    CSBrowserCapture *capture = [_captureMap objectForKey:uuid];
    if (capture)
    {
        [capture playPcmAudio:audioData frameCount:frameCount];
    }
}


@end
