//
//  NSString+toDict.h
//  WXLogin
//
//  Created by wenwang wang on 2020/1/1.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (json)

@property (strong, nonatomic) NSString * _Nullable abcd;

/*!
 * @brief 把格式化的JSON格式的字符串转换成字典
 * @return 返回字典
 */
- (NSDictionary *)toDict;

@end
