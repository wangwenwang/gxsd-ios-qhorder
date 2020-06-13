//
//  NSArray+Extension.h
//  ICUnicodeDemo
//
//  Created by andy  on 15/8/8.
//  Copyright (c) 2015年 andy . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Extension)

@property (strong, nonatomic) NSString * _Nullable abcd;

- (NSString *)formatArray:(NSArray *)array formatString:(NSString *)formatString;
@end
