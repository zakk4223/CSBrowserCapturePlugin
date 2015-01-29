//
//  main.m
//  CefWithIOSurface
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#include "cef_app.h"
#include "cef_client.h"
#include "cef_render_handler.h"
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>




class RenderHandler : public CefRenderHandler
{
public:
    IOSurfaceRef m_iosurface;
    
    RenderHandler()
    {
        NSDictionary *sAttrs = @{(NSString *)kIOSurfaceIsGlobal: @YES,
                                 (NSString *)kIOSurfaceWidth: @640,
                                 (NSString *)kIOSurfaceHeight: @480,
                                 (NSString *)kIOSurfaceBytesPerElement: @4,
                                 (NSString *)kIOSurfacePixelFormat:@(kCVPixelFormatType_32BGRA)};
        
        m_iosurface = IOSurfaceCreate((__bridge CFDictionaryRef)sAttrs);
        
    }
    
    ~RenderHandler()
    {
        if (m_iosurface)
        {
            NSLog(@"DEALLOCATE IOSURFACE");
            CFRelease(m_iosurface);
            m_iosurface = NULL;
        }
        
    }
    bool GetViewRect(CefRefPtr<CefBrowser> browser, CefRect &rect)
    {
        rect = CefRect(0,0, 640,480);
        return true;
    }
    void OnPaint(CefRefPtr<CefBrowser> browser, PaintElementType type, const RectList &dirtyRects, const void *buffer, int width, int height)
    {
        if (!m_iosurface)
        {
            return;
        }
        
        IOSurfaceLock(m_iosurface, 0, NULL);
        void *surfBase = IOSurfaceGetBaseAddress(m_iosurface);
        memcpy(surfBase, buffer, width*height*4);
        IOSurfaceUnlock(m_iosurface, 0, NULL);
        
        return;
    }
    
    
    
public:
    IMPLEMENT_REFCOUNTING(RenderHandler);
};


@class RemoteInterface;


class BrowserClient : public CefClient, public CefLifeSpanHandler
{
public:
    BrowserClient(RenderHandler *renderhandler) : m_renderHandler(renderhandler)
    {;}
    
    ~BrowserClient()
    {
        NSLog(@"BROWSER CLIENT DESTROYED");

        m_renderHandler = NULL;
    }

    virtual CefRefPtr<CefRenderHandler> GetRenderHandler() {
        return m_renderHandler;
    }
    
    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler()
    {
        return this;
    }
    
    
    void OnAfterCreated(CefRefPtr<CefBrowser>browser)
    {
        m_Browser = browser;
        m_useCount++;
    }
    
    void CloseBrowser()
    {
        m_Browser->GetHost()->CloseBrowser(true);
        m_Browser = NULL;
    }
    int m_useCount = 0;
    CefRefPtr<CefBrowser> m_Browser;
    CefRefPtr<CefRenderHandler> m_renderHandler;
    
    
    IMPLEMENT_REFCOUNTING(BrowserClient);
};


@interface ParentWatcher : NSThread

@end


@implementation ParentWatcher

-(void)main
{
    pid_t parent_pid = getppid();
    
    int fd = kqueue();
    
    struct kevent kev;
    
    EV_SET(&kev, parent_pid, EVFILT_PROC, EV_ADD|EV_ENABLE, NOTE_EXIT,0,NULL);
    
    kevent(fd, &kev, 1, &kev, 1, NULL);
    
    NSLog(@"PARENT EXITED!!!!");
    exit(0);
    
    //CefShutdown();
    
    
    
}
@end
@interface RemoteInterface : NSObject
{
    std::map<std::string, CefRefPtr<BrowserClient>> _urlMap;
    
    
}


-(IOSurfaceID)loadURL:(NSString *)url;
-(void)closeURL:(NSString *)url;

@end

@implementation RemoteInterface

-(void)closeURL:(NSString *)url
{
    std::string stdurl([url UTF8String]);
    
    CefRefPtr<BrowserClient> browserClient;
    
    browserClient = _urlMap[stdurl];
    
    if (browserClient)
    {
        browserClient->m_useCount--;
        if (browserClient->m_useCount <= 0)
        {
            browserClient->CloseBrowser();
            _urlMap.erase(stdurl);
            browserClient = NULL;
        }
    }
    
}
-(IOSurfaceID)loadURL:(NSString *)url
{
    RenderHandler *renderHandler;
    renderHandler = new RenderHandler();
    
    CefRefPtr<CefBrowser> browser;
    CefRefPtr<BrowserClient> browserClient;
    
    CefWindowInfo window_info;
    CefBrowserSettings browserSettings;
    
    
    std::string stdurl([url UTF8String]);
    
    browserClient = _urlMap[stdurl];
    
    if (!browserClient)
    {
        window_info.SetAsWindowless(NULL, YES);
        
        browserClient = new BrowserClient(renderHandler);
        
        CefBrowserHost::CreateBrowser(window_info, browserClient, [url UTF8String], browserSettings, NULL);
        _urlMap[stdurl] = browserClient;
    } else {
        browserClient->m_useCount++;
    }
    
    
    CefRefPtr<CefRenderHandler> rhbase = browserClient->GetRenderHandler();
    CefRefPtr<RenderHandler> retHandler = static_cast<RenderHandler *>(rhbase.get());
    
    
    return IOSurfaceGetID(retHandler->m_iosurface);
}

@end
int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        
        
        CefMainArgs args(argc, argv);
        
        
        int result = CefExecuteProcess(args, NULL,NULL);
        
        
        if (result >= 0)
        {
            return result;
        }
        
        if (result == -1)
        {
            
        }
        
        

        
        CefSettings settings;
        bool initresult = CefInitialize(args, settings, NULL, NULL);
        
        CefRefPtr<CefCommandLine> cmdline = CefCommandLine::GetGlobalCommandLine();
        const CefString tvalue;
        
        CefString teststr = cmdline.get()->GetSwitchValue("cs_connection_name");
        
        RemoteInterface *rmi = [[RemoteInterface alloc] init];
        NSConnection *server = [NSConnection new];
        
        
        
        server.rootObject = rmi;
        [server registerName:[NSString stringWithUTF8String:teststr.ToString().c_str()]];
        
        
        if (!initresult)
        {
            return -1;
        }
        

        ParentWatcher *watchdog = [[ParentWatcher alloc] init];
        [watchdog start];
        
        CefRunMessageLoop();
        
        
    }
    return 0;
}
