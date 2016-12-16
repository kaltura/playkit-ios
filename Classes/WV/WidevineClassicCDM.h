//
//  WidevineClassicCDM.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/12/2015.
//  Copyright © 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    KCDMEvent_Null,
    KCDMEvent_AssetCanPlay,
    KCDMEvent_AssetStatus,
    KCDMEvent_LicenseAcquired,
    KCDMEvent_LicenseFailed,
    KCDMEvent_Unregistered,
    KCDMEvent_FileNotFound,
} KCDMEventType;

typedef void(^KCDMAssetEventBlock)(KCDMEventType event, NSDictionary* data);
typedef void(^KCDMReadyToPlayBlock)(NSString* playbackURL);


@interface WidevineClassicCDM : NSObject

+(void)setEventBlock:(KCDMAssetEventBlock)block forAsset:(NSString*)assetUri;

+(void)registerLocalAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri;
+(void)renewAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri;
+(void)unregisterAsset:(NSString*)assetUri;
+(void)checkAssetStatus:(NSString*)assetUri;

+(void)playAsset:(NSString *)assetUri withLicenseUri:(NSString*)licenseUri readyToPlay:(KCDMReadyToPlayBlock)block;
+(void)playLocalAsset:(NSString*)assetUri readyToPlay:(KCDMReadyToPlayBlock)block;

@end



@interface NSDictionary (Widevine)
-(NSTimeInterval)wvLicenseTimeRemaning;
-(NSTimeInterval)wvPurchaseTimeRemaning;
@end
