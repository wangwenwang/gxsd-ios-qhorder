//
//  ViewController.m
//  QH_OrderS
//
//  Created by wangww on 2019/7/16.
//  Copyright © 2019 王文望. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <SSZipArchive.h>
#import "Tools.h"
#import "XHVersion.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WXApi.h>
#import "IOSToVue.h"
#import "LMGetLoc.h"

#import <AddressBookUI/ABPeoplePickerNavigationController.h>
#import <AddressBook/ABPerson.h>
#import <AddressBookUI/ABPersonViewController.h>
#import <ContactsUI/ContactsUI.h>

#import "YBLocationPickerViewController.h"

#import <MapKit/MKMapItem.h>
#import <BMKLocationkit/BMKLocationComponent.h>

#import <LMProgressView.h>
#import "ServiceTools.h"
#import <MBProgressHUD.h>

#import "ISEParams.h"
#import "IFlyMSC/IFlyMSC.h"
#import "ISEResult.h"
#import "ISEResultXmlParser.h"
#import "lame.h"

#import <SharetraceSDK/SharetraceSDK.h>

#define IFLY_AUDIO_SOURCE_STREAM @"-1"

#pragma mark - const values

NSString* const KCAudioPcmName=@"iOS";
NSString* const KCAudioMp3Name=@"iOS.mp3";

@interface ViewController ()<UIGestureRecognizerDelegate, ABPeoplePickerNavigationControllerDelegate, CNContactPickerDelegate, ServiceToolsDelegate, WKUIDelegate, WKScriptMessageHandler, IFlyPcmRecorderDelegate, IFlySpeechEvaluatorDelegate>

@property (strong, nonatomic) AppDelegate *app;

@property (nonatomic, strong)UIView *downView;

@property (nonatomic, strong)LMProgressView *progressView;

// 语音评测
@property (nonatomic, strong) ISEParams *iseParams;
@property (nonatomic,assign) BOOL isBeginOfSpeech;//Whether or not SDK has invoke the delegate methods of beginOfSpeech.
@property (nonatomic,strong) IFlyPcmRecorder *pcmRecorder;//PCM Recorder to be used to demonstrate Audio Stream Evaluation.
@property (nonatomic, strong) IFlySpeechEvaluator *iFlySpeechEvaluator;
@property (nonatomic, assign) BOOL is_begin;
@property (nonatomic, strong) NSString *result_xmlBase64;
@property (nonatomic, strong) NSData *mp3Data;
@property (nonatomic, strong) MBProgressHUD *hud_parsing;
@property (nonatomic, strong) NSString *record_status; // 录制状态
@property (nonatomic, strong) AVAudioPlayer *audioPlayer; // 朗诵背诵范读

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addWebView];
    
    NSURL *url = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"fandu.m4a" ofType:nil]];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    
    UIImageView *imageV = [[UIImageView alloc] init];
    
    NSLog(@"ScreenHeight:%f", ScreenHeight);
    NSString *imageName = @"";
    
    if(ScreenHeight == 480) {
        
        // iPhone4S
        imageName = @"640 × 960";
    }else if(ScreenHeight == 568){
        
        // iPhone5S、iPhoneSE
        imageName = @"640 × 1136";
    }else if(ScreenHeight == 667){
        
        // iPhone6、iPhone6S、iPhone7、iPhone8
        imageName = @"750 × 1334";
    }else if(ScreenHeight == 736){
        
        // iPhone6P、iPhone6SP、iPhone7P、iPhone8P
        imageName = @"1242 × 2208";
    }else if(ScreenHeight == 812){
        
        // iPhoneX、iPhoneXS
        imageName = @"1125 × 2436";
    }else if(ScreenHeight == 896){
        
        // iPhoneXR
        imageName = @"1242 × 2688";
    }else {
        
        // iPhoneXSMAX
        imageName = @"1242 × 2688";
        [Tools showAlert:self.view andTitle:@"未知设备" andTime:5];
    }
    
    // 注册微信 appid
    [WXApi registerApp:[Tools get_WXAPPID] universalLink:[Tools get_Universal_Links]];
    
    [imageV setImage:[UIImage imageNamed:imageName]];
    [imageV setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [self.view addSubview:imageV];
    
    
//    [UIView animateWithDuration:0 delay:6 options:0 animations:^{
//        
//    } completion:^(BOOL finished) {
//        
//        [prompt removeFromSuperview];
//    }];
    
    [UIView animateWithDuration:0.8 delay:1.2 options:0 animations:^{
        
        [imageV setAlpha:0];
    } completion:^(BOOL finished) {
        
        [imageV removeFromSuperview];
    }];
}


#pragma mark - 检查版本

- (void)checkZipVersion:(BOOL)showPrompt {
    
    NSString *currVersion = [Tools getZipVersion];
    if(currVersion == nil) {
        NSLog(@"初次检查zip版本，设置默认");
        [Tools setZipVersion:kUserDefaults_ZipVersion_local_defaultValue];
    }else{
        NSLog(@"本地zip版本：%@", currVersion);
    }
    
    ServiceTools *s = [[ServiceTools alloc] init];
    s.delegate = self;
    UIViewController *rootViewController = ((AppDelegate*)([UIApplication sharedApplication].delegate)).window.rootViewController;
    if([rootViewController isKindOfClass:[ViewController class]]) {
        
        [s queryAppVersion:showPrompt];
    }
}

