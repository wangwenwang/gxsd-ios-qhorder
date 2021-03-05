//
//  AppDelegate.m
//  QH_OrderS
//
//  Created by wangww on 2019/7/16.
//  Copyright © 2019 王文望. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "ServiceTools.h"
#import <WXApi.h>
#import "Tools.h"
#import <SSZipArchive.h>
#import <LMProgressView.h>
#import "NSString+toDict.h"
#import "NSDictionary+toString.h"
#import "IOSToVue.h"

// 推送
#import <GTSDK/GeTuiSdk.h>                          // GTSDK 头文件
#import <PushKit/PushKit.h>                         // VOIP支持需要导入PushKit库,实现 PKPushRegistryDelegate
#import <UserNotifications/UserNotifications.h>     // iOS10 通知头文件
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif
// GTSDK 配置信息
#define kGtAppId @"3XaObvshst7kndg9Sny0B9"
#define kGtAppKey @"Z4iGcM5qR07sixGQ6T3ZU3"
#define kGtAppSecret @"n59KfCTM428EqYL7RuN8Y4"

#import <IFlyMSC/IFlyMSC.h>

#import <SharetraceSDK/SharetraceSDK.h>

@interface AppDelegate ()<ServiceToolsDelegate, WXApiDelegate, SharetraceDelegate>

@property (strong, nonatomic) WKWebView *webView;

@property (nonatomic, strong)UIView *downView;

@property (nonatomic, strong)LMProgressView *progressView;

@property (nonatomic, strong)BMKMapManager *mapManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // 接收webview
    [self addNotification];
    
    _mapManager = [[BMKMapManager alloc] init];
    // 如果要关注网络及授权验证事件，请设定generalDelegate参数
    
    BOOL ret = [_mapManager start:[Tools get_baidu_map_ak]  generalDelegate:nil];
    if (!ret) {
        NSLog(@"百度地图加载失败！");
    }else {
        NSLog(@"百度地图加载成功！");
    }
    
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    ViewController *mainView = [[ViewController alloc] init];
    _window.rootViewController = mainView;
    [_window makeKeyAndVisible];
    
    // 注册微信凭证
    BOOL b = [WXApi registerApp:[Tools get_WXAPPID] universalLink:@"https://tms.kaidongyuan.com"];
    
    if(b) { NSLog(@"微信注册--成功");}
    else  { NSLog(@"微信注册--失败");}
    
    // 检查HTML zip 是否有更新
    [self checkZipVersion];
    
//    // [ GTSDK ]：使用APPID/APPKEY/APPSECRENT创建个推实例
//    [GeTuiSdk startSdkWithAppId:kGtAppId appKey:kGtAppKey appSecret:kGtAppSecret delegate:self];
//
//    // [ 参考代码，开发者注意根据实际需求自行修改 ] 注册远程通知
//    [self registerRemoteNotification];
//
//    // [ 参考代码，开发者注意根据实际需求自行修改 ] 注册VOIP
//    [self voipRegistration];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    
    //Set APPID
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@", @"5f9a1b08"];
    //Configure and initialize iflytek services.(This interface must been invoked in application:didFinishLaunchingWithOptions:)
    [IFlySpeechUtility createUtility:initString];
    
    [Sharetrace initWithDelegate:self appKey:@"88e7bea3c760a53b"];
    
    return YES;
}


#pragma mark - 微信登录

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    return [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    return [WXApi handleOpenURL:url delegate:self];
}


// 获取tms用户信息
- (void)bindingWX:(NSString *)openid {
    
    WeakSelf;
    
    NSString *params = [NSString stringWithFormat:@"{\"wxOpenid\":\"%@\",\"APPLOGIN\":\"T\"}", openid];
    NSString *paramsEncoding = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *url = [NSString stringWithFormat:@"https://www.gxsd.mobi/gxsd-prod/read/readUser/login?openId=%@&accountType=%@", openid, [Tools get_role]];
    NSLog(@"请求APP用户信息参数：%@",url);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        NSDictionary *result = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];

        int code = [result[@"code"] intValue];
        id data = result[@"data"];
        NSString *message = result[@"message"];

        if(code == 200) {

            NSString *params = [data toString];
            NSString *_params = [params stringByReplacingOccurrencesOfString:@"\n"withString:@""];
            NSString *__params = [_params stringByReplacingOccurrencesOfString:@" "withString:@""];
            NSString *paramsEncoding = [params stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
//            NSString *js = [NSString stringWithFormat:@"WXBind_YES_Ajax('%@')", __params];
//            [weakSelf.webView evaluateJavaScript:js completionHandler:^(id _Nullable resp, NSError * _Nullable error) {
//                NSLog(@"error = %@ , response = %@",error, resp);
//            }];
            
            [IOSToVue TellVueWXBind_YES_Ajax:weakSelf.webView andParamsEncoding:__params];
            
            NSLog(@"请求APP用户信息成功");
        } else{
            
            [IOSToVue TellVueWXBind_NO_Ajax:_webView andOpenid:openid];
            NSLog(@"此微信未注册");
        }
        NSLog(@"%@", result);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

        NSLog(@"请求APP用户信息失败");
    }];
}

