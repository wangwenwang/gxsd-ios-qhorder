//
//  ServiceTools.m
//  tms-ios
//
//  Created by wenwang wang on 2018/9/28.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "ServiceTools.h"
#import "Tools.h"
#import "AppDelegate.h"
#import "IOSToVue.h"
#import "ViewController.h"
#import "NSString+toDict.h"
#import "NSDictionary+toString.h"
#import "JVERIFICATIONService.h"

@interface ServiceTools()

@property (strong, nonatomic) AppDelegate *app;

@end;

@implementation ServiceTools

- (instancetype)init {
    
    if(self = [super init]) {
        
        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)downZip:(NSString *)urlStr andVersion:(NSString *)version {
    
    WeakSelf;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    // 需要删除文件的物理地址
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *path = [NSString stringWithFormat:@"%@/dist.zip", paths.firstObject];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDelete = [fileManager removeItemAtPath:path error:nil];
    if (isDelete) {
        
        // 删除文件成功
        NSLog(@"删除文件成功");
    }else{
       
        // 删除文件失败
        NSLog(@"删除文件失败");
    }
    
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        if([self.delegate respondsToSelector:@selector(downloadProgress:)]) {
            
            [weakSelf.delegate downloadProgress:downloadProgress.fractionCompleted];
        }
    }  destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        NSLog(@"File downloaded to: %@", filePath);
        if([weakSelf.delegate respondsToSelector:@selector(downloadCompletion:andFilePath:)]) {
            
            [weakSelf.delegate downloadCompletion:version andFilePath:filePath.path];
        }
    }];
    [downloadTask resume];
}

- (void)queryAppVersion:(BOOL)showPrompt {
    
    WeakSelf;
    
    NSString *url = [Tools get_update_url];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
    NSString *params = @"{\"tenantCode\":\"KDY\"}";
    NSDictionary *parameters = @{@"params" : params};
    NSLog(@"接口:%@|zip检测参数：%@", url, parameters);
    
    [manager POST:url parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"请求成功---%@", responseObject);
        int code = [responseObject[@"code"] intValue];
        NSString *Msg = responseObject[@"Msg"];
        if(code == 200) {
            
            NSDictionary *dict = responseObject[@"data"][0];
            NSString *server_zipVersion = dict[@"vueVersion"];
            NSString *currZipVersion = [Tools getZipVersion];
            int c = [Tools compareVersion:server_zipVersion andLocati:currZipVersion];
            if(c == 1) {
                
                // 设置 webView 为 nil，解决WKWebview调用reload导致JSContext失效的问题
                UIViewController *rootViewController = [Tools getRootViewController];
                if([rootViewController isKindOfClass:[ViewController class]]) {
                    
                    ViewController *vc = (ViewController *)rootViewController;
                    [vc.webView removeFromSuperview];
                    vc.webView = nil;
                }
                NSString *server_zipDownloadUrl = dict[@"vueDownloadUrl"];
                NSLog(@"更新zip...");
                
                if([weakSelf.delegate respondsToSelector:@selector(downloadStart)]) {
                    [weakSelf.delegate downloadStart];
                }
                [self downZip:server_zipDownloadUrl andVersion:server_zipVersion];
            }else{
                
                if(showPrompt){
                    
                    [Tools showAlert:((AppDelegate*)([UIApplication sharedApplication].delegate)).window andTitle:@"已经是最新版本"];
                }
            }
        }else {
            if([weakSelf.delegate respondsToSelector:@selector(failureOfLogin:)]) {
                [weakSelf.delegate failureOfLogin:Msg];
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败---%@", error);
        if([weakSelf.delegate respondsToSelector:@selector(failureOfLogin:)]) {
            
            [weakSelf.delegate failureOfLogin:@"请求失败"];
        }
    }];
    
}

- (void)uploadUserInfo:(nullable NSString *)userId andOrganizationName:(nullable NSString *)organizationName andProvince:(nullable NSString *)province andCity:(nullable NSString *)city andArea:(nullable NSString *)area andAddress:(nullable NSString *)address andToken:(nullable NSString *)token {
    NSString *url = @"https://www.gxsd.mobi/gxsd-prod/app/user/updateUserInfo";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"token"];
    NSDictionary *params = @{@"userId": userId, @"organizationName": organizationName, @"province": province, @"city": city, @"area": area, @"address": address};
    NSLog(@"接口:%@|更新用户信息参数：%@", url, params);
    [manager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"请求成功---%@", responseObject);
        int code = [responseObject[@"code"] intValue];
        if(code == 200) {
            [Tools showAlert:((AppDelegate*)([UIApplication sharedApplication].delegate)).window andTitle:@"更新成功"];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"请求失败---%@", error);
        [Tools showAlert:((AppDelegate*)([UIApplication sharedApplication].delegate)).window andTitle:@"请求失败"];
    }];
}

- (void)getPhone:(nullable NSString *)loginToken {
    
    NSString *url = [NSString stringWithFormat:@"https://www.gxsd.mobi/gxsd-prod/system/jiGuang/loginTokenVerifyBody"];
    NSDictionary *params= @{@"loginToken":loginToken};
    NSLog(@"通过token换取手机号参数：%@，%@", url, params);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/plain", nil];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager POST:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        int code = [responseObject[@"code"] intValue];
        NSString *data = responseObject[@"data"];
        if(code == 200) {
            
            [JVERIFICATIONService dismissLoginControllerAnimated:YES completion:NULL];
            [self login:data];
            NSLog(@"通过token换取手机号成功");
        }
        NSLog(@"%@", responseObject);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

        NSLog(@"通过token换取手机号失败");
    }];
}

- (void)login:(nullable NSString *)account {
    
    NSString *url = [NSString stringWithFormat:@"https://www.gxsd.mobi/gxsd-prod/read/readUser/login?account=%@&yzm=999999&accountType=%@&appType=iOS", account, [Tools get_role]];
    NSLog(@"请求APP用户信息参数：%@",url);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:url parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *result = [[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] toDict];
        int code = [result[@"code"] intValue];
        id data = result[@"data"];
        if(code == 200) {

            NSString *params = [data toString];
            NSString *_params = [params stringByReplacingOccurrencesOfString:@"\n"withString:@""];
            NSString *__params = [_params stringByReplacingOccurrencesOfString:@" "withString:@""];
            [JVERIFICATIONService dismissLoginControllerAnimated:YES completion:NULL];
            [IOSToVue TellVueWXBind_YES_Ajax:self->_webview andParamsEncoding:__params];
            NSLog(@"请求APP用户信息成功");
        }else{
            [Tools showAlert:((AppDelegate*)([UIApplication sharedApplication].delegate)).window andTitle:[NSString stringWithFormat:@"异常，错误码：%d", code]];
        }
        NSLog(@"%@", result);

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

        NSLog(@"请求APP用户信息失败");
    }];
}

@end
