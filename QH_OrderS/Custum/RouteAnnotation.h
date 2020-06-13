//
//  RouteAnnotation.h
//  YBDriver
//
//  Created by 王文望 on 20/1/1.
//  Copyright © 2016年 凯东源. All rights reserved.
//

@interface RouteAnnotation : BMKPointAnnotation

@property (assign, nonatomic) int type;///<0:起点 1：终点 2：公交 3：地铁 4:驾乘 5:途经点

@property (assign, nonatomic) int degree;

@property (strong, nonatomic) NSString * _Nullable abcd;

/// 地址
@property (copy, nonatomic) NSString * _Nullable address;

@end
