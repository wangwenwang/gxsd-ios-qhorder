//
//  NSDictionary+toString.m
//  wms-ios
//
//  Created by wenwang wang on 2020/1/1.
//  Copyright © 2018年 wenwang wang. All rights reserved.
//

#import "NSDictionary+toString.h"

@implementation NSDictionary (toString)

- (NSString *)descriptionWithLocale:(id)locale {
    
    NSArray *allKeys = [self allKeys];
    
    NSMutableString *str = [[NSMutableString alloc] initWithFormat:@"{\n "];
    
    int i = 0;
    for (NSString *key in allKeys) {
        
        id value= self[key];
        
        [str appendFormat:@"\t \"%@\" : ",key];
        
        // 字典和数组的value不加""
        if([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            [str appendFormat:@"%@",value];
        } else {
            [str appendFormat:@"\"%@\"",value];
        }
        
        // 不是最后一个value加,
        if(i != allKeys.count - 1) {
            [str appendString:@","];
        }
        [str appendString:@"\n"];
        
        i++;
    }
    
    [str appendString:@"}"];
    
    return str;
}

- (NSString *)toString {
    
    NSString *jsonString = @"";
    if ([NSJSONSerialization isValidJSONObject:self]){
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
        jsonString =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}

@end
