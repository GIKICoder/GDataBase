
GDataBase
==============

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/GIKICoder/GDataBase/master/LICENSE)&nbsp;
[![Build Status](https://travis-ci.org/ibireme/YYModel.svg?branch=master)](https://github.com/GIKICoder/GDataBase)&nbsp;

Features
==============
- 对于FMDB基于ORM的封装.方便项目中使用.
- 所有API基于FMDBQueue,保证线程安全.
- 由于ORM字符串拼接,执行效率会有损耗.
- 支持sqlite 保留字作为字段插入. 无需考虑模型属性命名.
- 支持多主键,单一主键,自增主键数据表创建
- 支持模型黑名单. 可以自定义部分字段不进行数据库存储操作.
- 支持模型字段自定义序列化. 
- 无需手动创建数据表.
- 无需考虑数据库字段整添,自动处理数据库升级.免去升级烦恼.
- 支持数据库表存储value base64编/解码.
- 对模型无侵入,只需遵守相关协议即可.
- 功能以及代码还在更新完善中. 后期会支持更多功能.欢迎star.或者提建议改进
- 后续会支持创建关联表,建索引等常用功能.


Usage
==============
### 主要结构

```
- GDataObjectProtocol : 所有需要操作模型需要此遵守协议
- GDataBase : 数据库操作类
```

### DB创建
```
NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
path = [path stringByAppendingString:@"GDATA.db"];    
self.database = [GDataBase databaseWithPath:path];
```
### ORM模型
```
@interface GAppsDataViewModel : NSObject<GDataObjectProtocol>
@property (nonatomic, strong) NSString  *dataID;
@property (nonatomic, copy) NSString  *fields;
@property (nonatomic, assign) int  dataGroup;
/// index,ID,group等为sqlite保留字.GDatabase中已经做过处理,可直接使用
@property (nonatomic, assign) NSInteger  index;

@property (nonatomic, strong) NSArray<GSubModel*>   *datas;

@end

@implementation GAppsDataViewModel
///在第一行注入此宏即可使用GDatabase 进行模型存储
GDATABASE_IMPLEMENTATION_INJECT(GAppsDataViewModel)

/// 以下协议方法均可不实现

/// 如不实现此方法. 数据表默认为自增主键 'GAUTOPRIMARYKEY' 
- (NSArray<NSString *> *)g_GetCustomPrimarykey
{
return @[@"dataID"];//单一主键
// return @[@"dataID",@"dataGroup"]; // 多主键
}

/// 如实现此方法. 所有key 值均不会参与数据库存储
- (NSDictionary<NSString *,NSString *> *)g_blackList
{
return @{
@"fields" :@"fields",             };
}

/// 自定义归档属性
- (id)g_ArchiveProperty:(NSString*)property_name
{
if ([property_name isEqualToString:@"datas"]) {
NSData *data = [self.datas yy_modelToJSONData];
return data;
}
return nil;
}

/// 自定义接档属性
- (void)g_UnarchiveSetData:(id)data property:(NSString*)property_name
{
if ([property_name isEqualToString:@"datas"]) {
NSError *eror = nil;
NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&eror];
self.datas = [NSArray yy_modelArrayWithClass:[GSubModel class] json:array];
}

}

/// 如需要自定义归解档的属性名称以及需要归档的sqlite 字段类型,实现此方法
+ (NSDictionary<NSString *,NSString*> *)g_customArchiveList
{
return @{
@"datas" : GBLOB_TYPE,
};
}


@end
```

### 模型存储

```
- (BOOL)addObject:(id)model;
会自动处理数据表建立,以及字段升级等问题. 无需单独创建数据表
```

```
/// 单条
- (void)insertOneRowData
{
GAppsDataViewModel * model = [[GAppsDataViewModel alloc] init];
model.dataID = @"WOSHI_dataID";
model.fields = @"1234567";
model.dataGroup = 12;
model.index = 12;
BOOL isSucess = [self.database addObject:model];
}

/// 多条插入
- (void)insertLargeDataNOInTransaction
{
BOOL isSucess =   [self.database addObjects:self.models WithTableName:nil];
}

/// 开启事务_异步线程插入
- (void)insertLargeData
{
__weak typeof(self) weakSelf = self;
dispatch_async(dispatch_get_global_queue(0, 0), ^{
BOOL isSucess =   [weakSelf.database addObjectsInTransaction:weakSelf.models WithTableName:nil];
});
}

```

### 模型读取
```
/// 获取GAppsDataViewModel全部数据
- (void)getAllData
{
NSArray * all = [self.database getAllObjectsWithClass:[GAppsDataViewModel class]];
}

/// 根据条件获取数据
- (void)querySqlData
{
NSArray *Datas = [self.database getObjectsWithClass:[GAppsDataViewModel class] withTableName:@"GAppsDataViewModel"  whereCond:@"dataID= '%@' AND dataGroup=%d",@"WOSHI_dataID",12];
}
- (void)queryOrderbylimit
{
NSString *str = @"str";
NSArray *datas = [self.database getObjectsWithClass:[GAppsDataViewModel class] withTableName:nil orderBy:@"dataID" limit:10 cond:@"dataID='%@' and dataGroup='%@'",str,str];

}

- (void)querySelectSqlData
{

NSArray *  array = [[[[[[self.database selectClazz:[GAppsDataViewModel class]]
whereProperty:@"dataID"] equal:@"WOSHI_dataID"]
orderby:@"dataID" asc:YES]
limit:10]
queryObjectsWithClazz:[GAppsDataViewModel class]];

}

```
### 模型更新

```
///字段更新
- (void)updateSqlData
{
BOOL isSucess = [self.database updateObjectClazz:[GAppsDataViewModel class] keyValues:@{@"fields":@"我被修改了"} cond:@"dataIndex = %ld and dataGroup = %ld",12,12,nil];
}

- (void)updateObject
{
NSArray *objects = [self.database getAllObjectsWithClass:[GAppsDataViewModel class]];
id object = [objects firstObject];
object.index = 10;

/********* 自增主键
long autoPri = [object g_getAutoPrimaryKey];
GAppsDataViewModel * dataModel = [GAppsDataViewModel new];
dataModel.dataID = @"WOSHI_dataID";
dataModel.fields = @"1234567";
dataModel.dataGroup = 12;
dataModel.dataIndex = 12;
[dataModel setValue:@(autoPri) forKey:GAUTOPRIMARYKEY];
*********/
[self.database addObject:objects];
}

```
### 删除操作
```
- (void)deleteObject
{
NSArray * datas = [self.database getAllObjectsWithClass:[GAutoPrimaryKeyModel class]];
BOOL isSucess = [self.database deleteObject:[datas firstObject]];
// or BOOL isSucess = [self.database deleteObjects:datas];
}

- (void)deleteTable
{
[self.database removeTableWithClass:[GAutoPrimaryKeyModel class];
//or [self.database removeTable:@"GAutoPrimaryKeyModel"];
}
```


### 数据表count查询
```
- (void)querySqlTableCount
{
long count = [self.database countInDataBaseWithClass:[GAppsDataViewModel class] withTableName:nil cond:nil];
}
```
支持
==============
-该项目最低支持 `iOS 7.0` 和 `Xcode 8.0`。

-暂不支持CocoaPods及其他安装方式.
