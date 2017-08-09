//
//  GBlackListModel.m
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GBlackListModel.h"

@implementation GBlackListModel
GDATABASE_IMPLEMENTATION_INJECT(GBlackListModel)

- (NSArray<NSString *> *)g_GetCustomPrimarykey
{
    return @[@"dataID"];
}

- (NSDictionary<NSString *,NSString *> *)g_blackList
{
    return @{
             @"blackField1" :@"value",
             @"blackField2" :@"value",
             @"blackField3" :@"value",
             };
}
@end