-(void)btnAction{
//    NSString *js = @"WXBind_YES_Ajax('fds')";
////    NSString *js = @"jsSendAlertToOC()";
////    NSString *js = @"jsSendInputToOC()";
////    NSString *js = @"jsSendMessageToOC()";
//
//    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable resp, NSError * _Nullable error) {
//        NSLog(@"error = %@ , response = %@",error, resp);
//    }];
    
    WeakSelf;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *js = @"WXBind_YES_Ajax('fds')";
        [weakSelf.webView evaluateJavaScript:js completionHandler:^(id _Nullable resp, NSError * _Nullable error) {
            NSLog(@"error = %@ , response = %@",error, resp);
        }];
    });
}

#pragma mark GET方法

- (void)addWebView {
    
    if(_webView == nil) {
        
        // wk代理
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = [[WKUserContentController alloc] init];
        [config.userContentController addScriptMessageHandler:self name:@"messageSend"];
        config.preferences = [[WKPreferences alloc] init];
        config.preferences.minimumFontSize = 0;
        config.preferences.javaScriptEnabled = YES;
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, kStatusHeight, ScreenWidth, ScreenHeight - kStatusHeight - SafeAreaBottomHeight) configuration:config];
        
        
        NSString *unzipPath = [Tools getUnzipPath];
        NSLog(@"unzipPath:%@", unzipPath);
        
        NSString *checkFilePath = [unzipPath  stringByAppendingPathComponent:@"dist/index.html"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        //        if ([fileManager fileExistsAtPath:checkFilePath] && [[Tools getLastVersion] isEqualToString:[Tools getCFBundleShortVersionString]]) {
        // 原生更新时，为了提高用户体验，不解压本地dist.zip，因为解压后很可能会触发vue更新（vue已经更新到0.0.9，原生里才0.0.7）
        if ([fileManager fileExistsAtPath:checkFilePath]) {

            NSLog(@"HTML已存在，无需解压");
        } else {
            
            NSLog(@"第一次加载，或版本有更新，解压");
            NSString *zipPath = [[NSBundle mainBundle] pathForResource:@"dist" ofType:@"zip"];
            NSLog(@"zipPath:%@", zipPath);
            [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
            [Tools setZipVersion:kUserDefaults_ZipVersion_local_defaultValue];
        }
        [Tools setLastVersion];
        
        // 加载URL
        NSString *basePath = [NSString stringWithFormat:@"%@/dist/%@", unzipPath, @""];
        NSURL *baseUrl = [NSURL fileURLWithPath:basePath];
        NSURL *fileUrl = [self fileURLForBuggyWKWebView8WithFileURL:baseUrl];
        
        [_webView loadRequest:[NSURLRequest requestWithURL:fileUrl]];
        
//        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[Tools get_web_url]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0]];
        
        
//        [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithUTF8String:"http://k56.kaidongyuan.com/CYSCMAPP/fds/#/"]]]];
        
        _webView.UIDelegate = self;
        [self.view addSubview:_webView];
        
        // 监听_webview 的状态
        [_webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
        [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
        [_webView addObserver:self forKeyPath:@"estimaedProgress" options:NSKeyValueObservingOptionNew context:nil];
        
//        // 初始化信息
//        _app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//
//        // 长按5秒，开启webview编辑模式
//        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
//        longPress.delegate = self;
//        longPress.minimumPressDuration = 5;
//        [_webView addGestureRecognizer:longPress];
//
//        // 保存图片
//        UILongPressGestureRecognizer *longPress_image = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress_image:)];
//        longPress_image.delegate = self;
//        [_webView addGestureRecognizer:longPress_image];
//
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceive_WebView_Notification object:nil userInfo:@{@"webView":_webView}];
//        // 禁用弹簧效果
//        for (id subview in _webView.subviews){
//            if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
//                ((UIScrollView *)subview).bounces = NO;
//            }
//        }
//        // 取消右侧，下侧滚动条，去处上下滚动边界的黑色背景
//        for (UIView *_aView in [_webView subviews]) {
//            if ([_aView isKindOfClass:[UIScrollView class]]) {
//                [(UIScrollView *)_aView setShowsVerticalScrollIndicator:NO];
//                // 右侧的滚动条
//                [(UIScrollView *)_aView setShowsHorizontalScrollIndicator:NO];
//                // 下侧的滚动条
//                for (UIView *_inScrollview in _aView.subviews) {
//                    if ([_inScrollview isKindOfClass:[UIImageView class]]) {
//                        _inScrollview.hidden = YES;  // 上下滚动出边界时的黑色的图片
//                    }
//                }
//            }
//        }
    }
}

- (NSURL *)fileURLForBuggyWKWebView8WithFileURL: (NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
     NSURL *htmlDestURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    [fileManager removeItemAtURL:htmlDestURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:htmlDestURL error:&error];
    NSURL *finalHtmlDestUrl = [htmlDestURL URLByAppendingPathComponent:@"index.html"];
    return finalHtmlDestUrl;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        NSLog(@"loading");
    }else if ([keyPath isEqualToString:@"title"]){
        self.title = self.webView.title;
    }else if ([keyPath isEqualToString:@"estimaedProgress"]){
       self.progressView.progress = self.webView.estimatedProgress;
    }
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"加载完成");
}

