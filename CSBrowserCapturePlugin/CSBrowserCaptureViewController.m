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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)resizeBrowser:(id)sender
{
    if (self.captureObj)
    {
        [(CSBrowserCapture *)self.captureObj resize];
    }
}


@end
