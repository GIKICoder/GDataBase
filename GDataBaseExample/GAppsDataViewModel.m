//
//  GAppsDataViewModel.m
//  GOACloud
//
//  Created by GIKI on 2017/7/30.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GAppsDataViewModel.h"
@implementation GDataModel
GDATABASE_IMPLEMENTATION_INJECT(GDataModel)
@end
@implementation GAppsDataViewModel
GDATABASE_IMPLEMENTATION_INJECT(GAppsDataViewModel)

//- (NSArray<NSString *> *)g_GetCustomPrimarykey
//{
//    return @[@"dataID"];
//}


+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper
{
    return @{
             @"dataID" :@"id",
             @"dataGroup" : @"group",
             @"dataIndex" :@"index",
             @"templateID" : @"template",
             };
}

@end
