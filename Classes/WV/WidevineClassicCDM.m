//
//  WidevineClassicCDM.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/12/2015.
//  Copyright © 2015 Kaltura. All rights reserved.
//

#import "WidevineClassicCDM.h"

#import "WViPhoneAPI.h"

#define WV_PORTAL_ID @"kaltura"


@interface NSString (Widevine)
-(NSString*)wvAssetPath;
@end


@implementation WidevineClassicCDM

#if TARGET_OS_SIMULATOR || !WIDEVINE_ENABLED
// If the Widevine Classic library is not present, we need to stub it, to satisfy the linker.
WViOsApiStatus WV_Initialize(const WViOsApiStatusCallback callback, NSDictionary *settings ) {
    
    // Help developers find the misconfiguration by crashing.
#if TARGET_OS_SIMULATOR || DEBUG
    assert(!"FATAL error: Widevine Classic is not avaialble");
#endif
    
    callback(WViOsApiEvent_InitializeFailed, @{}); 
    return WViOsApiStatus_NotInitialized; 
}

WViOsApiStatus WV_Terminate() { return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_SetCredentials( NSDictionary *settings ) { return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_RegisterAsset (NSString *asset) { return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_UnregisterAsset (NSString *asset) { return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_QueryAssetStatus (NSString *asset ) { return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_NowOnline () { return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_RenewAsset (NSString *asset) { return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_Play (NSString *asset, NSMutableString *url, NSData *authentication ) {[url setString:asset]; return WViOsApiStatus_NotInitialized; }
WViOsApiStatus WV_Stop () { return WViOsApiStatus_NotInitialized; }
NSString *NSStringFromWViOsApiEvent( WViOsApiEvent event ) { return @"Stub"; }
#endif

static NSMutableDictionary* assetBlocks;

static NSNumber* wvInitialized;


+(void)dispatchAfterInit:(dispatch_block_t)block {
    
    // TODO: assuming initialization takes less than 200 msec. 
    
    if ([wvInitialized boolValue]) {
        if ([NSThread isMainThread]) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
        return;
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC), dispatch_get_main_queue(), block);
    }
}

static WViOsApiStatus widevineCallback(WViOsApiEvent event, NSDictionary *attributes) {
    return [WidevineClassicCDM widevineCallbackWithEvent:event attr:attributes];
}

+(WViOsApiStatus)widevineCallbackWithEvent:(WViOsApiEvent)event attr:(NSDictionary*)attributes {
    
    BOOL ignoreEvent = NO;
    KCDMEventType cdmEvent = KCDMEvent_Null;
    
    switch (event) {
        // Normal flow
        case WViOsApiEvent_Initialized:
            wvInitialized = @YES;
            break;
            
        case WViOsApiEvent_Registered: break;
        case WViOsApiEvent_EMMReceived: 
            cdmEvent = KCDMEvent_LicenseAcquired;
            break;
            
        case WViOsApiEvent_Playing:
            cdmEvent = KCDMEvent_AssetCanPlay;
            break;
            
        case WViOsApiEvent_Stopped: break;
            
        case WViOsApiEvent_QueryStatus:
            cdmEvent = KCDMEvent_AssetStatus;
            break;
            
        // Normal flow
        case WViOsApiEvent_EMMRemoved:
        case WViOsApiEvent_Unregistered:
            cdmEvent = KCDMEvent_Unregistered;
            break;
        case WViOsApiEvent_Terminated: 
            // Do nothing.
            break;
            
        // Errors
        case WViOsApiEvent_InitializeFailed:
            wvInitialized = @NO;
            break;
            
        case WViOsApiEvent_NullEvent:
            if ((WViOsApiStatus)[attributes[@"WVStatusKey"] intValue] == WViOsApiStatus_FileNotPresent) {
                cdmEvent = KCDMEvent_FileNotFound;
            }
            break;
            
        case WViOsApiEvent_EMMFailed:
            cdmEvent = KCDMEvent_LicenseFailed;
            break;
            
        case WViOsApiEvent_PlayFailed:
        case WViOsApiEvent_StoppingOnError: 
            // Do nothing, consider reporting to client.
            break;
            
        default:
            // Other events are just informative, don't even report them.
            ignoreEvent = YES;
            break;
    }
    
    if (ignoreEvent) {
        return WViOsApiStatus_OK;
    }
    
    NSString* assetPath = attributes[WVAssetPathKey];
    NSString* wvEventString = NSStringFromWViOsApiEvent(event);
    
    if (!assetPath) {
        // Not an asset event
        return WViOsApiStatus_OK;
    }
    
    [self callAssetBlockFor:assetPath event:cdmEvent data:attributes];
    
    return WViOsApiStatus_OK;

}

+ (void)initialize {
    
    if (wvInitialized) {
        return;
    }
    
    @synchronized([self class]) {
        
        if (wvInitialized) {
            return;
        }
        
        wvInitialized = @NO;
        assetBlocks = [NSMutableDictionary new];
        
        NSDictionary* settings = @{
                                   WVPortalKey: WV_PORTAL_ID,
                                   WVAssetRootKey: NSHomeDirectory(),
                                   };
        
        WViOsApiStatus wvStatus = WV_Initialize(widevineCallback, settings);
    }
}

+(void)setEventBlock:(KCDMAssetEventBlock)block forAsset:(NSString*)assetUri {

    // Nils not allowed.
    if (!block) {
        return;
    }
    if (!assetUri) {
        return;
    }
    
    // only use the url part before the query string.
    NSArray* split = [assetUri componentsSeparatedByString:@"?"];
    assetUri = [split firstObject];
    
    // register using widevine's assetPath
    assetUri = assetUri.wvAssetPath;
    if (assetUri) {
        assetBlocks[assetUri] = [block copy];
    }
}

+(void)callAssetBlockFor:(NSString*)assetPath event:(KCDMEventType)event data:(NSDictionary*)data {
    
    // only use the url part before the query string.
    NSArray* split = [assetPath componentsSeparatedByString:@"?"];
    assetPath = [split firstObject];
    
    KCDMAssetEventBlock assetBlock = assetBlocks[assetPath];

    if (assetBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            assetBlock(event, data);
        });
    }
}

+(void)registerLocalAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri renew:(BOOL)renew {
    
    // It's an error to call this function without the licenseUri.
    if (!licenseUri) {
        return;
    }
    
    __weak WidevineClassicCDM *weakSelf = self;
    [self dispatchAfterInit:^{
        __strong WidevineClassicCDM *strongSelf = weakSelf;
        WV_SetCredentials(@{WVDRMServerKey: licenseUri});
        
        NSString* assetPath = assetUri.wvAssetPath;
        
        WViOsApiStatus wvStatus = WViOsApiStatus_OK;
        
        wvStatus = WV_RegisterAsset(assetPath);
        if ((int)wvStatus == 1013) {
            wvStatus = WViOsApiStatus_FileNotPresent;
        }
        
        if ((int)wvStatus == 4100) {
            // Already registered -- not an error.
            wvStatus = WV_RenewAsset(assetPath);
        }

        if (wvStatus == WViOsApiStatus_FileNotPresent) {
            [[strongSelf class] widevineErrorWithEvent:WViOsApiEvent_NullEvent status:wvStatus asset:assetPath];
            return;
        } else if (wvStatus != WViOsApiStatus_OK) {
            [[strongSelf class] widevineErrorWithEvent:WViOsApiEvent_NullEvent status:wvStatus asset:assetPath];
        }
        WV_NowOnline(); 
        WV_QueryAssetStatus(assetPath);
    }];
}

+(void)registerLocalAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri {
    [self registerLocalAsset:assetUri withLicenseUri:licenseUri renew:NO];
}

+(void)renewAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri {
    [self registerLocalAsset:assetUri withLicenseUri:licenseUri renew:YES];
}

+(void)widevineErrorWithEvent:(WViOsApiEvent)event status:(WViOsApiStatus)status asset:(NSString*)assetPath {
    [self widevineCallbackWithEvent:event attr:@{
                                                 WViOsApiStatusKey: @(status),
                                                 WVAssetPathKey: assetPath,
                                                 }];
}

+(void)unregisterAsset:(NSString*)assetUri {
    NSString* assetPath = assetUri.wvAssetPath;
    WViOsApiStatus wvStatus = WV_UnregisterAsset(assetPath);

    if ((int)wvStatus == 4017) {    // undocumented value that seems to mean the same.
        wvStatus = WViOsApiStatus_NotRegistered;
    }
    if (wvStatus == WViOsApiStatus_NotRegistered) {
        [self widevineErrorWithEvent:WViOsApiEvent_Unregistered status:wvStatus asset:assetPath];
    } else if (wvStatus != WViOsApiStatus_OK) {
        [self widevineErrorWithEvent:WViOsApiEvent_NullEvent status:wvStatus asset:assetPath];
    }
}


+(void)checkAssetStatus:(NSString*)assetUri {
    NSString* assetPath = assetUri.wvAssetPath;

    WViOsApiStatus wvStatus = WV_QueryAssetStatus(assetPath);
    if (wvStatus != WViOsApiStatus_OK) {
        [self widevineErrorWithEvent:WViOsApiEvent_QueryStatus status:wvStatus asset:assetPath];
    }
}


+(void)playAsset:(NSString *)assetUri withLicenseUri:(NSString*)licenseUri readyToPlay:(KCDMReadyToPlayBlock)block {
    
    [self dispatchAfterInit:^{
        NSMutableString* playbackURL = [NSMutableString new];
        NSString* assetPath = assetUri.wvAssetPath;
        
        // We can try playing even if we don't have the licenseUri -- if the license is already stored.
        if (licenseUri) {
            WV_SetCredentials(@{WVDRMServerKey: licenseUri});
        }
        
        WViOsApiStatus status = WV_Play(assetPath, playbackURL, nil);
        if (status == WViOsApiStatus_AlreadyPlaying) {
            WV_Stop();
            status = WV_Play(assetPath, playbackURL, nil);
        }
        if (block) {
            block([playbackURL copy]);
        }
    }];

}

+(void)playLocalAsset:(NSString*)assetUri readyToPlay:(KCDMReadyToPlayBlock)block {
    [self playAsset:assetUri withLicenseUri:nil readyToPlay:block];
}

@end



@implementation NSString (Widevine)

-(NSString*)wvAssetPath {
    NSString* assetUri = self;
    NSString* assetPath;
    
    if ([assetUri hasPrefix:@"file://"]) {
        // File URL -- convert to file path
        assetUri = [NSURL URLWithString:assetUri].path;
    }
    
    if ([assetUri hasPrefix:@"/"]) {
        // Downloaded file
        
        // Ensure it's in the home directory.
        // This is actually the simplest way to get the path of a file URL.
        NSString* homeDir = NSHomeDirectory();
        if ([assetUri hasPrefix:homeDir]) {
            // strip the homedir, including the slash. 
            assetPath = [assetUri substringFromIndex:homeDir.length+1];
            // assetPath is now homeDir + "/" + assetUri
        } else {
            // will return nil
        }
    } else {
        // Online file
        assetPath = assetUri;
    }
    
    return assetPath;
}

@end





@implementation NSDictionary (Widevine)

-(NSTimeInterval)wvLicenseTimeRemaning {
    return ((NSNumber*)self[WVEMMTimeRemainingKey]).doubleValue;
}

-(NSTimeInterval)wvPurchaseTimeRemaning {
    return ((NSNumber*)self[WVPurchaseTimeRemainingKey]).doubleValue;
}

@end
