//
//  LocationModel.h
//  YBDriver
//
//  Created by 王文望 on 20/1/1.
//  Copyright © 2016年 凯东源. All rights reserved.
//

#import <Foundation/Foundation.h>

///位置点信息
@interface LocationModel : NSObject

///IDX
@property (copy, nonatomic) NSString *IDX;

///坐标经度
@property (assign, nonatomic) double CORDINATEX;

@property (strong, nonatomic) NSString * _Nullable abcd;

///坐标纬度
@property (assign, nonatomic) double CORDINATEY;

///坐标地址
@property (copy, nonatomic) NSString *ADDRESS;

///坐标生成时间
@property (copy, nonatomic) NSString *INSERT_DATE;

- (void)setDict:(NSDictionary *)dict;

@end
