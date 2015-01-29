//
//  CSBrowserCaptureTaskManager.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSRemoteBrowserProtocol.h"


@interface CSBrowserTaskManager : NSObject
{
    NSTask *_browserTask;
    NSString *_connectionName;
    NSObject<CSRemoteBrowserProtocol> *_remoteObject;
    pid_t _browserPid;
    
}

+(id)sharedBrowserTaskManager;

-(IOSurfaceID)loadURL:(NSString *)url;
-(void)closeURL:(NSString *)url;

@end
