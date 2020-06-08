//
//  CSBrowserCaptureTaskManager.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOSurface/IOSurface.h>
#import "CSRemoteBrowserProtocol.h"

@class CSBrowserCapture;

extern NSString *const CSBrowserCaptureNotificationURLResized;

@interface CSBrowserTaskManager : NSObject
{
    NSTask *_browserTask;
    NSString *_connectionName;
    pid_t _browserPid;
    NSXPCConnection *_taskConnection;
    NSMapTable *_captureMap;
    
}

+(id)sharedBrowserTaskManager;

@property (strong) id<CSRemoteBrowserProtocol> remoteObject;
@property (strong) NSString *xpcUUID;


-(void)loadURL:(NSString *)url width:(int)width height:(int)height withCapture:(CSBrowserCapture *)capture withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;
-(void)closeURL:(NSString *)url;
-(void)resizeURL:(NSString *)url width:(int)width height:(int)height withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;


-(void)setTaskConnection:(NSXPCConnection *)connection;
-(void)launchBrowserTask;



@end
