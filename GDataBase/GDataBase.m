//
//  GDataBase.m
//  GDataBase
//
//  Created by GIKI on 2017/8/4.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GDataBase.h"
#import "FMDB.h"
#import <objc/runtime.h>
#import "GDBCoreInterface.h"

@interface GDataBase()
@property(nonatomic, strong) NSMutableArray*  obj_array;
@property (nonatomic, strong) NSString  *sqlCondition;

@end

@implementation GDataBase

+ (instancetype)databaseWithPath:(NSString *)dbPath
{
    return [GDataBase databaseWithPath:dbPath isBase64Encode:YES];
}

+ (instancetype)databaseWithPath:(NSString *)dbPath isBase64Encode:(BOOL)isEncode
{
    GDataBase *database = [[GDataBase alloc] initWithDBPath:dbPath];
    database.isEncode = isEncode;
    return database;
}

#pragma mark - public Method

- (BOOL)addObject:(id<GDataObjectProtocol>)obj
{
    return [self addObject:obj WithTableName:NSStringFromClass([obj class])];
}

- (BOOL)addObjects:(NSArray *)objs
{
    if (!objs || objs.count <= 0) {
        return NO;
    }
    [self tableCheck:objs[0]];
    __block NSMutableArray *array = [NSMutableArray array];
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        for (NSObject* obj in objs) {
            NSString * query = [self getInsertRecordQuery:(id<GDataObjectProtocol>)obj];
            BOOL isSuccess = [db executeUpdate:query,nil];
            if (!isSuccess) {
                [array addObject:obj];
            }
        }
    }];
    
    return !(array.count >0);
}

- (BOOL)addObject:(id<GDataObjectProtocol>)obj WithTableName:(NSString*)tableName
{
    if (!obj) {
        return NO;
    }
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass([obj class]);
    }
    [self tableCheck:obj];
    
    __block BOOL isSuccess = NO;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString * query = [self getInsertRecordQuery:(id<GDataObjectProtocol>)obj withTableName:tableName];
        isSuccess = [db executeUpdate:query,nil];
    }];
    return isSuccess;
}

- (BOOL)addObjects:(NSArray*)objs WithTableName:(NSString*)tableName
{
    if (!objs || objs.count <= 0) {
        return NO;
    }
    
    [self tableCheck:objs[0]];
    __block NSMutableArray *array = [NSMutableArray array];
    __block NSString *sheetName = tableName;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        for (NSObject* obj in objs) {
            if (!sheetName || [sheetName isEqualToString:@""]) {
                sheetName = NSStringFromClass([obj class]);
            }
            NSString * query = [self getInsertRecordQuery:(id<GDataObjectProtocol>)obj withTableName:sheetName];
            BOOL isSuccess = [db executeUpdate:query,nil];
            if (!isSuccess) {
                [array addObject:obj];
            }
        }
    }];
    
    return !(array.count >0);
}

- (BOOL)addObjectsInTransaction:(NSArray *)objs WithTableName:(NSString *)tableName
{
    if (!objs || objs.count <= 0) {
        return NO;
    }
    
    [self tableCheck:objs[0]];
    __block NSMutableArray *array = [NSMutableArray array];
    __block NSString *sheetName = tableName;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (id<GDataObjectProtocol> obj in objs) {
            if (!sheetName || [sheetName isEqualToString:@""]) {
                sheetName = NSStringFromClass([obj class]);
            }
            NSString * query = [self getInsertRecordQuery:(id<GDataObjectProtocol>)obj withTableName:sheetName];
            BOOL isSuccess = [db executeUpdate:query,nil];
            if (!isSuccess) {
                [array addObject:obj];
                *rollback = YES;
            }
        }
    }];
    return !(array.count > 0);
}

/**
 修改数据
 */
- (BOOL)updateObjectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues cond:(NSString *)predicateFormat,...
{
    if (keyValues.allValues.count <= 0 || !keyValues) {
        return NO;
    }
    va_list arglist;
    va_start(arglist, predicateFormat);
    NSString *tableName = NSStringFromClass(clazz);
    return [self updateTableName:tableName objectClazz:clazz keyValues:keyValues cond:predicateFormat,arglist];
}

