//
//  CSRemoteBrowserProtocol.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CSRemoteBrowserProtocol <NSObject>

-(void)loadURL:(NSString *)url width:(int)width height:(int)height withUUID:(NSString *)uuid withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;
-(void)closeURL:(NSString *)url;
-(void)resizeURL:(NSString *)url width:(int)width height:(int)height withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;

-(void)browserCheckin:(NSString *)uuid;
-(void)setupAudioStream:(int)sampleRate withChannelCount:(int)channelCount forUUID:(NSString *)uuid;
-(void)receiveAudioData:(NSData *)audioData frameCount:(int)frameCount forUUID:(NSString *)uuid;




@end
