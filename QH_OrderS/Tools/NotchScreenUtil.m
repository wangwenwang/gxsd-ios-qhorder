//
//  TwoController.m
//  QH_OrderS
//
//  Created by wangww on 2021/8/10.
//  Copyright © 2021 王文望. All rights reserved.
//

#import "NotchScreenUtil.h"

@interface NotchScreenUtil ()

@end

@implementation NotchScreenUtil

+ (BOOL)isIPhoneNotchScreen{
    BOOL result = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return result;
    }
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [self mainWindow];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            result = YES;
        }
    }
    return result;
}

+ (UIWindow *)mainWindow {
    UIApplication *app = [UIApplication sharedApplication];
    if ([app.delegate respondsToSelector:@selector(window)]) {
        return [app.delegate window];
    }else{
        return [app keyWindow];
    }
}

+ (CGFloat)getIPhoneNotchScreenHeight{
    /*
     * iPhone8 Plus  UIEdgeInsets: {20, 0, 0, 0}
     * iPhone8       UIEdgeInsets: {20, 0, 0, 0}
     * iPhone XR     UIEdgeInsets: {44, 0, 34, 0}
     * iPhone XS     UIEdgeInsets: {44, 0, 34, 0}
     * iPhone XS Max UIEdgeInsets: {44, 0, 34, 0}
     */
    CGFloat bottomSpace = 0;
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeAreaInsets = UIApplication.sharedApplication.windows.firstObject.safeAreaInsets;
        switch (UIApplication.sharedApplication.statusBarOrientation) {
            case UIInterfaceOrientationPortrait:
            {
                bottomSpace = safeAreaInsets.bottom;
            }
                break;
            case UIInterfaceOrientationLandscapeLeft:
            {
                bottomSpace = safeAreaInsets.right;
            }
                break;
            case UIInterfaceOrientationLandscapeRight:
            {
                bottomSpace = safeAreaInsets.left;
            }
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
            {
                bottomSpace = safeAreaInsets.top;
            }
                break;
            default:
            {
                bottomSpace = safeAreaInsets.bottom;
            }
                break;
        }
    }
    return bottomSpace;
}
@end