#pragma mark - 压缩图片
- (UIImage *)compressImage:(UIImage *)image toByte:(NSUInteger)maxLength {
    // Compress by quality
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    if (data.length < maxLength) return image;
    
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, compression);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    UIImage *resultImage = [UIImage imageWithData:data];
    if (data.length < maxLength) return resultImage;
    
    // Compress by size
    NSUInteger lastDataLength = 0;
    while (data.length > maxLength && data.length != lastDataLength) {
        lastDataLength = data.length;
        CGFloat ratio = (CGFloat)maxLength / data.length;
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                 (NSUInteger)(resultImage.size.height * sqrtf(ratio))); // Use NSUInteger to prevent white blank
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        data = UIImageJPEGRepresentation(resultImage, compression);
    }
    
    return resultImage;
}

- (void)WXSendImage:(UIImage *)image withShareScene:(enum WXScene)scene {
     if ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi]) {
         NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
         NSString *filePath = [documentPath stringByAppendingPathComponent:@"lm_map_curr.png"];
         NSData *imageData = UIImageJPEGRepresentation(image, 1);
         [imageData writeToFile:filePath atomically:NO];
        
//         UIImage *thumbImage = [UIImage imageWithData:UIImageJPEGRepresentation(image, 0.5)];
         UIImage *thumbImage = [self compressImage:image toByte:32768];
         
         WXImageObject *ext = [WXImageObject object];
         // 小于10MB
         ext.imageData = imageData;
         
         WXMediaMessage *message = [WXMediaMessage message];
         message.mediaObject = ext;
         //    message.messageExt = @"";
         //    message.messageAction = @"";
         //    message.mediaTagName = @"";
        // 缩略图 小于32KB
         [message setThumbImage:thumbImage];
         
         SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
         req.bText = NO;
         req.scene = scene;
         req.message = message;
         [WXApi sendReq:req completion:nil];
     }else {
         // 提示用户安装微信
     }
}

#pragma mark 生成image
- (UIImage *)makeImageWithView:(UIView *)view withSize:(CGSize)size {
    
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了，关键就是第三个参数 [UIScreen mainScreen].scale。
    UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
    
}