- (BOOL)updateTableName:(NSString*)tableName objectClazz:(Class)clazz keyValues:(NSDictionary *)keyValues cond:(NSString *)predicateFormat,...
{
    if (keyValues.allValues.count <= 0 || !keyValues) {
        return NO;
    }
    
    __block NSString* sql = [NSString stringWithFormat:@"UPDATE %s SET", [tableName UTF8String]];
    [keyValues enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        objc_property_t property = class_getProperty(clazz, key.UTF8String);
        NSString *property_value = @"";
        if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
            
            NSString* value = [NSString stringWithFormat:@"%@" , obj];
            NSString* property_sign = [self getPropertySign:property];
            if ([property_sign isEqualToString:@"@\"NSString\""] ||
                [property_sign isEqualToString:@"@"]) {
                value = [ self base64Str:value];
            }
            
            property_value = [NSString stringWithFormat:@"'%@'", value];;
        }else{
            property_value = [NSString stringWithFormat:@"%@", [obj stringValue]];
        }
        NSString *keyName = [self processReservedWord:key];
        sql = [NSString stringWithFormat:@"%@ %@=%@,",sql,keyName,property_value];
    }];
    // 删除最后一个逗号
    sql = [self removeLastOneChar:sql];
    
    va_list arglist;
    
    if (predicateFormat) {
        va_start(arglist, predicateFormat);
        NSString *condition = [[NSString alloc] initWithFormat:predicateFormat arguments:arglist];
        sql = [NSString stringWithFormat:@"%@ WHERE %@",sql,[self formatConditionString:condition]];
    }
    
    __block BOOL sucess = NO;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        sucess = [db executeUpdate:sql,nil];
    }];
    return sucess;
}

/// 获取数据表中的全部数据
- (NSArray*)getAllObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName
{
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    NSString* sql = [NSString stringWithFormat:@"select * from %s", [tableName UTF8String]];
    return [self excuteSql:sql  withClass:clazz];
}

- (NSArray*)getAllObjectsWithClass:(Class)clazz
{
    NSString* tableName = NSStringFromClass(clazz);
    return [self getAllObjectsWithClass:clazz withTableName:tableName];
}

/// 根据condition获取数据表中符合条件的数据
- (NSArray *)getObjectsWithClass:(Class)clazz whereCond:(NSString *)format,...
{
    va_list args;
    va_start(args, format);
    NSString *condition = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSString *tableName = NSStringFromClass(clazz);
    NSString* sql = [NSString stringWithFormat:@"select * from %s where ", [tableName UTF8String]];
    sql = [sql stringByAppendingString:[self formatConditionString:condition]];
    
    return [self excuteSql:sql withClass:clazz];
}


- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName whereCond:(NSString *)format,...
{
    
    va_list args;
    va_start(args, format);
    NSString *condition = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    NSString* sql = [NSString stringWithFormat:@"select * from %s where ", [tableName UTF8String]];
    sql = [sql stringByAppendingString:[self formatConditionString:condition]];
    
    return [self excuteSql:sql withClass:clazz];
}

- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName CustomCond:(NSString *)predicateFormat, ...
{
    va_list args;
    va_start(args, predicateFormat);
    NSString *condition = [[NSString alloc] initWithFormat:predicateFormat arguments:args];
    va_end(args);
    
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    NSString* sql = [NSString stringWithFormat:@"select * from %s ", [tableName UTF8String]];
    sql = [sql stringByAppendingString:[self formatConditionString:condition]];
    
    return [self excuteSql:sql withClass:clazz];
}

- (NSArray *)getObjectsWithClass:(Class)clazz withTableName:(NSString*)tableName orderBy:(NSString*)orderName limit:(NSInteger)count cond:(NSString *)predicateFormat,...
{
    NSString *condition = @"";
    if (predicateFormat) {
        va_list arglist;
        va_start(arglist, predicateFormat);
        condition = [[NSString alloc] initWithFormat:predicateFormat arguments:arglist];
    }
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    NSString* sql = [NSString stringWithFormat:@"select * from %s ", [tableName UTF8String]];
    
    
    sql = [NSString stringWithFormat:@"%@ %@",sql,[self formatConditionString:condition]];
    
    if (orderName || orderName.length > 0) {
        sql = [NSString stringWithFormat:@"%@ order by %@",sql,orderName];
    }
    
    if (count > 0) {
        sql = [NSString stringWithFormat:@"%@ limit %ld",sql,count];
    }
    
    return [self excuteSql:sql withClass:clazz];
}

