//
//  CSBrowserCaptureViewController.m
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSBrowserCaptureViewController.h"

@interface CSBrowserCaptureViewController ()

@end

@implementation CSBrowserCaptureViewController

- (IBAction)resizeBrowser:(id)sender
{
    if (self.captureObj)
    {
        [(CSBrowserCapture *)self.captureObj resize];
    }
}


@end
