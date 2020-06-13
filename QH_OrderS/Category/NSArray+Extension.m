//
//  NSArray+Extension.m
//  ICUnicodeDemo
//
//  Created by wenwang wang on 2020/1/1.
//  Copyright (c) 2015年 andy . All rights reserved.
//

#import "NSArray+Extension.h"
#import "NSDictionary+Extension.h"

@implementation NSArray (Extension)

- (NSString *)description {
    return [self formatArray:self formatString:nil];
}
- (NSString *)formatArray:(NSArray *)array formatString:(NSString *)formatString {
    NSMutableString *string = [NSMutableString string];
    if (formatString == nil||formatString.length == 0) {
        formatString = @"\t";
        [string appendString:@"[\n"];
    }else {
        [string appendString:@"\t[\n"];
    }
    for (int i = 0; i<array.count; i++) {
        id value = array[i];
        NSString *arrayFormatString = [NSString stringWithFormat:@"%@%@",formatString,formatString];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [string appendFormat:@"%@%@\n",formatString,[value formatDictionary:value formatString:arrayFormatString]];
        }else if ([value isKindOfClass:[NSArray class]]) {
            [string appendFormat:@"%@%@\n",formatString,[self formatArray:value formatString:arrayFormatString]];
        }else{
            [string appendFormat:@"%@%@,\n",formatString,value];
        }
    }
    [string appendFormat:@"%@]",[formatString substringFromIndex:1]];
    return string;
}
@end