- (NSArray *)getResultDictionaryWithTableName:(NSString*)tableName CustomCond:(NSString *)predicateFormat, ...
{
    NSString *condition = @"";
    if (predicateFormat) {
        va_list arglist;
        va_start(arglist, predicateFormat);
        condition = [[NSString alloc] initWithFormat:predicateFormat arguments:arglist];
    }
     NSString* sql = [NSString stringWithFormat:@"select * from %s ", [tableName UTF8String]];
    return [self excuteSql:sql];
}

- (long)countInDataBaseWithClass:(Class)clazz withTableName:(NSString*)tableName cond:(NSString*)predicateFormat, ...
{
    NSString* condition = nil;
    if (predicateFormat) {
        va_list arglist;
        va_start(arglist, predicateFormat);
        condition = [[NSString alloc] initWithFormat:predicateFormat arguments:arglist];
    }
    
    if (!tableName || [tableName isEqualToString:@""]) {
        tableName = NSStringFromClass(clazz);
    }
    __block long count = 0;
    NSString* sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %s ", [tableName UTF8String]];
    
    if (condition) {
        sql = [NSString stringWithFormat:@"%@ WHERE %@",sql,condition];
    }
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        count = [db longForQuery:sql];
    }];
    
    return count;
}

- (BOOL)deleteObject:(id<GDataObjectProtocol>)obj withTableName:(NSString *)tableName
{
    if (obj) {
        if (!tableName || [tableName isEqualToString:@""]) {
            tableName = NSStringFromClass([obj class]);
        }
        NSString *query = [self formatDeleteSQLWithObjc:obj withTableName:tableName];
        
        __block BOOL isSuccess = NO;
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            isSuccess = [db executeUpdate:query,nil];
        }];
        
        return isSuccess;
    }
    
    return NO;
    
}

- (BOOL)deleteObject:(id<GDataObjectProtocol>)obj
{
    if (!obj) {
        return NO;
    }
    NSString *tableName = NSStringFromClass([obj class]);
    return [self deleteObject:obj withTableName:tableName];
}

- (BOOL)deleteObjects:(NSArray<id<GDataObjectProtocol>>*)objs withTableName:(NSString*)tableName
{
    __block BOOL isSuccess = NO;
    [self.dbQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        __block NSString* sheetName = tableName;
        [objs enumerateObjectsUsingBlock:^(id<GDataObjectProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!sheetName || [sheetName isEqualToString:@""]) {
                sheetName = NSStringFromClass([obj class]);
            }
            NSString *query = [self formatDeleteSQLWithObjc:obj withTableName:sheetName];
            isSuccess = [db executeUpdate:query,nil];
            if (!isSuccess) {
                *rollback = YES;
            }
        }];
    }];
    return isSuccess;
}

- (BOOL)deleteObjects:(NSArray<id<GDataObjectProtocol>>*)objs
{
    return [self deleteObjects:objs withTableName:nil];
}

- (BOOL)removeTableWithClass:(Class)clazz
{
    NSString* sheet_name = NSStringFromClass(clazz);
    return [self removeTable:sheet_name];
}

- (BOOL)removeTable:(NSString*)table_name
{
    __block BOOL tf = NO;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [@"DROP TABLE " stringByAppendingString:table_name];
        tf = [db executeUpdate:sql,nil];
    }];
    
    return tf;
}

#pragma mark - condition Method

- (instancetype)selectClazz:(Class)clazz
{
    NSString *tableName = NSStringFromClass(clazz);
    self.sqlCondition = [NSString stringWithFormat:@"select * from %s",[tableName UTF8String]];
    return self;
}

- (instancetype)selectTableName:(NSString*)tableName
{
    self.sqlCondition = [NSString stringWithFormat:@"select * from %s",[tableName UTF8String]];
    return self;
}

- (instancetype)whereProperty:(NSString*)propertyName
{
    NSString *keyName = [self processReservedWord:propertyName];
    self.sqlCondition = [NSString stringWithFormat:@"%@ where %@",self.sqlCondition,keyName];
    return self;
}

