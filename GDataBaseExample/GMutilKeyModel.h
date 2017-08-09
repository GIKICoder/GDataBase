//
//  GMutilKeyModel.h
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataObjectProtocol.h"
/// 多主建
@interface GMutilKeyModel : NSObject<GDataObjectProtocol>

@property (nonatomic, copy  ) NSString * primaryKey1;
@property (nonatomic, copy  ) NSString * primaryKey3;
@property (nonatomic, assign) int  primaryKey2;
@property (nonatomic, strong) NSString * other;
@end
