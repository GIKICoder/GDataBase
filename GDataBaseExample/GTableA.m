//
//  GTableA.m
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GTableA.h"

@implementation GSubTableA



@end

@implementation GTableA
GDATABASE_IMPLEMENTATION_INJECT(GTableA)


- (id)g_ArchiveProperty:(NSString*)property_name
{
    if ([property_name isEqualToString:@"datas"]) {
        NSData *data = [self.datas yy_modelToJSONData];
        return data;
    }
    return nil;
}

- (void)g_UnarchiveSetData:(id)data property:(NSString*)property_name
{
    if ([property_name isEqualToString:@"datas"]) {
        NSError *eror = nil;
        NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&eror];
        self.datas = [NSArray yy_modelArrayWithClass:[GSubTableA class] json:array];
    }
    
}

+ (NSDictionary<NSString *,NSString*> *)g_customArchiveList
{
    return @{
             @"datas" : GBLOB_TYPE,
             @"data"  : GBLOB_TYPE,
             };
}

@end
