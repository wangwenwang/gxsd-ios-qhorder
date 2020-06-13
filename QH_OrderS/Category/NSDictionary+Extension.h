//
//  NSDictionary+Extension.h
//  ICUnicodeDemo
//
//  Created by 王文望 on 20/1/1.
//  Copyright (c) 2015年 andy . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Extension)

@property (strong, nonatomic) NSString * _Nullable abcd;

- (NSString *)formatDictionary:(NSDictionary *)dict formatString:(NSString *)formatString;
@end
