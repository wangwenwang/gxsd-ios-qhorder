//
//  NotchScreenUtil.h
//  QH_OrderS
//
//  Created by wangww on 2021/8/10.
//  Copyright © 2021 王文望. All rights reserved.
//

#import <UIKit/UIKit.h>
/*
 * iPhone刘海屏工具类
 */
@interface NotchScreenUtil : NSObject
 
// 判断是否是刘海屏
+(BOOL)isIPhoneNotchScreen;
 
// 获取刘海屏高度
+(CGFloat)getIPhoneNotchScreenHeight;

@end