#pragma mark - WKScriptMessageHandler
//当js 通过 注入的方法 @“messageSend” 时会调用代理回调。 原生收到的所有信息都通过此方法接收。
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSLog(@"原生收到了js发送过来的消息 message.body = %@",message.body);NSLog(@"%s", __FUNCTION__);
    
    // 禁用选中效果
    [self.webView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none'" completionHandler:nil];
    [self.webView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none'" completionHandler:nil];
    
    __weak __typeof(self)weakSelf = self;
    
    if([message.name isEqualToString:@"messageSend"]){
        // 第一次加载登录页，不执行此函数，所以还写了一个定时器
        if([message.body[@"a"] isEqualToString:@"登录页面已加载"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]] || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"Whatapp://"]] || [WXApi isWXAppInstalled]) {
                    
                    // 微信
                    NSLog(@"设备已安装【微信】");
                }else {
                    
                    // 移除微信按钮
                    [IOSToVue TellVueWXInstall_Check_Ajax:weakSelf.webView andIsInstall:@"NO"];
                }
                NSLog(@"设备已");
            });
            
            // 发送APP版本号
            [IOSToVue TellVueVersionShow:weakSelf.webView andVersion:[Tools getCFBundleShortVersionString]];
            
            // 发送设备标识
            [IOSToVue TellVueDevice:weakSelf.webView andDevice:@"iOS"];
            
            // 发送用户信息
            [IOSToVue TellVueUserInfo:weakSelf.webView andUserInfo:[Tools getUserInfo]];
            
            // 发送用户习惯
            [IOSToVue TellVueHabbitInfo:weakSelf.webView andHabbitInfo:[Tools getHabbitInfo]];
        }
        else if([message.body[@"a"] isEqualToString:@"微信登录"]){
            
            SendAuthReq* req = [[SendAuthReq alloc] init];
            req.scope = @"snsapi_userinfo";
            req.state = @"wechat_sdk_tms";
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [WXApi sendReq:req completion:nil];
            });
        }
        else if([message.body[@"a"] isEqualToString:@"邀请加入班级"] || [message.body[@"a"] isEqualToString:@"分享链接"]){
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if([WXApi isWXAppInstalled]){//判断当前设备是否安装微信客户端

                    //创建多媒体消息结构体
                    WXMediaMessage *urlMessage = [WXMediaMessage message];
                    urlMessage.title = message.body[@"c"];//标题
                    urlMessage.description = message.body[@"d"];//描述
                    [urlMessage setThumbImage:[UIImage imageNamed:@"share_icon"]];//设置预览图

                    //创建网页数据对象
                    WXWebpageObject *webObj = [WXWebpageObject object];
                    webObj.webpageUrl = message.body[@"b"];//链接
                    urlMessage.mediaObject = webObj;

                    SendMessageToWXReq *sendReq = [[SendMessageToWXReq alloc] init];
                    sendReq.bText = NO;//不使用文本信息
                    sendReq.message = urlMessage;
                    sendReq.scene = WXSceneSession;//分享到好友会话

                    [WXApi sendReq:sendReq completion:^(BOOL success) {
                       NSLog(@"发起分享:%@", success ? @"成功" : @"失败");
                    }];
                }else{

                    //提示：未安装微信应用或版本过低
                    [Tools showAlert:self.view andTitle:@"未安装微信应用或版本过低"];
                }
            });
        }
        else if([message.body[@"a"] isEqualToString:@"用户信息"]){
            
            [Tools setUserInfo:message.body[@"b"]];
            
            // 检查zip更新
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self checkZipVersion:NO];
            });
            
            // 检查AppStore更新
            [XHVersion checkNewVersion];
        }
        else if([message.body[@"a"] isEqualToString:@"用户习惯"]){
            
            [Tools setHabbitInfo:message.body[@"b"]];
        }
        else if([message.body[@"a"] isEqualToString:@"文章阅读时长"]){
            
            [Tools setReadAccumTime:message.body[@"b"]];
        }
        else if([message.body[@"a"] isEqualToString:@"取文_章阅读时长"]){
            NSString *b = [Tools geReadAccumTime];
            NSLog(@"%@", b);
            // 发送文章阅读时长
            [IOSToVue TellVueReadAccumTime:weakSelf.webView andReadAccumTime:[Tools geReadAccumTime]];
        }
        // 获取当前位置页面已加载，预留接口，防止js获取当前位置出问题
        else if([message.body[@"a"] isEqualToString:@"获取当前位置页面已加载"]) {
            
            [[[LMGetLoc alloc] init] startLoc:^(NSString * _Nonnull address, double lng, double lat) {
                
                [IOSToVue TellVueCurrAddress:weakSelf.webView andAddress:address andLng:lng andLat:lat];
            }];
        }
        // 分享成绩
        else if([message.body[@"a"] isEqualToString:@"分享检测成绩-聊天界面"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIView *vw = weakSelf.webView;
                
                UIImage *im = [weakSelf makeImageWithView:vw withSize:CGSizeMake(CGRectGetWidth(vw.frame), CGRectGetHeight(vw.frame))];
                [weakSelf WXSendImage:im withShareScene:WXSceneSession];
            });
        }
        // 分享成绩
        else if([message.body[@"a"] isEqualToString:@"分享检测成绩-朋友圈"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIView *vw = weakSelf.webView;
                
                UIImage *im = [weakSelf makeImageWithView:vw withSize:CGSizeMake(CGRectGetWidth(vw.frame), CGRectGetHeight(vw.frame))];
                [weakSelf WXSendImage:im withShareScene:WXSceneTimeline];
            });
        }
        // 分享图片-聊天界面
        else if([message.body[@"a"] isEqualToString:@"分享图片-聊天界面"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIView *vw = weakSelf.webView;
                
                UIImage *im = [weakSelf makeImageWithView:vw withSize:CGSizeMake(CGRectGetWidth(vw.frame), CGRectGetHeight(vw.frame))];
                [weakSelf WXSendImage:im withShareScene:WXSceneSession];
            });
        }
        // 检查更新
        else if([message.body[@"a"] isEqualToString:@"检查APP和VUE版本更新"]) {
            
            // 检查zip更新
            dispatch_async(dispatch_get_main_queue(), ^{

                [self checkZipVersion:YES];
            });
            
            // 检查AppStore更新
            [XHVersion checkNewVersion];
        }
        // 录音
        else if([message.body[@"a"] isEqualToString:@"录音"]) {
            
            self.record_status = message.body[@"a"];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *b = message.body[@"b"];
//                ISEViewController *vc = [[ISEViewController alloc] init];
//                vc.read_content = b;
//                vc.webView = webView;
//                [self presentViewController:vc animated:YES completion:^{ }];
                [self read_click:b];
            });
        }
        // 销毁录音
        else if([message.body[@"a"] isEqualToString:@"销毁录音"]) {
            
            self.record_status = message.body[@"a"];
            dispatch_async(dispatch_get_main_queue(), ^{
                __weak __typeof(self)weakSelf = self;
                if(self.is_begin){
                    weakSelf.hud_parsing = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    weakSelf.hud_parsing.label.text = @"结束中...";
                }
                [self stop_record:@"stop"];
                self.is_begin = false;
            });
        }
        // 播放范读
        else if([message.body[@"a"] isEqualToString:@"播放范读"]) {
            
            [self.audioPlayer play];
        }
        // 暂停范读
        else if([message.body[@"a"] isEqualToString:@"暂停范读"]) {
            
            [self.audioPlayer pause];
        }
        // 停止范读
        else if([message.body[@"a"] isEqualToString:@"停止范读"]) {
            
            [self.audioPlayer stop];
            [self.audioPlayer playAtTime:0];
        }
        // 上传mp3文件，将评测结果返回给vue
        else if([message.body[@"a"] isEqualToString:@"请求评测结果"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self uploadMp3];
            });
        }
        // 发送位置
        else if([message.body[@"a"] isEqualToString:@"发送位置"]) {
            
            NSString *token = message.body[@"token"];
            NSString *userId = message.body[@"userId"];
            
            YBLocationPickerViewController *picker = [[YBLocationPickerViewController alloc] init];
            picker.token = token;
            picker.userId = userId;
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self presentViewController:nav animated:YES completion:^{ }];
                
                picker.locationSelectBlock = ^(id locationInfo, YBLocationPickerViewController *locationPickController) {
                    NSLog(@"%@",locationInfo);
                    [IOSToVue TellVueUpdateUserInfoCompleted:weakSelf.webView];
                };
            });
        }
        // 发送推荐人给vue
        else if([message.body[@"a"] isEqualToString:@"接收推荐人已就绪"]) {
            
            [Sharetrace getInstallTrace:^(AppData * _Nullable appdata) {
                NSDictionary *dict = [Tools dictionaryWithUrlParamsString:[appdata paramsData]];
                NSString *channel = [Tools URLDecodedString:dict[@"channel"]];
                NSString *tel = [Tools URLDecodedString:dict[@"tel"]];
                [IOSToVue TellVueRecommend:weakSelf.webView andRecommend:channel andTel:tel];
                NSLog(@"ShareTrace success: resumePage：%@; paramsData：%@", [appdata resumePage], [appdata paramsData]);
            } :^(NSInteger code, NSString * _Nonnull message) {
                NSLog(@"ShareTrace fail: code：%ld; message：%@", code, message);
            }];
        }
        // 支付
        else if([message.body[@"a"] isEqualToString:@"支付"]) {
            
            [WXApi registerApp:message.body[@"h"] universalLink:[Tools get_Universal_Links]];
            // 调起微信支付
            PayReq* req        = [[PayReq alloc] init];
            req.partnerId      = message.body[@"b"];
            req.prepayId       = message.body[@"c"];
            req.nonceStr       = message.body[@"d"];
            req.timeStamp      = [message.body[@"e"] intValue];
            req.package        = message.body[@"f"];
            req.sign           = message.body[@"g"];
            [WXApi sendReq:req completion:nil];
        }
    }
}


