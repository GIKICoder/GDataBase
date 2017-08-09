//
//  GTableA.h
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataObjectProtocol.h"
#import "YYModel.h"

@interface GSubTableA : NSObject
@property (nonatomic, strong) NSString *key;
@end

@interface GTableA : NSObject<GDataObjectProtocol>

@property (nonatomic, strong) NSArray * datas;
@property (nonatomic, strong) GSubTableA * subA;
@property (nonatomic, strong) id data;
@property (nonatomic, strong) NSData * realData;
@property (nonatomic, strong) NSDictionary * dict;
@property (nonatomic, strong) NSMutableArray * array;

@end
