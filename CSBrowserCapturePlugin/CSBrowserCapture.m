//
//  CSBrowserCapture.m
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSBrowserCapture.h"
#import "CSIOSurfaceLayer.h"

@implementation CSBrowserCapture

@synthesize url = _url;

-(instancetype)init
{
    if (self = [super init])
    {
        _taskManager = [CSBrowserTaskManager sharedBrowserTaskManager];
        
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
    
        self.browser_width = 1280;
        self.browser_height = 720;
        self.urlUUID = [[NSUUID UUID] UUIDString];
        
        _taskManager.xpcUUID = [self createXPCListener];
        
        [_taskManager launchBrowserTask];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlWasResized:) name:CSBrowserCaptureNotificationURLResized object:nil];
    }
    
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.browser_width = [aDecoder decodeIntForKey:@"browser_width"];
        self.browser_height = [aDecoder decodeIntForKey:@"browser_height"];
        self.url = [aDecoder decodeObjectForKey:@"url"];
        
    }
    return self;
}



-(bool)newXPCConnection:(NSXPCConnection *)newConnection forUUID:(NSString *)uuid
{
    if (![uuid isEqualToString:_taskManager.xpcUUID])
    {
        return NO;
    }
    
    
    
    [_taskManager setTaskConnection:newConnection];
    
    if (_url)
    {
        [_taskManager loadURL:_url width:self.browser_width height:self.browser_height withCapture:self withReply:^(IOSurfaceID ioSurfaceID) {
            [self updateSurfaceID:ioSurfaceID];
        }];
        self.activeVideoDevice.uniqueID = _url;
        self.captureName = _url;
    }
    return YES;
}

-(void)urlWasResized:(NSNotification *)notification
{
    if(!_url)
    {
        return;
    }
    
    NSString *notificationURL = (NSString *)notification.object;
    
    if ([notificationURL isEqualToString:_url])
    {
        //WE CARE ALOT
        
        //trickery. set _url to nil so we don't try to close it and possibly destroy the backing window
        _url = nil;
        self.url = notificationURL;
    }
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:@"url"];
    [aCoder encodeInt:self.browser_height forKey:@"browser_height"];
    [aCoder encodeInt:self.browser_width forKey:@"browser_width"];
    
}


-(void)willDelete
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_taskManager)
    {
        [_taskManager closeURL:_url];
    }
}


+(NSString *)label
{
    return @"Browser Capture";
}


-(CALayer *)createNewLayer
{
    
    CSIOSurfaceLayer *newLayer = [CSIOSurfaceLayer layer];
    if (_browserSurface)
    {
        newLayer.ioSurface = _browserSurface;
    }
    
    return newLayer;
}



-(void)updateSurfaceID:(IOSurfaceID)surfaceID
{
    _surfaceID = surfaceID;
    IOSurfaceRef oldSurface = _browserSurface;
    
    if (_surfaceID)
    {
        _browserSurface = IOSurfaceLookup(_surfaceID);
    }
    
    if (_browserSurface)
    {
        
        self.browser_width = (int)IOSurfaceGetWidth(_browserSurface);
        self.browser_height = (int)IOSurfaceGetHeight(_browserSurface);
        
        [self updateLayersWithBlock:^(CALayer *layer) {
            ((CSIOSurfaceLayer *)layer).ioSurface = _browserSurface;
        }];
    }
    
    if (oldSurface)
    {
        CFRelease(oldSurface);
    }
    
}


-(void)resize
{
    [_taskManager resizeURL:_url width:self.browser_width height:self.browser_height withReply:^(IOSurfaceID ioSurfaceID) {
        [self updateSurfaceID:ioSurfaceID];
    }];
}


-(void)setUrl:(NSString *)url
{
    
    
    if (_url)
    {
        [_taskManager closeURL:_url];
    }
    
    _url = url;
    NSLog(@"CALLING SET URL %@ TASKMGR %@ %@", _url, _taskManager, self.pcmPlayer);
    self.activeVideoDevice.uniqueID = url;
    self.captureName = url;
    
    if (!_url)
    {
        return;
    }
    
    if (_taskManager)
    {
        [_taskManager loadURL:_url width:self.browser_width height:self.browser_height withCapture:self withReply:^(IOSurfaceID ioSurfaceID) {
            [self updateSurfaceID:ioSurfaceID];
        }];
    }
    


    
    if (!self.pcmPlayer)
    {
        _audioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100.0 channels:2 interleaved:NO];
        
        self.pcmPlayer = [self createAttachedAudioInputForUUID:self.url withName:self.url withFormat:_audioFormat];
        [self.pcmPlayer play];
        


    } else {
        self.pcmPlayer.name = _url;
    }
    
}


-(void)setupAudioStream:(int)sampleRate withChannelCount:(int)channelCount
{
    
    AVAudioChannelLayout *channelLayout = [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_DiscreteInOrder | channelCount];
    
    AVAudioFormat *newFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:sampleRate interleaved:NO channelLayout:channelLayout];
    if (!self.pcmPlayer)
    {
        _audioFormat = newFormat;
        
        self.pcmPlayer = [self createAttachedAudioInputForUUID:self.url withName:self.url withFormat:_audioFormat];
        [self.pcmPlayer play];
        


    } else {
        if (![newFormat isEqual:_audioFormat])
        {
            [self.pcmPlayer setAudioFormat:newFormat];
            _audioFormat = newFormat;
        }
    }
}


-(void)playPcmAudio:(NSData *)pcmData frameCount:(int)frameCount
{
    
    CAMultiAudioPCM *retPCM = [[CAMultiAudioPCM alloc] initWithDescription:_audioFormat.streamDescription  forFrameCount:frameCount];
    
    memcpy(retPCM.audioBufferList->mBuffers->mData, pcmData.bytes, retPCM.audioBufferList->mBuffers->mDataByteSize*_audioFormat.channelCount);    
    [self.pcmPlayer playPcmBuffer:retPCM];
}

-(NSString *)url
{
    return _url;
}


@end
