//
//  CSBrowserCapture.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCaptureBase.h"
#import "CSBrowserTaskManager.h"
#import "CSAbstractCaptureDevice.h"

@interface CSBrowserCapture : CSCaptureBase <CSCaptureSourceProtocol>
{

    CSBrowserTaskManager *_taskManager;
    IOSurfaceID _surfaceID;
    IOSurfaceRef _browserSurface;
    
}

@property (strong) NSString *url;

@end
