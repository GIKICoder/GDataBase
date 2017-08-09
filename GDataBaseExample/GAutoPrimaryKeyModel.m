//
//  GAutoPrimaryKeyModel.m
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/8.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GAutoPrimaryKeyModel.h"

@implementation GAutoPrimaryKeyModel
GDATABASE_IMPLEMENTATION_INJECT(GAutoPrimaryKeyModel)

- (void)g_setValue:(id)value forUndefinedKey:(NSString *)key
{
 
}
@end
