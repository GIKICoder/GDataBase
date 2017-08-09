//
//  SQLiteReserveModel.m
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "SQLiteReserveModel.h"

@implementation SQLiteReserveModel
GDATABASE_IMPLEMENTATION_INJECT(SQLiteReserveModel)

- (NSArray<NSString *> *)g_GetCustomPrimarykey
{
    return @[@"index"];
}

@end
