//
//  ServiceTools.h
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ServiceToolsDelegate <NSObject>

@optional
- (void)failureOfLogin:(nullable NSString *)msg;

@optional
- (void)downloadStart;

@optional
- (void)downloadProgress:(double)progress;

@optional
- (void)downloadCompletion:(nullable NSString *)version andFilePath:(nullable NSString *)filePath;

@optional
- (void)fast_login_click;

@end

@interface ServiceTools : NSObject

@property (strong, nonatomic) WKWebView * _Nullable webview;

@property (strong, nonatomic) NSString * _Nullable abcd;

@property (nullable, weak, nonatomic)id <ServiceToolsDelegate> delegate;


/// 查询版本号
/// @param showPrompt 是否显示提示
- (void)queryAppVersion:(BOOL)showPrompt;


/// 更新用户信息
/// @param userId 用户id
/// @param organizationName 学校名称
/// @param province 省
/// @param city 市
/// @param area 区/县
/// @param address 详细地址
/// @param token 公钥
- (void)uploadUserInfo:(nullable NSString *)userId andOrganizationName:(nullable NSString *)organizationName andProvince:(nullable NSString *)province andCity:(nullable NSString *)city andArea:(nullable NSString *)area andAddress:(nullable NSString *)address andToken:(nullable NSString *)token;


/// 获取手机号
/// @param loginToken SDK获取的 token
- (void)getPhone:(nullable NSString *)loginToken;

@end