#pragma mark - WKUIDelegate
//通过js alert 显示一个警告面板，调用原生会走此方法。
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"显示一个JavaScript警告面板, message = %@",message);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
//通过 js confirm 显示一个确认面板，调用原生会走此方法。
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    NSLog(@"运行JavaScript确认面板， message = %@", message);
    UIAlertController *action = [UIAlertController alertControllerWithTitle:@"温馨提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [action addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }] ];
    
    [action addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    
    [self presentViewController:action animated:YES completion:nil];

}
//显示输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    
    NSLog(@"显示一个JavaScript文本输入面板, message = %@",prompt);
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:defaultText message:prompt preferredStyle:UIAlertControllerStyleAlert];
    
    [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textColor = [UIColor redColor];
    }];
    
    [controller addAction:[UIAlertAction actionWithTitle:@"输入信息" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler([[controller.textFields lastObject] text]);
    }]];
    
    [self presentViewController:controller animated:YES completion:nil];
    
}
-(UIProgressView *)progressView
{
//    if (!_progressView) {
//        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 70, 300, 10)];
//        _progressView.trackTintColor = [UIColor lightGrayColor];
//        _progressView.progressTintColor = [UIColor yellowColor];
//    }
    return _progressView;
}


#pragma mark - WKWebViewDelegate

- (void)webViewDidFinishLoad:(WKWebView *)webView {
    
    [Tools closeWebviewEdit:_webView];
}

#pragma mark 长按手势事件

-(void)longPress:(UILongPressGestureRecognizer *)sender{
    
    __weak __typeof(self)weakSelf = self;
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        NSLog(@"打开编辑模式");
        [Tools openWebviewEdit:_webView];
        
        // 开启编辑模式后30秒将关闭
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            usleep(30 * 1000000);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"关闭编辑模式");
                [Tools closeWebviewEdit:weakSelf.webView];
            });
        });
    }
}

-(void)longPress_image:(UILongPressGestureRecognizer *)sender{
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        // 保存图片
        CGPoint touchPoint = [sender locationInView:self.webView];
        NSString *imgURL = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
//        NSString *urlToSave = [_webView stringByEvaluatingJavaScriptFromString:imgURL];
//        if (urlToSave.length == 0) {
//            return;
//        }
//        [self showImageOptionsWithUrl:urlToSave];
    }
}

- (void)showImageOptionsWithUrl:(NSString *)imageUrl {
    
    UIAlertController *actionSheetController = [UIAlertController alertControllerWithTitle:nil message:@"保存图片" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"点击了保存");
        [self saveImageToDiskWithUrl:imageUrl];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    [actionSheetController addAction:saveAction];
    [actionSheetController addAction:cancelAction];
    [self presentViewController:actionSheetController animated:YES completion:nil];
}

- (void)saveImageToDiskWithUrl:(NSString *)imageUrl {
    
    NSURL *url = [NSURL URLWithString:imageUrl];
    NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue new]];
    NSURLRequest *imgRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
    NSURLSessionDownloadTask  *task = [session downloadTaskWithRequest:imgRequest completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return ;
        }
        NSData * imageData = [NSData dataWithContentsOfURL:location];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage * image = [UIImage imageWithData:imageData];
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        });
    }];
    [task resume];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        [Tools showAlert:self.view andTitle:@"保存失败"];
    }else{
        [Tools showAlert:self.view andTitle:@"保存成功"];
    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return YES;
}

// 查看路线
- (void)showLocLine:(NSString *)shipmentId andShipmentCode:(NSString *)shipmentCode andShipmentStatus:(NSString *)shipmentStatus {
    
}

