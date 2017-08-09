//
//  GMutilKeyModel.m
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GMutilKeyModel.h"

@implementation GMutilKeyModel
GDATABASE_IMPLEMENTATION_INJECT(GMutilKeyModel)

- (NSArray<NSString *> *)g_GetCustomPrimarykey
{
    return @[@"primaryKey1",@"primaryKey2",@"primaryKey3"];
}
@end
