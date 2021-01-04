//
//  ISEViewController.h
//  MSCDemo_UI
//
//  Created by 张剑 on 15/1/15.
//
//

#import <UIKit/UIKit.h>

@class ISEParams;

/**
 demo of Speech Evaluation (ISE)
 **/
@interface ISEViewController : UIViewController

@property (nonatomic, strong) ISEParams *iseParams;

@property (nonatomic, strong) NSString *read_content;

@property (nonatomic, strong) WKWebView *webView;

@end
