//
//  main.m
//  CefWithIOSurface
//
//  Created by Zakk on 1/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import "CSXPCBrokerProtocol.h"
#import "CSRemoteBrowserProtocol.h"

#include "cef_app.h"
#include "cef_client.h"
#include "cef_render_handler.h"
#include "wrapper/cef_library_loader.h"
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

@class RemoteInterface;


class CSCefApp : public CefApp
{
public:
    void OnBeforeCommandLineProcessing(const CefString& process_type, CefRefPtr<CefCommandLine> command_line) override
    {
        command_line->AppendSwitchWithValue("autoplay-policy", "no-user-gesture-required");
        command_line->AppendSwitch("disable-audio-output");
        command_line->AppendSwitch("use-mock-keychain");
    }
public:
    IMPLEMENT_REFCOUNTING(CSCefApp);
};

class AudioHandler : public CefAudioHandler
{
    
public:
    AudioHandler(id<CSRemoteBrowserProtocol> remotePlugin, NSString *remoteUUID) : m_remotePlugin(remotePlugin), m_remoteUUID(remoteUUID)
    {;}
    bool GetAudioParameters(CefRefPtr<CefBrowser> browser, CefAudioParameters& params) override
    {
        return true;
    }
    void OnAudioStreamStarted(CefRefPtr<CefBrowser> browser, const CefAudioParameters& params, int channels) override
    {
        m_channelCount = channels;
        if (m_remotePlugin)
        {
            [m_remotePlugin setupAudioStream:params.sample_rate withChannelCount:channels forUUID:m_remoteUUID];
        }
    }
    
    void OnAudioStreamPacket(CefRefPtr<CefBrowser> browser, const float** data, int frames, int64 pts) override
    {
        if (m_remotePlugin)
        {
            NSMutableData *audioData = [NSMutableData dataWithLength:sizeof(float)*frames*m_channelCount];
            
            int offset = 0;
            uint8_t *dataPtr = (uint8_t *)audioData.mutableBytes;
            
            for(int i = 0; i < m_channelCount; i++)
            {
                memcpy(dataPtr+offset, data[i], sizeof(float)*frames);
                offset += sizeof(float)*frames;
            }
            [m_remotePlugin receiveAudioData:audioData frameCount:frames forUUID:m_remoteUUID];
        }
    }
    
    void OnAudioStreamStopped(CefRefPtr<CefBrowser> browser) override
    {
        
    }
    
    void OnAudioStreamError(CefRefPtr<CefBrowser> browser, const CefString& message) override
    {
        
    }
    int m_channelCount;
    id<CSRemoteBrowserProtocol> m_remotePlugin;
    NSString *m_remoteUUID;
    
public:
    IMPLEMENT_REFCOUNTING(AudioHandler);
};

class RenderHandler : public CefRenderHandler
{
public:
    IOSurfaceRef m_iosurface = NULL;
    int          m_width;
    int          m_height;
    
    
    RenderHandler(int width, int height)
    {
        m_height = height;
        m_width = width;

        if (!(m_height > 0))
        {
            m_height = 720;
        }
        
        if (!(m_width > 0))
        {
            m_width = 1280;
        }
        
        m_iosurface = NULL;
        CreateIOSurface();
    }

    
    RenderHandler()
    {
        
        m_width = 1280;
        m_height = 720;
        m_iosurface = NULL;
        
        CreateIOSurface();
        
    }
    
    ~RenderHandler()
    {
        if (m_iosurface)
        {
            CFRelease(m_iosurface);
            m_iosurface = NULL;
        }
        
    }
    