// 授权回调的结果
- (void)onResp:(BaseResp *)resp {
    
    NSLog(@"resp:%d", resp.errCode);
    
    if([resp isKindOfClass:[SendAuthResp class]]) {
        
        SendAuthResp *rep = (SendAuthResp *)resp;
        if(resp.errCode == -2) {
            
            NSLog(@"用户取消");
        }else if(resp.errCode == -4) {
            
            NSLog(@"用户拒绝授权");
        }else {
            
            NSString *code = rep.code;
            NSString *appid = [Tools get_WXAPPID];
            NSString *appsecret = [Tools get_WXAPPSECRED];
            NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", appid, appsecret, code];
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            [manager GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                NSDictionary *result = [[[ NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
                NSString *access_token = result[@"access_token"];
                NSString *openid = result[@"openid"];
                [self wxLogin:access_token andOpenid:openid];
                NSLog(@"请求access_token成功");
                [self bindingWX:openid];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                NSLog(@"请求access_token失败");
            }];
        }
    }
}


// 获取微信个人信息
- (void)wxLogin:(NSString *)access_token andOpenid:(NSString *)openid {
    
    NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@", access_token, openid];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *result =[[[ NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
        NSLog(@"请求个人信息成功");
        NSLog(@"%@", result);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"请求个人信息失败");
    }];
}


#pragma mark - 检查版本

- (void)checkZipVersion {
    
    NSString *currVersion = [Tools getZipVersion];
    if(currVersion == nil) {
        NSLog(@"初次检查zip版本，设置默认");
        [Tools setZipVersion:kUserDefaults_ZipVersion_local_defaultValue];
    }else{
        NSLog(@"本地zip版本：%@", currVersion);
    }
    
    ServiceTools *s = [[ServiceTools alloc] init];
    s.delegate = self;
    UIViewController *rootViewController = _window.rootViewController;
    if([rootViewController isKindOfClass:[ViewController class]]) {
        
        [s queryAppVersion:NO];
    }
}


#pragma mark - ServiceToolsDelegate

// 开始下载zip
- (void)downloadStart {
    
    if(!_downView) {
        _downView = [[UIView alloc] init];
    }
    [_downView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [_downView setBackgroundColor:RGB(145, 201, 249)];
    [_window addSubview:_downView];
    
    _progressView = [[LMProgressView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_window.frame), CGRectGetHeight(_window.frame))];
    [_downView addSubview:_progressView];
}

// 下载zip完成
- (void)downloadCompletion:(NSString *)version andFilePath:(NSString *)filePath {
    
    WeakSelf;
    
    NSLog(@"解压中...");
    NSString *unzipPath = [Tools getUnzipPath];
    BOOL unzip_b = [SSZipArchive unzipFileAtPath:filePath toDestination:unzipPath];
    if(unzip_b) {
        
        NSLog(@"解压完成，开始刷新APP内容...");
    }else {
        
        NSLog(@"解压失败");
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"延迟0.5秒");
        usleep(500000);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIViewController *rootViewController = [Tools getRootViewController];
            if([rootViewController isKindOfClass:[ViewController class]]) {
                
                ViewController *vc = (ViewController *)rootViewController;
                [vc addWebView];
            }
            
            [UIView animateWithDuration:0.2 animations:^{
                
                weakSelf.downView.alpha = 0.0f;
            }completion:^(BOOL finished){
                
                [weakSelf.downView removeFromSuperview];
                if(unzip_b) {
                    
                    [Tools setZipVersion:version];
                }else {
                    
                    NSLog(@"zip解压失败，不更新zip版本号");
                }
            }];
            NSLog(@"刷新内容完成");
        });
    });
}

// 下载zip进度
- (void)downloadProgress:(double)progress {
    
    WeakSelf;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weakSelf.progressView.progress = progress;
    });
}


#pragma mark - 通知

- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveWebView:) name:kReceive_WebView_Notification object:nil];
}


- (void)receiveWebView:(NSNotification *)aNotification {
    
    _webView = aNotification.userInfo[@"webView"];
    NSLog(@"");
}
              
@end
