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
    AVAudioFormat *_audioFormat;
    
}

@property (strong) CSPcmPlayer *pcmPlayer;
@property (strong) NSString *urlUUID;
@property (strong) NSString *url;
@property (assign) int browser_width;
@property (assign) int browser_height;
-(void)resize;
-(void)playPcmAudio:(NSData *)pcmData frameCount:(int)frameCount;
-(void)setupAudioStream:(int)sampleRate withChannelCount:(int)channelCount;
@end