- (instancetype)andProperty:(NSString*)propertyName
{
    NSString *keyName = [self processReservedWord:propertyName];
    
    self.sqlCondition = [NSString stringWithFormat:@"%@ and %@",self.sqlCondition,keyName];
    return self;
}

- (instancetype)equal:(id)value
{
    if ([value isKindOfClass:[NSString class]]) {
        self.sqlCondition = [NSString stringWithFormat:@"%@='%@'",self.sqlCondition,[self base64Str:value]];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        NSInteger intValue = [(NSNumber *)value integerValue];
        self.sqlCondition = [NSString stringWithFormat:@"%@=%ld",self.sqlCondition,intValue];
        
    } else {
        NSInteger intValue = (NSInteger)value;
        self.sqlCondition = [NSString stringWithFormat:@"%@=%ld",self.sqlCondition,intValue];
    }
    
    return self;
}

- (instancetype)equalMore:(NSInteger)value
{
    self.sqlCondition = [NSString stringWithFormat:@"%@>=%ld",self.sqlCondition,value];
    return self;
}

- (instancetype)equalLess:(NSInteger)value
{
    self.sqlCondition = [NSString stringWithFormat:@"%@<=%ld",self.sqlCondition,value];
    return self;
}

- (instancetype)more:(NSInteger)value
{
    self.sqlCondition = [NSString stringWithFormat:@"%@>%ld",self.sqlCondition,value];
    return self;
}

- (instancetype)less:(NSInteger)value
{
    self.sqlCondition = [NSString stringWithFormat:@"%@<%ld",self.sqlCondition,value];
    return self;
}

- (instancetype)orderby:(NSString*)propertyName asc:(BOOL)asc
{
    NSString *orderCond = asc ? @"ASC" : @"DESC";
    self.sqlCondition = [NSString stringWithFormat:@"%@ order by %@ %@",self.sqlCondition,propertyName,orderCond];
    
    return self;
}

- (instancetype)limit:(NSInteger)count
{
    self.sqlCondition = [NSString stringWithFormat:@"%@ limit %ld",self.sqlCondition,(long)count];
    return self;
}

- (NSArray*)queryObjectsWithClazz:(Class)clazz
{
    NSError *error;
    [self.dataBase validateSQL:self.sqlCondition error:&error];
    if (error) {
        NSAssert(!error, @"SQLCondition is not validatesql -- %@",self.sqlCondition);
    }
    return [self excuteSql:self.sqlCondition withClass:clazz];
}

- (GDataBase * (^)(Class))selectClazz
{
    return ^id(Class clazz){
        return [self selectClazz:clazz];
    };
}

- (GDataBase * (^)(NSString*))selectTableName
{
    return ^id(NSString* clazz){
        return [self selectTableName:clazz];
    };
}

- (GDataBase * (^)(NSString*))whereProperty
{
    return ^id(NSString* Property){
        return [self whereProperty:Property];
    };
}

- (GDataBase * (^)(NSString*))andProperty
{
    return ^id(NSString* Property){
        return [self andProperty:Property];
    };
}

- (GDataBase * (^)(id))equal
{
    return ^id(id value){
        return [self equal:value];
    };
}

- (GDataBase * (^)(NSInteger))equalMore
{
    return ^id(NSInteger value){
        return [self equalMore:value];
    };
}

- (GDataBase * (^)(NSInteger))equalLess
{
    return ^id(NSInteger value){
        return [self equalLess:value];
    };
}

- (GDataBase * (^)(NSInteger))more
{
    return ^id(NSInteger value){
        return [self more:value];
    };
}

- (GDataBase * (^)(NSInteger))less
{
    return ^id(NSInteger value){
        return [self less:value];
    };
}

- (GDataBase * (^)(NSString *property,BOOL asc))orderby
{
    return ^id(NSString *property,BOOL asc){
        return [self orderby:property asc:asc];
    };
}
- (GDataBase * (^)(NSInteger))limit
{
    return ^id(NSInteger value){
        return [self limit:value];
    };
}

- (NSArray * (^)(Class))queryObjectsWithClass
{
    return ^id(Class clazz){
        return [self queryObjectsWithClazz:clazz];
    };
}
@end
