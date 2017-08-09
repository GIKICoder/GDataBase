//
//  SQLiteReserveModel.h
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataObjectProtocol.h"
@interface SQLiteReserveModel : NSObject<GDataObjectProtocol>

@property (nonatomic, assign) NSInteger  index;
@property (nonatomic, copy  ) NSString * group;
@property (nonatomic, copy  ) NSString * add;
@property (nonatomic, copy  ) NSString * as;
@property (nonatomic, copy  ) NSString * desc;

@end
