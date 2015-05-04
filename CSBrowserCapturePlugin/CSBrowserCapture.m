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



-(void)resize
{
    [_taskManager resizeURL:_url width:self.browser_width height:self.browser_height];
}


-(void)setUrl:(NSString *)url
{
    
    
    IOSurfaceRef oldSurface = _browserSurface;
    if (_url)
    {
        [_taskManager closeURL:_url];
    }
    
    _url = url;
    _surfaceID = [_taskManager loadURL:url width:self.browser_width height:self.browser_height];
    self.activeVideoDevice.uniqueID = url;
    self.captureName = url;
    
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



-(NSString *)url
{
    return _url;
}


@end
