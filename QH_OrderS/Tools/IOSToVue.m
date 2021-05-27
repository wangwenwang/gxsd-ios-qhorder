//
//  IOSToVue.m
//  QH_OrderS
//
//  Created by wangww on 2019/8/1.
//  Copyright © 2019 王文望. All rights reserved.
//

#import "IOSToVue.h"

@implementation IOSToVue

+ (void)TellVueMsg:(nullable WKWebView *)webView andJsStr:(nullable NSString *)jsStr {
    
//    NSLog(@"%@", jsStr);
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable resp, NSError * _Nullable error) {
            NSLog(@"error = %@ , response = %@",error, resp);
        }];
    });
}

+ (void)TellVueHiddenNav:(nullable WKWebView *)webView {
    
    NSString *jsStr = [NSString stringWithFormat:@"HiddenNav('')"];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueDevice:(nullable WKWebView *)webView andDevice:(nullable NSString *)dev {
    
    NSString *jsStr = [NSString stringWithFormat:@"Device_Ajax('%@')",dev];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueWXBind_YES_Ajax:(nullable WKWebView *)webView andParamsEncoding:(nullable NSString *)paramsEncoding {
    
    NSString *jsStr = [NSString stringWithFormat:@"WXBind_YES_Ajax('%@')",paramsEncoding];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
    
    
}

+ (void)TellVueWXBind_NO_Ajax:(nullable WKWebView *)webView andOpenid:(nullable NSString *)openid {
    
    NSString *jsStr = [NSString stringWithFormat:@"WXBind_NO_Ajax('%@')",openid];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueWXInstall_Check_Ajax:(nullable WKWebView *)webView andIsInstall:(nullable NSString *)isInstall {
    
    NSString *jsStr = [NSString stringWithFormat:@"WXInstall_Check_Ajax('%@')",isInstall];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueCurrAddress:(nullable WKWebView *)webView andAddress:(nullable NSString *)address andLng:(float)lng andLat:(float)lat {
    
    NSString *jsStr = [NSString stringWithFormat:@"SetCurrAddress('%@','%f','%f')", address, lng, lat];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueVersionShow:(nullable WKWebView *)webView andVersion:(nullable NSString *)version {
    
    NSString *jsStr = [NSString stringWithFormat:@"VersionShow('%@')",version];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueSendLocation:(nullable WKWebView *)webView andAddress:(nullable NSString *)address andLng:(float)lng andLat:(float)lat {
    
    NSString *jsStr = [NSString stringWithFormat:@"SetSendLocation('%@','%f','%f')", address, lng, lat];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueContactPeople:(nullable WKWebView *)webView andAddress:(nullable NSString *)name andLng:(nullable NSString *)tel {
    
    NSString *jsStr = [NSString stringWithFormat:@"SetContactPeople('%@','%@')", name, tel];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueUserInfo:(nullable WKWebView *)webView andUserInfo:(nullable NSString *)userInfo {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_userInfo('%@')", userInfo];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueHabbitInfo:(nullable WKWebView *)webView andHabbitInfo:(nullable NSString *)habbitInfo {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_userHabbit('%@')", habbitInfo];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueReadAccumTime:(nullable WKWebView *)webView andReadAccumTime:(nullable NSString *)readAccumTime {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_read_accum_time('%@')", readAccumTime];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueReadGswXml:(nullable WKWebView *)webView andXml:(nullable NSString *)xml andMp3Path:(nullable NSString *)path {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_read_gsw_xml_result('%@','%@')", xml, path];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueStartRecord:(nullable WKWebView *)webView {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_startRecord()"];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueRecordVolume:(nullable WKWebView *)webView andVolume:(int)volume {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_recordVolume('%d')", volume];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueStopRecord:(nullable WKWebView *)webView nextStatus:(nullable NSString *)status {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_stopRecord('%@')", status];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueUpdateUserInfoCompleted:(nullable WKWebView *)webView {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_updateUserInfoCompleted()"];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

+ (void)TellVueRecommend:(nullable WKWebView *)webView andRecommend:(nullable NSString *)channel andTel:(nullable NSString *)tel {
    
    NSString *jsStr = [NSString stringWithFormat:@"LM_AndroidIOSToVue_Recommend('%@','%@')", channel, tel];
    [IOSToVue TellVueMsg:webView andJsStr:jsStr];
}

@end
