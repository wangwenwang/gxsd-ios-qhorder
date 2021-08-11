//
//  TwoController.m
//  QH_OrderS
//
//  Created by wangww on 2021/8/10.
//  Copyright © 2021 王文望. All rights reserved.
//

#import "TwoController.h"
#import "NotchScreenUtil.h"

@interface TwoController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *safeAreaTop;

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation TwoController

- (void)viewDidLoad {
    
    _webView.scrollView.bounces = NO;
    [self loadString];
    
    BOOL b = [NotchScreenUtil isIPhoneNotchScreen];
    if(!b){
        _safeAreaTop.constant = 0;
    }
}

- (IBAction)exitOnclick {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadString {
    
    NSURL *url = [NSURL URLWithString:@"https://tongbu.eduyun.cn/tbkt/tbkthtml/h5.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}
@end
