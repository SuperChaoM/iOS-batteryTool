//
//  main.c
//  batteryTool
//
//  Created by SuperChao1 on 2024/1/17.
//  Copyright (c) 2024 ___ORGANIZATIONNAME___. All rights reserved.
//

#include <stdio.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <dlfcn.h>
#include <CoreFoundation/CoreFoundation.h>

// 定义充电阈值变量
float chargeStartThreshold = 0.20; // 开始充电的电量阈值
float chargeStopThreshold = 0.60;  // 停止充电的电量阈值


void traversePreferences() {
    CFStringRef applicationID = CFSTR("com.apple.smartcharging.topoffprotection");
    CFStringRef userName = CFSTR("mobile");
    CFArrayRef keyList = CFPreferencesCopyKeyList(applicationID, userName, kCFPreferencesCurrentHost);

    if (keyList != NULL) {
        for (CFIndex i = 0; i < CFArrayGetCount(keyList); i++) {
            CFStringRef key = (CFStringRef)CFArrayGetValueAtIndex(keyList, i);
            CFPropertyListRef value = CFPreferencesCopyValue(key, applicationID, userName, kCFPreferencesCurrentHost);

            // 在这里处理每个键和值，例如打印它们
            if (key && value) {
                CFShow(key);
                CFShow(value);
            }

            if (value != NULL) {
                CFRelease(value);
            }
        }

        CFRelease(keyList);
    } else {
        printf("No keys found.\n");
    }
}


//https://github.com/SparkDev97/iOS14-Runtime-Headers/blob/f1f1b547ae5f6c98a4eb490258276a67aa3d0226/PrivateFrameworks/PowerUI.framework/PowerUISmartChargeManager.h#L18
void enableCharging()
{
    Class PowerUISmartChargeManager_class = NSClassFromString(@"PowerUISmartChargeManager");
    NSObject *workspace = [PowerUISmartChargeManager_class performSelector:@selector(manager)];

    [workspace performSelector:@selector(enableCharging)];
}

void disableCharging()
{
    Class PowerUISmartChargeManager_class = NSClassFromString(@"PowerUISmartChargeManager");
    NSObject *workspace = [PowerUISmartChargeManager_class performSelector:@selector(manager)];
    [workspace performSelector:@selector(disableCharging)];
        
    int lastBatteryLevel = [workspace performSelector:@selector(lastBatteryLevel)];
    
    int lastFullyCharged = [workspace performSelector:@selector(lastFullyCharged)];
    
    NSLog(@"lastBatteryLevel:%d;lastFullyCharged:%d",lastBatteryLevel,lastFullyCharged);

}

void checkBatteryState() {
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    UIDeviceBatteryState batteryState = [UIDevice currentDevice].batteryState;
//    switch (batteryState) {
//        case UIDeviceBatteryStateUnplugged:
//            // 未充电
//            NSLog(@"未充电");
//            break;
//        case UIDeviceBatteryStateCharging:
//            // 充电中
//            NSLog(@"充电中");
//            break;
//        case UIDeviceBatteryStateFull:
//            // 已充满
//            NSLog(@"已充满");
//            break;
//        case UIDeviceBatteryStateUnknown:
//            // 未知状态
//            NSLog(@"未知状态");
//            break;
//    }
    if (batteryLevel < 0.0) {
        NSLog(@"无法读取电池电量");
    } else {
        NSLog(@"当前电池电量: %0.2f%%", batteryLevel * 100);
        if (batteryLevel < chargeStartThreshold && batteryState != UIDeviceBatteryStateCharging) {
            enableCharging();
            NSLog(@"电池电量低于 %0.2f%%，启动充电", chargeStartThreshold * 100);
        } else if (batteryLevel > chargeStopThreshold && batteryState == UIDeviceBatteryStateCharging) {
            disableCharging();
            NSLog(@"电池电量超过 %0.2f%%，停止充电", chargeStopThreshold * 100);
        }
    }
    
   

}


int main (int argc, const char * argv[])
{

    void *handler = dlopen("/System/Library/PrivateFrameworks/PowerUI.framework/PowerUI", RTLD_LAZY);

    if (!handler) {
        [NSException raise:NSInternalInconsistencyException format:@"Handler is null. /System/Library/PrivateFrameworks/PowerUI.framework/PowerUI."];
    }
    
    disableCharging();

    [UIDevice currentDevice].batteryMonitoringEnabled = YES;

    // 创建一个定时器，每隔一段时间检查电池zw状态
    [NSTimer scheduledTimerWithTimeInterval:60.0 //
                                     target:[NSBlockOperation blockOperationWithBlock:^{
        checkBatteryState();
    }]
                                   selector:@selector(main)
                                   userInfo:nil
                                    repeats:YES];

    // 启动 RunLoop
    [[NSRunLoop currentRunLoop] run];
	return 0;
}