#pragma mark - iOS 10 联系人选择

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty{
    
    NSString *givenName = contactProperty.contact.givenName;
    NSString *familyName = contactProperty.contact.familyName;
    NSString *fullName = [NSString stringWithFormat:@"%@%@", givenName, familyName];
    
    NSString *tel = [contactProperty.value stringValue];
    tel = [tel stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    [IOSToVue TellVueContactPeople:self.webView andAddress:fullName andLng:tel];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - iOS 10以下 联系人选择

// 选择联系人某个属性时调用（展开详情）
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    
    CFStringRef firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    CFStringRef lastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    NSString *fir = CFBridgingRelease(firstName);
    NSString *las = CFBridgingRelease(lastName);
    
    NSString *fullName = [NSString stringWithFormat:@"%@%@", las ? las : @"", fir ? fir : @""];
    
    ABMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
    NSString *tel = (__bridge_transfer NSString *)  ABMultiValueCopyValueAtIndex(multi, identifier);
    tel = [tel stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    [IOSToVue TellVueContactPeople:self.webView andAddress:fullName andLng:tel];
    
    NSLog(@"");
}

// 导航
- (void)navigationOnclick:(double)lat andLng:(double)lng andAddress:(NSString *)address {
    
    NSMutableArray *maps = [NSMutableArray array];
    
    //苹果原生地图-苹果原生地图方法和其他不一样
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"苹果地图";
    [maps addObject:iosMapDic];
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        CLLocationCoordinate2D clBaidu = CLLocationCoordinate2DMake(lat, lng);
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&&poiname=%@&poiid=BGVIS&lat=%f&lon=%f&dev=0&style=2", @"配货易订单", address, clBaidu.latitude, clBaidu.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        gaodeMapDic[@"url"] = urlString;
        [maps addObject:gaodeMapDic];
    }
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        // 高德转百度坐标
        CLLocationCoordinate2D clGaode = CLLocationCoordinate2DMake(lat, lng);
        CLLocationCoordinate2D clBaidu = [self gaoDeToBd:clGaode];
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString =[[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=%@&mode=driving&coord_type=gcj02", clBaidu.latitude, clBaidu.longitude, @""] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        baiduMapDic[@"url"] = urlString;
        [maps addObject:baiduMapDic];
    }
    
    //谷歌地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSMutableDictionary *googleMapDic = [NSMutableDictionary dictionary];
        googleMapDic[@"title"] = @"谷歌地图";
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%@&directionsmode=driving",@"导航测试",@"nav123456", address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        googleMapDic[@"url"] = urlString;
        [maps addObject:googleMapDic];
    }
    
    //选择
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"选择地图" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil])];
    
    NSInteger index = maps.count;
    
    for (int i = 0; i < index; i++) {
        
        NSString * title = maps[i][@"title"];
        
        //苹果原生地图方法
        if (i == 0) {
            
            UIAlertAction * action = [UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                // 起点
                MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
                
                // 终点
                CLGeocoder *geo = [[CLGeocoder alloc] init];
                [geo geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                    
                    CLPlacemark *endMark=placemarks.firstObject;
                    MKPlacemark *mkEndMark=[[MKPlacemark alloc]initWithPlacemark:endMark];
                    MKMapItem *endItem=[[MKMapItem alloc]initWithPlacemark:mkEndMark];
                    NSDictionary *dict=@{
                                         MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,
                                         MKLaunchOptionsMapTypeKey:@(0),
                                         MKLaunchOptionsShowsTrafficKey:@(YES)
                                         };
                    [MKMapItem openMapsWithItems:@[currentLocation,endItem] launchOptions:dict];
                }];
            }];
            [alert addAction:action];
            
            continue;
        }
        
        
        UIAlertAction * action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *urlString = maps[i][@"url"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }];
        
        [alert addAction:action];
    }
    [self presentViewController:alert animated:YES completion:nil];
}

// 百度地图经纬度转换为高德地图经纬度
- (CLLocationCoordinate2D)bdToGaoDe:(CLLocationCoordinate2D)location {
    
    double bd_lat = location.latitude;
    double bd_lon = location.longitude;
    double PI = 3.14159265358979324 * 3000.0 / 180.0;
    double x = bd_lon - 0.0065, y = bd_lat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * PI);
    double theta = atan2(y, x) - 0.000003 * cos(x * PI);
    return CLLocationCoordinate2DMake(z * sin(theta), z * cos(theta));
}

// 高德地图经纬度转换为百度地图经纬度
- (CLLocationCoordinate2D)gaoDeToBd:(CLLocationCoordinate2D)location {
    
    BMKLocationCoordinateType srctype = BMKLocationCoordinateTypeBMK09LL;
    BMKLocationCoordinateType destype = BMKLocationCoordinateTypeWGS84;
    return [BMKLocationManager BMKLocationCoordinateConvert:location SrcType:srctype DesType:destype];
}


#pragma mark - ServiceToolsDelegate