    void CreateIOSurface()
    {
        

        IOSurfaceRef newSurface;
        size_t current_width = 0;
        size_t current_height = 0;
        
        if (m_iosurface)
        {
            current_width = IOSurfaceGetWidth(m_iosurface);
            current_height = IOSurfaceGetHeight(m_iosurface);
        }
        
        
        if (m_width != current_width || m_height != current_height)
        {
            

            if (m_iosurface)
            {
                CFRelease(m_iosurface);
                m_iosurface = NULL;
            }
            

            NSDictionary *sAttrs = @{(NSString *)kIOSurfaceIsGlobal: @YES,
                                     (NSString *)kIOSurfaceWidth: @(m_width),
                                     (NSString *)kIOSurfaceHeight: @(m_height),
                                     (NSString *)kIOSurfaceBytesPerElement: @4,
                                     (NSString *)kIOSurfacePixelFormat:@(kCVPixelFormatType_32BGRA)};
            
            newSurface = IOSurfaceCreate((__bridge CFDictionaryRef)sAttrs);
            
            IOSurfaceRef oldSurface = m_iosurface;
            m_iosurface = newSurface;
            
            if (oldSurface)
            {
                CFRelease(oldSurface);
            }
        }
    }
    
    
    
    void Resize(int width, int height)
    {
        m_width = width;
        m_height = height;
        CreateIOSurface();
    }
    
    
    void GetViewRect(CefRefPtr<CefBrowser> browser, CefRect &rect)
    {
        
        rect = CefRect(0,0, m_width,m_height);
    }
    
    
    void OnPaint(CefRefPtr<CefBrowser> browser, PaintElementType type, const RectList &dirtyRects, const void *buffer, int width, int height)
    {
        
        if (!m_iosurface)
        {
            return;
        }
        
        size_t s_width = IOSurfaceGetWidth(m_iosurface);
        size_t s_height = IOSurfaceGetHeight(m_iosurface);
        
        if (s_width != width || s_height != height)
        {
            //strange things are afoot. (but probably just a resize in progress)
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




class BrowserClient : public CefClient, public CefLifeSpanHandler
{
public:
    BrowserClient(RenderHandler *renderhandler, AudioHandler *audiohandler) : m_renderHandler(renderhandler), m_audioHandler(audiohandler)
    {;}
    
    ~BrowserClient()
    {
        m_renderHandler = NULL;
    }

    virtual CefRefPtr<CefAudioHandler> GetAudioHandler() override {
        return m_audioHandler;
    }
    
    virtual CefRefPtr<CefRenderHandler> GetRenderHandler() override {
        return m_renderHandler;
    }
    
    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override
    {
        return this;
    }
    
    
    void OnAfterCreated(CefRefPtr<CefBrowser>browser) override
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
    CefRefPtr<CefAudioHandler> m_audioHandler;
    
    
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
    
    exit(0);
    
    //CefShutdown();
    
    
    
}
@end
@interface RemoteInterface : NSObject<CSRemoteBrowserProtocol>
{
    std::map<std::string, CefRefPtr<BrowserClient>> _urlMap;
    
}

@property (strong) RemoteInterface *remotePlugin;

-(void)loadURL:(NSString *)url width:(int)width height:(int)height withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;
-(void)closeURL:(NSString *)url;
-(void)resizeURL:(NSString *)url width:(int)width height:(int)height withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;
@end

@implementation RemoteInterface


-(void)resizeURL:(NSString *)url width:(int)width height:(int)height withReply:(void (^)(IOSurfaceID ioSurfaceID))replyBlock;
{
    
    IOSurfaceID retVal = 0;
    
    std::string stdurl([url UTF8String]);
    
    CefRefPtr<BrowserClient> browserClient;
    
    browserClient = _urlMap[stdurl];
    
    if (browserClient && browserClient->m_Browser)
    {
        CefRefPtr<CefRenderHandler> rhbase = browserClient->GetRenderHandler();
        CefRefPtr<RenderHandler> retHandler = static_cast<RenderHandler *>(rhbase.get());

        retHandler->Resize(width, height);

        browserClient->m_Browser->GetHost()->WasResized();
        retVal = IOSurfaceGetID(retHandler->m_iosurface);
    }
    
    
    if (replyBlock)
    {
        replyBlock(retVal);
    }
}



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

-(void)loadURL:(NSString *)url width:(int)width height:(int)height withUUID:(NSString *)uuid withReply:(void (^)(IOSurfaceID))replyBlock
{
    
    CefRefPtr<CefBrowser> browser;
    CefRefPtr<BrowserClient> browserClient;
    
    CefWindowInfo window_info;
    CefBrowserSettings browserSettings;
    CefRefPtr<RenderHandler> retHandler;
    
    
    std::string stduuid([uuid UTF8String]);
    
    browserClient = _urlMap[stduuid];
    
    if (!browserClient)
    {
        RenderHandler *renderHandler;
        renderHandler = new RenderHandler(width, height);
        

        AudioHandler *audioHandler;
        audioHandler = new AudioHandler(self.remotePlugin, uuid);
        
        window_info.SetAsWindowless(NULL);
        browserClient = new BrowserClient(renderHandler, audioHandler);
        
        CefBrowserHost::CreateBrowser(window_info, browserClient, [url UTF8String], browserSettings, NULL, NULL);
        _urlMap[stduuid] = browserClient;
        retHandler = renderHandler;
        
    } else {
        browserClient->m_useCount++;
        CefRefPtr<CefRenderHandler> rhbase = browserClient->GetRenderHandler();
        retHandler = static_cast<RenderHandler *>(rhbase.get());
    }
    
    
    
    IOSurfaceID retVal = IOSurfaceGetID(retHandler->m_iosurface);

    if (replyBlock)
    {
        replyBlock(retVal);
    }
}


@end
int main(int argc, char * argv[]) {
    @autoreleasepool {
        
        
        CefScopedLibraryLoader library_loader;
        if (!library_loader.LoadInMain())
        {
            NSLog(@"CEF LIBRARY LOAD FAILED");
            return 1;
        }
        
        CefMainArgs args(argc, argv);
        CefRefPtr<CSCefApp> myapp(new CSCefApp);
        
        
        
        int result = CefExecuteProcess(args, myapp,NULL);
        
        
        if (result >= 0)
        {
            return result;
        }
        
        if (result == -1)
        {
            
        }
        
        

        
        CefSettings settings;
    
        bool initresult = CefInitialize(args, settings, myapp, NULL);
        
        CefRefPtr<CefCommandLine> cmdline = CefCommandLine::GetGlobalCommandLine();

        const CefString tvalue;
        
        CefString teststr = cmdline.get()->GetSwitchValue("cs_connection_name");
        
        
        NSXPCInterface *brokerInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CSXPCBrokerProtocol)];
        NSXPCConnection *connection = [[NSXPCConnection alloc] initWithMachServiceName:@"zakk.lol.cocoasplit.broker" options:0];
        [connection setRemoteObjectInterface:brokerInterface];
        [connection resume];
        
        id<CSXPCBrokerProtocol> brokerObj = [connection synchronousRemoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            NSLog(@"CEF NO BROKER CONNECTION");
        }];
        
        RemoteInterface *rmi = [[RemoteInterface alloc] init];
        NSString *browserUUID = [NSString stringWithUTF8String:teststr.ToString().c_str()];
        [brokerObj retrieveListenerforUUID:browserUUID withReply:^(NSXPCListenerEndpoint * _Nonnull listener) {
            NSXPCInterface *pluginInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CSRemoteBrowserProtocol)];
            
            NSXPCConnection *pluginConnection = [[NSXPCConnection alloc] initWithListenerEndpoint:listener];
            pluginConnection.exportedInterface = pluginInterface;
            pluginConnection.exportedObject = rmi;
            
            [pluginConnection setRemoteObjectInterface:pluginInterface];

            [pluginConnection resume];
            
            id<CSRemoteBrowserProtocol>pluginObj = [pluginConnection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
                NSLog(@"Error connecting to browser task");
            }];
            [pluginObj browserCheckin:browserUUID];
            rmi.remotePlugin = pluginObj;
        }];
                
        
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
