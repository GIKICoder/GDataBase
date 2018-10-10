//
//  GAppsDataViewModel.h
//  GOACloud
//
//  Created by GIKI on 2017/7/30.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYModel.h"
#import "GDataObjectProtocol.h"
@interface GDataModel : NSObject<GDataObjectProtocol,YYModel>
@property (nonatomic, strong) NSString * ID;
@property (nonatomic, assign) NSInteger  index;
@end
@interface GAppsDataViewModel : NSObject<GDataObjectProtocol,YYModel>
@property (nonatomic, strong) NSString  *dataID;
@property (nonatomic, copy) NSString  *fields;
@property (nonatomic, assign) int  dataGroup;
@property (nonatomic, assign) NSInteger  dataIndex;
@property (nonatomic,   copy) NSString * name;
@property (nonatomic, assign) NSInteger  show;
@property (nonatomic,   copy) NSString * templateID;
@property (nonatomic, assign) long long   timestamp;
@property (nonatomic, assign) NSInteger  type;
@property (nonatomic,   copy) NSString * list;
@end


