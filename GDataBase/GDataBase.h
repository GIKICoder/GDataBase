//
//  GDataBase.h
//  GDataBase
//
//  Created by GIKI on 2017/8/4.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDBCore.h"
#import "GDataObjectProtocol.h"

@interface GDataBase : GDBCore

/**
 构造方法

 @param dbPath 如果没有文件会默认创建xx.db 文件
        isBase64Encode 是否开启对字符串进行base64编码,默认开启
 @return GDataBase实例
 */
+ (instancetype)databaseWithPath:(NSString *)dbPath;
+ (instancetype)databaseWithPath:(NSString *)dbPath isBase64Encode:(BOOL)isEncode;

/**
 往数据库中增加一条数据<不开启事务>
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名
 @param obj <需要遵守GDataObjectProtocol>
 @return YES/NO
 */
- (BOOL)addObject:(id<GDataObjectProtocol>)obj;
- (BOOL)addObject:(id<GDataObjectProtocol>)obj WithTableName:(NSString*)tableName;

/**
 往数据库中增加一组数据<不开启事务>
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名
 @param objs <数组中模型需要遵守GDataObjectProtocol>
 @return YES/NO
 */
- (BOOL)addObjects:(NSArray*)objs;
- (BOOL)addObjects:(NSArray*)objs WithTableName:(NSString*)tableName;

/**
 往数据库中增加一组数据,开始事务.

 @param objs objs <数组中模型需要遵守GDataObjectProtocol>
 @param tableName 数据表名,传nil则默认表明为类名
 @return YES/NO
 */
- (BOOL)addObjectsInTransaction:(NSArray*)objs WithTableName:(NSString*)tableName;

/**
 从数据库中删除一条(组)数据
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名

 @param obj <需要遵守GDataObjectProtocol>
 @return YES/NO
 */
- (BOOL)deleteObject:(id<GDataObjectProtocol>)obj;
- (BOOL)deleteObject:(id<GDataObjectProtocol>)obj withTableName:(NSString *)tableName;
- (BOOL)deleteObjects:(NSArray<id<GDataObjectProtocol>>*)objs;
- (BOOL)deleteObjects:(NSArray<id<GDataObjectProtocol>>*)objs withTableName:(NSString*)tableName;


/**
 更新数据
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名.
 @param clazz 需要更新的模型Class
 @param keyValues 需要更新的字段键值对 <key:属性名 value:需要更新的值>
 @param predicateFormat 格式化查询条件.
 @example:[...xxxcond:@"dataID = '%@ AND id=%d'",dataID, id]
 @return YES/NO
 */
- (BOOL)updateObjectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues cond:(NSString *)predicateFormat,...;
- (BOOL)updateTableName:(NSString*)tableName objectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues cond:(NSString *)predicateFormat,...;

/**
 获取数据表中的全部数据
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名.
 @param clazz 需要查询的模型Class
 @return class表的全部数据
 */
- (NSArray*)getAllObjectsWithClass:(Class)clazz;
- (NSArray*)getAllObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName;

/**
 根据condition获取数据表中符合条件的数据
 @breif:使用第一种或者不传tableName 则默认使用类名作为表名.
 @param clazz 需要查询的模型Class
 @param predicateFormat 格式化查询条件.
        orderName 排序的propertyName 降序 需要在propertyName后拼接 'desc'
        limit 传0无限制.
        CustomCond:默认不拼接'where',condition 自定义 "where dataID='AAA' order by dataID limit 10"
 @example:[...xxxcond:@"dataID = '%@ AND id=%d'",dataID, id]
 @return 数据表中符合条件的所有数据集合
 */
- (NSArray *)getObjectsWithClass:(Class)clazz whereCond:(NSString *)predicateFormat, ...;
- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName whereCond:(NSString *)predicateFormat, ...;
- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName CustomCond:(NSString *)predicateFormat, ...;
- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName orderBy:(NSString*)orderName limit:(NSInteger)count cond:(NSString *)predicateFormat, ...;

/**
 根据condition 获取数据表中符合条件的数据集合,直接返回字典数据

 @param tableName 表名
 @param predicateFormat 查询条件.如果传'nil'查询全部
 @return 返回字典数组.
 */
- (NSArray *)getResultDictionaryWithTableName:(NSString*)tableName CustomCond:(NSString *)predicateFormat, ...;

/**
 根据condition获取数据表中数据的个数
 @breif:不传tableName 则默认使用类名作为表名.
 @param clazz 需要查询的模型Class
 @param predicateFormat 格式化查询条件.
 @example:[...xxxcond:@"dataID = '%@ AND id=%d'",dataID, 12]
 @return 数据表中符合条件的数据的个数
 */
- (long)countInDataBaseWithClass:(Class)clazz withTableName:(NSString*)tableName cond:(NSString*)predicateFormat, ...;

/**
 删除数据表

 @param clazz 如果表名为class 可使用第一种
 @return YES/NO
 */
- (BOOL)removeTableWithClass:(Class)clazz;
- (BOOL)removeTable:(NSString*)table_name;

#pragma mark - condition Method

- (GDataBase * (^)(Class))selectClazz;
- (GDataBase * (^)(NSString*))selectTableName;
- (GDataBase * (^)(NSString*))whereProperty;
- (GDataBase * (^)(NSString*))andProperty;
- (GDataBase * (^)(id))equal;
- (GDataBase * (^)(NSInteger))equalMore;
- (GDataBase * (^)(NSInteger))equalLess;
- (GDataBase * (^)(NSInteger))more;
- (GDataBase * (^)(NSInteger))less;
- (GDataBase * (^)(NSString *property,BOOL asc))orderby;
- (GDataBase * (^)(NSInteger))limit;
- (NSArray * (^)(Class))queryObjectsWithClass;

- (instancetype)selectClazz:(Class)clazz;
- (instancetype)selectTableName:(NSString*)tableName;
- (instancetype)whereProperty:(NSString*)propertyName;
- (instancetype)andProperty:(NSString*)propertyName;
- (instancetype)equal:(id)value;
- (instancetype)equalMore:(NSInteger)value;
- (instancetype)equalLess:(NSInteger)value;
- (instancetype)more:(NSInteger)value;
- (instancetype)less:(NSInteger)value;
- (instancetype)orderby:(NSString*)propertyName asc:(BOOL)asc;
- (instancetype)limit:(NSInteger)count;
- (NSArray*)queryObjectsWithClazz:(Class)clazz;


@end