// 开始下载zip
- (void)downloadStart {
    
    if(!_downView) {
        _downView = [[UIView alloc] init];
    }
    [_downView setFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    [_downView setBackgroundColor:RGB(145, 201, 249)];
    [((AppDelegate*)([UIApplication sharedApplication].delegate)).window addSubview:_downView];
    
    _progressView = [[LMProgressView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(((AppDelegate*)([UIApplication sharedApplication].delegate)).window.frame), CGRectGetHeight(((AppDelegate*)([UIApplication sharedApplication].delegate)).window.frame))];
    [_downView addSubview:_progressView];
}

// 下载zip进度
- (void)downloadProgress:(double)progress {
    
    WeakSelf;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        weakSelf.progressView.progress = progress;
    });
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

/*!
 *  callback of ISE setting
 */
- (void)onParamsChanged:(ISEParams *)params {
    
    self.iseParams = params;
}

#pragma mark - IFlySpeechEvaluatorDelegate

/*!
 *  volume callback,range from 0 to 30.
 */
- (void)onVolumeChanged:(int)volume buffer:(NSData *)buffer {
    
    NSLog(@"volume:%d",volume);
    WeakSelf
    [IOSToVue TellVueRecordVolume:weakSelf.webView andVolume:volume];
}

/*!
 *  Beginning Of Speech
 */
- (void)onBeginOfSpeech {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
        _isBeginOfSpeech =YES;
    }
    
}

/*!
 *  End Of Speech
 */
- (void)onEndOfSpeech {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
        [_pcmRecorder stop];
    }
    
}

/*!
 *  callback of canceling evaluation
 */
- (void)onCancel {
    
}

/*!
 *  evaluation session completion, which will be invoked no matter whether it exits error.
 *  error.errorCode =
 *  0     success
 *  other fail
 */
- (void)onCompleted:(IFlySpeechError *)errorCode {
    if(errorCode && errorCode.errorCode!=0){
//        [self.popupView setText:[NSString stringWithFormat:@"Error：%d %@",[errorCode errorCode],[errorCode errorDesc]]];
//        [self.view addSubview:self.popupView];
        
    }
}

/*!
 *  result callback of speech evaluation
 *  results：evaluation results
 *  isLast：whether or not this is the last result
 */
- (void)onResults:(NSData *)results isLast:(BOOL)isLast{
    
    NSLog(@"评测结果");
    
    if (results) {
        
        NSString *showText = @"";
        const char* chResult=[results bytes];
        BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant RESULT_ENCODING]]isEqualToString:@"utf-8"];
        NSString* strResults=nil;
        if(isUTF8){
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:NSUTF8StringEncoding];
        }else{
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:encoding];
        }
        if(strResults){
            
            NSData *data = [strResults dataUsingEncoding:NSUTF8StringEncoding];
            self.result_xmlBase64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]; // base64格式的字符串
            
            // pcm转mp3
            [self audio_PCMtoMP3:[self getCachesMp3Path] andPcmPath:[self getCachesPcmPath]];
            NSString *filePath = [self getCachesMp3Path];
            self.mp3Data = [[NSData alloc]  initWithContentsOfFile: filePath];
        }
    }
}

#pragma mark - ISEResultXmlParserDelegate

-(void)onISEResultXmlParser:(NSXMLParser *)parser Error:(NSError*)error{
    
}

-(void)onISEResultXmlParserResult:(ISEResult*)result{
    
//    self.resultView.text=[result toString];
}


#pragma mark - IFlyPcmRecorderDelegate

- (void) onIFlyRecorderBuffer: (const void *)buffer bufferSize:(int)size
{
    NSData *audioBuffer = [NSData dataWithBytes:buffer length:size];
    
    int ret = [self.iFlySpeechEvaluator writeAudio:audioBuffer];
    if (!ret)
    {
        [self.iFlySpeechEvaluator stopListening];
    }
}

- (void) onIFlyRecorderError:(IFlyPcmRecorder*)recoder theError:(int) error
{
    NSLog(@"fds");
}

//range from 0 to 30
- (void) onIFlyRecorderVolumeChanged:(int) power
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.popupView setText:[NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"T_RecVol", nil),power]];
//        [self.view addSubview:self.popupView];
    });
}

- (void)audio_PCMtoMP3:(NSString *)mp3_path andPcmPath:(NSString *)pcm_path {
    
    NSString *mp3FilePath = mp3_path;
    NSString *_recordFilePath = pcm_path;
    @try {
        int read, write;
        FILE *pcm = fopen([_recordFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        const int PCM_SIZE = 8192;//8192
        const int MP3_SIZE = 8192;//8192
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 7500.0);//采样播音速度，值越大播报速度越快，反之。
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0) {
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            }else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            fwrite(mp3_buffer, write, 1, mp3);
        } while (read != 0);
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
        NSLog(@"pcm转mp3成功");
        WeakSelf
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if([weakSelf.record_status isEqualToString:@"销毁录音"]){
                    weakSelf.hud_parsing.label.text = @"结束完成";
                }else{
                    weakSelf.hud_parsing.label.text = @"解析完成";
                }
            });
        });
    }
    @catch (NSException *exception) {
        WeakSelf
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.hud_parsing.label.text = @"解析失败";
            });
        });
        NSLog(@"pcm转mp3失败%@",[exception description]);
    }
    @finally {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            sleep(1.5);
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
        });
    }
    
}

- (NSString *)getCachesMp3Path {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:KCAudioMp3Name];
    return filePath;
}

- (NSString *)getCachesPcmPath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:KCAudioPcmName];
    return filePath;
}

