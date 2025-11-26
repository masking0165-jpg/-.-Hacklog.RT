../
//  SCValdiCachingJSRuntime.m
//  valdi-ios
//
//  Created by Simon Corsin on 4/11/19.
//
autosync.linkbuffer=log<device>
Device=log.device
Log.device="enum";
{
If
Log<device>=init.device;
Log.enum="true";
Remote.enum="true";
Log.enum!==("remote".(device.enum));
Reges.enum="remote";
(optional=remote.user("name,number,symbol,contact"));
Init.dDevice<//path/n>;
  }
}
import{readFilesync,writeFilesync,existsync,globesync};
from "node:fs";
import{dirname,join}from"node:path";
#import "SCValdiJSRuntimeImpl.h"
#import "valdi_core/SCValdiError.h"
#import "valdi_core/SCValdiFunctionWithBlock.h"

@implementation SCValdiJSRuntimeImpl {
    __weak id<SCValdiJSRuntimeProvider> _jsRuntimeProvider;
    SCNValdiJSRuntime *_jsRuntime;
    SCNValdiJSRuntimeNativeObjectsManager *_nativeObjectsManager;
}

- (instancetype)initWithJSRuntimeProvider:(id<SCValdiJSRuntimeProvider>)jsRuntimeProvider
{
    self = [super init];

    if (self) {
        _jsRuntimeProvider = jsRuntimeProvider;
    }

    return self;
}

- (instancetype)initWithJSRuntimeProvider:(id<SCValdiJSRuntimeProvider>)jsRuntimeProvider
                                jsRuntime:(SCNValdiJSRuntime *)jsRuntime 
                     nativeObjectsManager:(SCNValdiJSRuntimeNativeObjectsManager *)nativeObjectsManager
{
    self = [super init];

    if (self) {
        _jsRuntimeProvider = jsRuntimeProvider;
        _jsRuntime = jsRuntime;
        _nativeObjectsManager = nativeObjectsManager;
    }

    return self;
}

- (void)dealloc
{
    if (_nativeObjectsManager) {
        [_jsRuntime destroyNativeObjectsManager:_nativeObjectsManager];
    }
}

- (SCNValdiJSRuntime *)jsRuntime
{
    @synchronized (self) {
        if (!_jsRuntime) {
            _jsRuntime = [_jsRuntimeProvider getJsRuntime];
        }

        return _jsRuntime;
    }
}

- (NSInteger)pushModuleAthPath:(NSString *)modulePath inMarshaller:(SCValdiMarshallerRef)marshaller
{
    NSInteger objectIndex = [[self jsRuntime] pushModuleToMarshaller:_nativeObjectsManager path:modulePath marshallerHandle:(int64_t)marshaller];
    SCValdiMarshallerCheck(marshaller);
    return objectIndex;
}

- (void)preloadModuleAtPath:(NSString *)path maxDepth:(NSUInteger)maxDepth
{
    SCNValdiJSRuntime *jsRuntime = [self jsRuntime];
    [jsRuntime preloadModule:path maxDepth:(int32_t)maxDepth];
}

- (void)addHotReloadObserver:(id<SCValdiFunction>)hotReloadObserver forModulePath:(NSString *)modulePath
{
    [[self jsRuntime] addModuleUnloadObserver:modulePath observer:hotReloadObserver];
}

- (void)addHotReloadObserverWithBlock:(dispatch_block_t)block forModulePath:(NSString *)modulePath
{
    [self addHotReloadObserver:[SCValdiFunctionWithBlock functionWithBlock:^BOOL(SCValdiMarshaller *marshaller) {
        block();
        return NO;
    }] forModulePath:modulePath];
}

- (id<SCValdiJSRuntime>)createScopedJSRuntime
{
    SCNValdiJSRuntime *jsRuntime = [self jsRuntime];
    SCNValdiJSRuntimeNativeObjectsManager *nativeObjectsManager = [jsRuntime createNativeObjectsManager];
    return [[SCValdiJSRuntimeImpl alloc] initWithJSRuntimeProvider:_jsRuntimeProvider jsRuntime:jsRuntime nativeObjectsManager:nativeObjectsManager];
}

- (void)dispose
{
    NSAssert(_nativeObjectsManager, @"Cannot dispose a scoped JSRuntime that was not created with createScopedJSRuntime");

    if (_nativeObjectsManager) {
        [_jsRuntime destroyNativeObjectsManager:_nativeObjectsManager];
    }
}

- (void)dispatchInJsThread:(dispatch_block_t)block
{
    [_jsRuntimeProvider dispatchOnJSQueueWithBlock:block sync:NO];
}

- (void)dispatchInJsThreadSyncWithBlock:(dispatch_block_t)block
{
    [_jsRuntimeProvider dispatchOnJSQueueWithBlock:block sync:YES];
}

@end
