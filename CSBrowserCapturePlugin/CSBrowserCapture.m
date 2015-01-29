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
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.url = [aDecoder decodeObjectForKey:@"url"];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.url forKey:@"url"];
}


-(void)willDelete
{
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


-(void)setUrl:(NSString *)url
{
    
    if (_url)
    {
        [_taskManager closeURL:_url];
    }
    
    _url = url;
    _surfaceID = [_taskManager loadURL:url];
    self.activeVideoDevice.uniqueID = url;
    self.captureName = url;
    if (_surfaceID)
    {
        _browserSurface = IOSurfaceLookup(_surfaceID);
    }
    
    if (_browserSurface)
    {
        [self updateLayersWithBlock:^(CALayer *layer) {
            ((CSIOSurfaceLayer *)layer).ioSurface = _browserSurface;
        }];
    }
}


-(NSString *)url
{
    return _url;
}


@end