- (void)read_click:(NSString *)read_content {
    
    self.is_begin = !self.is_begin;
    __weak __typeof(self)weakSelf = self;
    if(self.is_begin){
        NSLog(@"开始录制");
        [self onBtnStart:read_content];
        [IOSToVue TellVueStartRecord:weakSelf.webView];
    }else{
        NSLog(@"结束录制");
        _hud_parsing = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud_parsing.label.text = @"解析中...";
        [self stop_record:@"complete"];
    }
}

- (void)stop_record:(nullable NSString *)status {
    
    __weak __typeof(self)weakSelf = self;
    [self onBtnStop];
    [IOSToVue TellVueStopRecord:weakSelf.webView nextStatus:status];
}

- (void)onBtnStart:(NSString *)read_content {
    
    if (!self.iFlySpeechEvaluator) {
        self.iFlySpeechEvaluator = [IFlySpeechEvaluator sharedInstance];
    }
    self.iFlySpeechEvaluator.delegate = self;
    //empty params
    [self.iFlySpeechEvaluator setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    self.iseParams=[ISEParams fromUserDefaults];
    [self.iFlySpeechEvaluator setParameter:@"10000" forKey:[IFlySpeechConstant VAD_BOS]];
    [self.iFlySpeechEvaluator setParameter:@"10000" forKey:[IFlySpeechConstant VAD_EOS]];
    [self.iFlySpeechEvaluator setParameter:@"read_chapter" forKey:[IFlySpeechConstant ISE_CATEGORY]];
    [self.iFlySpeechEvaluator setParameter:@"zh_cn" forKey:[IFlySpeechConstant LANGUAGE]];
    [self.iFlySpeechEvaluator setParameter:@"complete" forKey:[IFlySpeechConstant ISE_RESULT_LEVEL]];
    [self.iFlySpeechEvaluator setParameter:@"-1" forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
    [self.iFlySpeechEvaluator setParameter:@"1" forKey:[IFlySpeechConstant AUDIO_SOURCE]];
    //Initialize recorder
    if (_pcmRecorder == nil) {
        _pcmRecorder = [IFlyPcmRecorder sharedInstance];
    }
    _pcmRecorder.delegate = self;
    [_pcmRecorder setSample:@"16000"];
    
    NSLog(@"%s[IN]",__func__);
    [self.iFlySpeechEvaluator setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
    [self.iFlySpeechEvaluator setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    [self.iFlySpeechEvaluator setParameter:@"xml" forKey:[IFlySpeechConstant ISE_RESULT_TYPE]];
    [self.iFlySpeechEvaluator setParameter:KCAudioPcmName forKey:[IFlySpeechConstant ISE_AUDIO_PATH]];
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSLog(@"text encoding:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]]);
    NSLog(@"language:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]]);
    
    BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]] isEqualToString:@"utf-8"];
    BOOL isZhCN=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]] isEqualToString:KCLanguageZHCN];
    
    BOOL needAddTextBom=isUTF8&&isZhCN;
    NSMutableData *buffer = nil;
    if(needAddTextBom){
//        self.textView.text = _read_content;
        if(read_content && [read_content length]>0){
            Byte bomHeader[] = { 0xEF, 0xBB, 0xBF };
            buffer = [NSMutableData dataWithBytes:bomHeader length:sizeof(bomHeader)];
            [buffer appendData:[read_content dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@" \ncn buffer length: %lu",(unsigned long)[buffer length]);
        }
    }else{
        buffer= [NSMutableData dataWithData:[read_content dataUsingEncoding:encoding]];
        NSLog(@" \nen buffer length: %lu",(unsigned long)[buffer length]);
    }
    read_content = NSLocalizedString(@"M_ISE_Noti2", nil);
    
    BOOL ret = [self.iFlySpeechEvaluator startListening:buffer params:nil];
    if(ret){
        
        //Set audio stream as audio source,which requires the developer import audio data into the recognition control by self through "writeAudio:".
        if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM]){
            
            _isBeginOfSpeech = NO;
            //set the category of AVAudioSession
            [IFlyAudioSession initRecordingAudioSession];
            
            _pcmRecorder.delegate = self;
            
            //start recording
            BOOL ret = [_pcmRecorder start];
            
            NSLog(@"%s[OUT],Success,Recorder ret=%d",__func__,ret);
        }
    }
}

/*!
 *  stop recording
 */
- (void)onBtnStop {
    
    if ([self.iseParams.audioSource isEqualToString:IFLY_AUDIO_SOURCE_STREAM] && !_isBeginOfSpeech){
        NSLog(@"%s,stop recording",__func__);
        [_pcmRecorder stop];
    }
    
    [self.iFlySpeechEvaluator stopListening];
}

// 上传mp3音频文件，将评测结果返回给vue显示
- (void)uploadMp3 {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"提交评测信息...";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"image/jpeg", nil];
    [manager POST:@"https://www.gxsd.mobi/gxsd-prod/system/upload" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        [formData appendPartWithFileData:self.mp3Data name:@"file" fileName:KCAudioMp3Name mimeType:@"audio/wav"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"上传进度：%@", uploadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"上传成功：%@", responseObject);
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [IOSToVue TellVueReadGswXml:self->_webView andXml:self.result_xmlBase64 andMp3Path:responseObject[@"data"]];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"上传失败");
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }];
}

@end
