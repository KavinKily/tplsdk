#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FBlueSDKPublicHeader.h"
#import "FeasyCallbackSDK.h"
#import "FEBluetoothSDK.h"
#import "FEBluetoothSetting.h"
#import "FEComponent.h"
#import "FEDeviceInfo.h"
#import "FEOTA.h"
#import "FEPeripheral.h"
#import "FEWiFi.h"
#import "FSCError.h"

FOUNDATION_EXPORT double tplsdkVersionNumber;
FOUNDATION_EXPORT const unsigned char tplsdkVersionString[];

