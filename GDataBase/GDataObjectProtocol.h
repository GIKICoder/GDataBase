//
//  GDataObjectProtocol.h
//  GDataBase
//
//  Created by GIKI on 2017/8/4.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


@protocol GDataObjectProtocol <NSObject>

/// ORM 存储数据库ORM模型可使用sqlite 关键字. 内部已经做了处理.

@required
/**
 获取属性列表
 @breif: 如果使用GDATABASE_IMPLEMENTATION_INJECT 宏.宏内已经实现.无需添加
 @return 属性列表
 */
- (NSArray*)g_getAllProperty;

@optional

/**
 自定义主键方法
 @breif: 如果使用GDATABASE_IMPLEMENTATION_INJECT 宏. 宏内已经实现.无需添加
 如果返回多个字段.会默认创建多主键表.返回一个字段会创建单主键表
 @default: 默认创建表的方式为自增主键'GAUTOPRIMARYKEY',
 @return 自定义主键列表
 */
- (NSArray<NSString *> *)g_GetCustomPrimarykey;

/**
 黑名单
 @breif: 如果模型中部分属性,无需存入数据库,在使用GDATABASE_IMPLEMENTATION_INJECT宏的情况下
 实现<+g_blackList>类方法,key为需要忽略的属性名.value可随意填写.
 如果没有使用GDATABASE_IMPLEMENTATION_INJECT宏. 可以在<-g_getAllProperty>方法中过滤相关属性.
 @return 黑名单列表
 */
- (NSDictionary<NSString *,NSString*> *)g_blackList;

/**
 自定义序列化列表
 key:为需要自定义序列化的属性名称
 value:为序列化后sql字段类型.目前支持2种. 'GTEXT_TYPE' 'GBLOB_TYPE'
 @return 自定义序列化列表
 */
+ (NSDictionary<NSString *,NSString*> *)g_customArchiveList;

/**
 在使用GDATABASE_IMPLEMENTATION_INJECT宏的情况下, 模型类中如需实现
 setValue:(id)value forUndefinedKey:(NSString *)key
 方法,请使用该方法.
 @param value <#value description#>
 @param key <#key description#>
 */
- (void)g_setValue:(id)value forUndefinedKey:(NSString *)key;

/**
 在使用GDATABASE_IMPLEMENTATION_INJECT宏的情况下, 模型类中如需额外初始化
 请实现'g_init'. 或者自定义其他构造方法.调用 '[super init]'
 */
- (void)g_init;

/**
 自定义序列化解档方法
 
 @param data 从数据库中取出的data
 @param property_name 属性名称
 */
- (void)g_UnarchiveSetData:(id)data property:(NSString*)property_name;

/**
 自定义序列化归档方法.
 
 @param property_name 属性名称
 @return 归档data
 */
- (id)g_ArchiveProperty:(NSString*)property_name;

/**
 获取当前模型自增主键,模型对外使用.
 @breif:GDATABASE_IMPLEMENTATION_INJECT宏中已经实现
 
 @return 自增主键
 */
- (long)g_getAutoPrimaryKey;

@end

/// 自增主键字段名称
#define GAUTOPRIMARYKEY @"GAUTOPRIMARYKEY"

/// 属性自定义归档支持转化sqltype字段
#define GTEXT_TYPE @"text"
#define GBLOB_TYPE @"blob"

/**
 默认方法注入宏
 @breif: 1,默认实现了一下方法
 {
 - (NSArray<NSString *> *)g_getPrimarykey;
 - (NSArray*)g_getAllProperty;
 - (void)setValue:(id)value forUndefinedKey:(NSString *)key;
 }
 2,必须在@implementation xxxClass 后,第一行注入该宏定义
 @param clazz
 @return
 */
#define GDATABASE_IMPLEMENTATION_INJECT(clazz) {\
NSMutableArray *_g_properties;\
long    _GAUTOPRIMARYKEY;\
}\
- (instancetype)init\
{\
self = [super init];\
if (self) {\
_g_properties = [NSMutableArray array];\
[self g_loadAllProperties];\
if ([self respondsToSelector:@selector(g_init)]) {\
[self g_init];\
}\
}\
return self;\
}\
- (long)g_getAutoPrimaryKey{\
return _GAUTOPRIMARYKEY;\
}\
- (NSArray*)g_getAllProperty\
{\
return _g_properties;\
}\
- (void)g_loadAllProperties\
{\
u_int count;\
objc_property_t *properties = class_copyPropertyList([self class], &count);\
NSAssert(count > 0, @"missting properties can not create table filed");\
NSMutableDictionary *defaultBlackList = [NSMutableDictionary dictionary];\
[defaultBlackList setObject:@"hash" forKey:@"hash"];\
[defaultBlackList setObject:@"superclass" forKey:@"superclass"];\
[defaultBlackList setObject:@"description" forKey:@"description"];\
[defaultBlackList setObject:@"debugDescription" forKey:@"debugDescription"];\
if ([self respondsToSelector:@selector(g_blackList)]) {\
NSDictionary *dict = [self g_blackList];\
[defaultBlackList setValuesForKeysWithDictionary:dict];\
}\
for (int i = 0; i < count ; i++)\
{\
const char* propertyName = property_getName(properties[i]);\
NSString *proNameStr = [NSString stringWithUTF8String: propertyName];\
if (![defaultBlackList objectForKey:proNameStr]) {\
[_g_properties addObject:proNameStr];\
}\
}\
free(properties);\
}\
- (void)setValue:(id)value forUndefinedKey:(NSString *)key\
{\
NSLog(@"ForUndefinedKey-- %@",key);\
if ([key isEqualToString:GAUTOPRIMARYKEY]) {\
_GAUTOPRIMARYKEY = [value longValue];\
}\
if ([self respondsToSelector:@selector(g_setValue:forUndefinedKey:)]) {\
[self g_setValue:value forUndefinedKey:key];\
}\
}\


