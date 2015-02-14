//
//  CSBrowserCaptureViewController.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSBrowserCapture.h"

@interface CSBrowserCaptureViewController : NSViewController

@property CSBrowserCapture *captureObj;

- (IBAction)resizeBrowser:(id)sender;

@end
