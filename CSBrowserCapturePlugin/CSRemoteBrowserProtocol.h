//
//  CSRemoteBrowserProtocol.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CSRemoteBrowserProtocol <NSObject>

-(IOSurfaceID)loadURL:(NSString *)url;
-(void)closeURL:(NSString *)url;
-(IOSurfaceID)resizeURL:(NSString *)url width:(int)width height:(int)height;


@end
