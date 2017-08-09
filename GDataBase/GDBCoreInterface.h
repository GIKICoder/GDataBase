//
//  GDBCoreInterface.h
//  GDataBase
//
//  Created by GIKI on 2017/8/5.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataObjectProtocol.h"
#import "GDataBaseUtils.h"
@class FMDatabaseQueue,FMDatabase;
@interface GDBCore ()
@property (nonatomic, strong, readonly) FMDatabase * dataBase;
@property (nonatomic, copy  ) NSString * dbFile;
@property (nonatomic, strong) FMDatabaseQueue * dbQueue;
/// 是否开启base64加密,默认不开启
@property (nonatomic, assign) BOOL  isEncrypt;
@property (nonatomic, strong) NSDictionary * sqliteReservedWordMap;

- (instancetype)initWithDBPath:(NSString*)dbPath;

- (BOOL)isDbFileExist;

#pragma mark - table check

- (void)tableCheck:(id<GDataObjectProtocol>)dataObject;
- (void)tableCheck:(id<GDataObjectProtocol>)dataObject withTableName:(NSString *)tableName;

#pragma mark - table Create Method

- (void)createTable:(FMDatabase *)db table_name:(NSString *)table_name fileds:(NSArray *)fileds isAutoPrimaryKey:(BOOL)isAuto primaryKey:(NSArray<NSString *> *)primaryKey objClass:(Class)objClass;
- (void)createTableSingleKey:(FMDatabase*)db table_name:(NSString*)table_name fileds:(NSArray*)fileds primaryKey:(NSString*)primaryKey objClass:(Class)objClass;
- (void)createTableMutablePK:(FMDatabase*)db table_name:(NSString*)table_name fileds:(NSArray*)fileds primaryKey:(NSArray<NSString *> *)primaryKeyArr objClass:(Class)objClass;

#pragma mark - insert record Method

- (NSString *)getInsertRecordQuery:(id<GDataObjectProtocol>)dataObject;
- (NSString *)getInsertRecordQuery:(id<GDataObjectProtocol>)dataObject withTableName:(NSString *)tableName;
- (void)insertCol:(NSString*)colName db:(FMDatabase*)db objClass:(Class)objClass;

#pragma mark - excuteSql Method

- (NSArray*)excuteSql:(NSString*)sql;
- (NSArray*)excuteSql:(NSString*)sql withClass:(Class)clazz;

#pragma mark - SQL format Method

- (NSString *)formatDeleteSQLWithObjc:(id<GDataObjectProtocol>)data_obj withTableName:(NSString*)tableName;
- (NSString *)formatSingleConditionSQLWithObjc:(id<GDataObjectProtocol>)data_obj property_name:(NSString *)property_name;
- (NSString *)formatMutableConditionSQLWithObjc:(id<GDataObjectProtocol>)data_obj pkArr:(NSArray *)pkArr;
- (NSString*)getPropertySign:(objc_property_t)property;
- (NSString*)getSqlKindbyProperty:(objc_property_t)property;

#pragma mark - convert Model Method

- (void)setProperty:(id)model value:(FMResultSet *)rs columnName:(NSString *)columnName property:(objc_property_t)property;

#pragma mark - help Method

- (NSData *)convertHexStrToData:(NSString *)_str;
- (NSString*)formatConditionString:(NSString*)condition;
- (NSString*)removeLastOneChar:(NSString*)origin;
- (NSString *)base64Str:(NSString*)str;
- (NSString *)base64EncodedString:(NSString *)base64Str;
/// 处理和解码sqlite 保留字段
- (NSString*)processReservedWord:(NSString*)property_key;
- (NSString*)DeProcessReservedWord:(NSString*)property_key;
@end
