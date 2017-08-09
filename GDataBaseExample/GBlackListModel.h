//
//  GBlackListModel.h
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataObjectProtocol.h"
@interface GBlackListModel : NSObject<GDataObjectProtocol>

@property (nonatomic, copy) NSString* dataID ;

@property (nonatomic, copy) NSString * name;

@property (nonatomic, strong) NSArray * blackField1;
@property (nonatomic, assign) BOOL  blackField2;
@property (nonatomic, copy  ) NSString * blackField3;
@end
