//
//  GAutoPrimaryKeyModel.h
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/8.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataObjectProtocol.h"

@interface GAutoPrimaryKeyModel : NSObject<GDataObjectProtocol>

@property (nonatomic, strong) NSString * key;
@end
