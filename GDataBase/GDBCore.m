//
//  GDBCore.m
//  GDataBase
//
//  Created by GIKI on 2017/8/4.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GDBCore.h"
#import "FMDB.h"
#import "GDBCoreInterface.h"
@interface GDBCore ()
{
    BOOL _isExist;
}
@end

@implementation GDBCore

- (instancetype)initWithDBPath:(NSString*)dbPath
{
    if (self = [super init]) {
        self.dbFile = dbPath;
        self.sqliteReservedWordMap = [GDataBaseUtils getSQLiteReservedWord];
        [self connect];
        self.dbQueue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
        
        NSLog(@"DBFile:%@", self.dbFile);
        
    }
    return self;
}

- (void)dealloc{
    
    [self close];
    self.dbFile = nil;
    self.dbQueue = nil;
}

#pragma mark - public Method


-(BOOL)isDbFileExist
{
    BOOL result = _isExist;
    if (_isExist) {
        _isExist = NO;
    }
    return result;
}

#pragma mark - private Method

- (void)close{
    
    [_dataBase close];
    _dataBase = nil;
}

- (void)connect{
    
    if (!_dataBase) {
        _dataBase = [FMDatabase databaseWithPath:self.dbFile];
    }
    
    if (![_dataBase open]) {
        NSAssert(NO, @"can not open db file");
    } else {
        _isExist = YES;
    }
}


#pragma mark - table check

- (void)tableCheck:(id<GDataObjectProtocol>)data_obj
{
    NSString* table_name = NSStringFromClass([data_obj class]);
    [self tableCheck:data_obj withTableName:table_name];
}

- (void)tableCheck:(id<GDataObjectProtocol>)data_obj withTableName:(NSString *)tableName
{
    
    NSString* table_name = tableName;
    NSArray*  fileds = [data_obj g_getAllProperty];
    Class objClass = [data_obj class];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        //表是否存在
        NSString* sql = [NSString stringWithFormat:@"select count(*) from sqlite_master where type='table' and name='%@'", tableName];
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:@[]];
        
        while ([rs next]) {
            if ([rs intForColumnIndex:0] == 0) {
                NSArray* property_name_array = nil;
                if ([data_obj respondsToSelector:@selector( g_GetCustomPrimarykey)]) {
                    property_name_array = [data_obj  g_GetCustomPrimarykey];
                }
                BOOL isAuto = NO;
                if (property_name_array == nil || property_name_array.count <= 0) {
                    isAuto = YES;
                }
                [self createTable:db table_name:table_name fileds:fileds isAutoPrimaryKey:isAuto primaryKey:property_name_array objClass:objClass];
                [rs close];
                return ;
            }
        }
        
        [rs close];
        
        //字段是否都存在
        sql = [NSString stringWithFormat:@"select * from %@ limit 0", tableName];
        rs = [db executeQuery:sql withArgumentsInArray:@[]];
        
        for (NSString* property_name in fileds) {
            NSString *  property = [self processReservedWord:property_name];
            if ([rs columnIndexForName:property] == -1) {
                [self insertCol:property_name db:db objClass:objClass];
            }
        }
        
        [rs close];
    }];
    
}

#pragma mark - table Create Method

- (void)createTable:(FMDatabase *)db table_name:(NSString *)table_name fileds:(NSArray *)fileds isAutoPrimaryKey:(BOOL)isAuto primaryKey:(NSArray<NSString *> *)primaryKey objClass:(Class)objClass
{
    if (isAuto) { //自增主键
        [self createTableAutoPrimaryKey:db table_name:table_name fileds:fileds objClass:objClass];
        return;
    }
    if (primaryKey.count > 1) {
        [self createTableMutablePK:db table_name:table_name fileds:fileds primaryKey:primaryKey objClass:objClass];
    } else {
        [self createTableSingleKey:db table_name:table_name fileds:fileds primaryKey:primaryKey.firstObject objClass:objClass];
    }
}


- (void)createTableAutoPrimaryKey:(FMDatabase*)db table_name:(NSString*)table_name fileds:(NSArray*)fileds objClass:(Class)objClass
{
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ ( GAUTOPRIMARYKEY integer primary key autoincrement, ", table_name ];
    
    for (NSString* property_name in fileds) {
        
        objc_property_t objProperty = class_getProperty(objClass, [property_name UTF8String]);
        NSString* property_key = @"";
        NSString * propertyname = [self processReservedWord:property_name];
        NSString *sqlType = nil;
        if ([objClass respondsToSelector:@selector(g_customArchiveList)]) {
            NSDictionary *archiveList = [objClass g_customArchiveList];
            sqlType = [archiveList objectForKey:property_name];
        }
        if (sqlType == nil) {
            sqlType =  [self getSqlKindbyProperty:objProperty];
        }
        property_key = [NSString stringWithFormat:@"%@ %@,", propertyname,sqlType];
        [sql appendString:property_key];
    }
    
    [sql deleteCharactersInRange:NSMakeRange([sql length] - 1, 1)];
    [sql appendString:@")"];
    
    [db executeUpdate:sql];
}

- (void)createTableSingleKey:(FMDatabase*)db table_name:(NSString*)table_name fileds:(NSArray*)fileds primaryKey:(NSString*)primaryKey objClass:(Class)objClass
{
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (", table_name ];
    
    for (NSString* property_name in fileds) {
        
        objc_property_t objProperty = class_getProperty(objClass, [property_name UTF8String]);
        
        NSString* property_key = nil;
        
        NSString *sqlType = nil;
        if ([objClass respondsToSelector:@selector(g_customArchiveList)]) {
            NSDictionary *archiveList = [objClass g_customArchiveList];
            sqlType = [archiveList objectForKey:property_name];
        }
        if (sqlType == nil) {
            sqlType =  [self getSqlKindbyProperty:objProperty];
        }
        
        NSString * propertyname = [self processReservedWord:property_name];
        if ([primaryKey isEqualToString:property_name]) {
            property_key = [NSString stringWithFormat:@"%@ %@ primary key,", propertyname,sqlType];
        }else{
            property_key = [NSString stringWithFormat:@"%@ %@,", propertyname, sqlType];
        }
        
        [sql appendString:property_key];
        
    }
    
    [sql deleteCharactersInRange:NSMakeRange([sql length] - 1, 1)];
    [sql appendString:@")"];
    
    [db executeUpdate:sql];
}

//CREATE TABLE STUDENTS (subjectId TEXT, studentid TEXT, studentname TEXT, constraint pk_id primary key (subjectId, studentid))
- (void)createTableMutablePK:(FMDatabase*)db table_name:(NSString*)table_name fileds:(NSArray*)fileds primaryKey:(NSArray<NSString *> *)primaryKeyArr objClass:(Class)objClass
{
    NSMutableArray *keyArr = [[NSMutableArray alloc] initWithCapacity:primaryKeyArr.count];
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (", table_name ];
    
    for (NSString* property_name in fileds) {
        
        objc_property_t objProperty = class_getProperty(objClass, [property_name UTF8String]);
        NSString* property_key = nil;
        
        NSString *sqlType = nil;
        if ([objClass respondsToSelector:@selector(g_customArchiveList)]) {
            NSDictionary *archiveList = [objClass g_customArchiveList];
            sqlType = [archiveList objectForKey:property_name];
        }
        if (sqlType == nil) {
            sqlType =  [self getSqlKindbyProperty:objProperty];
        }
        
        
        if ([primaryKeyArr containsObject:property_name]) {
            [keyArr addObject:property_name];
        }
        NSString * propertyname = [self processReservedWord:property_name];
        property_key = [NSString stringWithFormat:@"%@ %@, ", propertyname,sqlType];
        
        [sql appendString:property_key];
        
    }
    
    [sql appendFormat:@"CONSTRAINT pk_id PRIMARY KEY ("];
    
    for (NSString *key in keyArr) {
        
        NSString * keyname = [self processReservedWord:key];
        [sql appendString:keyname];
        
        if (key != keyArr.lastObject) {
            [sql appendString:@", "];
        }
    }
    
    [sql appendString:@"))"];
    
    [db executeUpdate:sql];
}


#pragma mark - insert record Method

- (NSString *)getInsertRecordQuery:(id<GDataObjectProtocol>)dataObject
{
    NSString* table_name = NSStringFromClass([dataObject class]);
    return [self getInsertRecordQuery:dataObject withTableName:table_name];
}

- (NSString *)getInsertRecordQuery:(id<GDataObjectProtocol>)dataObject withTableName:(NSString *)tableName
{
    NSObject *data_obj = dataObject;
    NSString* table_name = tableName;//
    NSArray*  fileds = [dataObject g_getAllProperty];
    Class objClass = [data_obj class];
    
    NSMutableString* query = [[NSMutableString alloc] initWithFormat:@"insert or replace into %@ (", table_name];
    NSMutableString* values = [[NSMutableString alloc] initWithString:@" ("];
    
    for (NSString* property_name in fileds) {
        
        //sqlite 关键字过滤
        NSString *  propertyname = [self processReservedWord:property_name];
        NSString* property_key  = [NSString stringWithFormat:@"%@,", propertyname];
        NSString* property_value = nil;
        
        
        NSString *sqlType = nil;
        if ([objClass respondsToSelector:@selector(g_customArchiveList)]) {
            NSDictionary *archiveList = [objClass g_customArchiveList];
            sqlType = [archiveList objectForKey:property_name];
        }
        if (sqlType) {
            if ([dataObject respondsToSelector:@selector(g_ArchiveProperty:)]) {
                id result = [dataObject g_ArchiveProperty:property_name];
                if ([result isKindOfClass:[NSString class]]) {
                    property_value = [NSString stringWithFormat:@"'%@',", [self base64Str:result]];
                } else if([result isKindOfClass:[NSData class]]){
                    property_value = [NSString stringWithFormat:@"'%@',", [self base64Data:result]];
                } else {
                    property_value = [NSString stringWithFormat:@"%@,",result];
                }
                
            }
        } else {
            
            objc_property_t property = class_getProperty([data_obj class], property_name.UTF8String);
            if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
                
                NSString* value = [data_obj valueForKey:property_name];
                
                NSString* property_sign = [self getPropertySign:property];
                if ([property_sign isEqualToString:@"@\"NSString\""] ||
                    [property_sign isEqualToString:@"@"]) {
                    if ([GDataBaseUtils isEmpty:value]) {
                        value = @"?,";
                    } else {
                        value = [ self base64Str:value];
                    }
                }
                
                property_value = [NSString stringWithFormat:@"'%@',", value ];
                
            }else{
                property_value = [NSString stringWithFormat:@"%@,", [[data_obj valueForKey:property_name] stringValue]];
            }
        }
        [query appendString:property_key];
        [values appendString:property_value];
    }
    
    [query deleteCharactersInRange:NSMakeRange([query length] - 1, 1)];
    [values deleteCharactersInRange:NSMakeRange([values length] - 1, 1)];
    
    [query appendString:@") values "];
    [values appendString:@")"];
    
    [query appendString:values];
    
    return query;
    
}

- (void)insertCol:(NSString*)colName db:(FMDatabase*)db objClass:(Class)objClass
{
    NSString* table_name = NSStringFromClass(objClass);
    

    NSString *  property = [self processReservedWord:colName];
    
    NSString *sqlType = nil;
    if ([objClass respondsToSelector:@selector(g_customArchiveList)]) {
        NSDictionary *archiveList = [objClass g_customArchiveList];
        sqlType = [archiveList objectForKey:colName];
    }
    if (sqlType == nil) {
        objc_property_t objProperty = class_getProperty(objClass, [colName UTF8String]);
        NSString* kind =  [self getSqlKindbyProperty:objProperty];
        sqlType =  kind;
    }

    NSString *sql = [NSString stringWithFormat:@"alter table %@ add %@ %@", table_name, property, sqlType];
    
    [db executeUpdate:sql];
    
}

#pragma mark - excuteSql Method

- (NSArray*)excuteSql:(NSString*)sql
{
    NSMutableArray *results = [NSMutableArray array];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql,nil];
        
        while ([rs next]) {
            
            [results addObject:[rs resultDictionary]];
        }
        
        [rs close];
    }];
    return results;
}

- (NSArray*)excuteSql:(NSString*)sql withClass:(Class)clazz
{
    NSMutableArray *models = [NSMutableArray array];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql,nil];
        
        while ([rs next]) {
            id model = [[clazz alloc] init];
            
            for (int i = 0; i < [rs columnCount]; i++) {
                //列名
                NSString *columnName = [rs columnNameForIndex:i];
                NSString *properyName = [self DeProcessReservedWord:columnName];
                objc_property_t objProperty = class_getProperty(clazz, properyName.UTF8String);
                //如果属性不存在，则不操作
                if (objProperty) {
                    if(![rs columnIndexIsNull:i]) {
                        [self setProperty:model value:rs columnName:properyName property:objProperty];
                    }
                }
                // 自增主键
                if ([columnName isEqualToString:GAUTOPRIMARYKEY]) {
                    NSNumber *number = [rs objectForColumn:columnName];
                    [model setValue:@(number.longValue) forKey:columnName];
                }
            }
            
            [models addObject:model];
        }
        
        [rs close];
    }];
    return models;
}

#pragma mark - Delete SQL format Method

- (NSString *)formatDeleteSQLWithObjc:(id<GDataObjectProtocol>)data_obj withTableName:(NSString*)tableName
{
    NSAssert(data_obj, @"参数不完整");
    
    NSMutableString *query = nil;
    
    if (data_obj) {
        
        NSString* table_name = tableName;
        NSArray* property_name_array = nil;
        if ([data_obj respondsToSelector:@selector( g_GetCustomPrimarykey)]) {
            property_name_array = [data_obj  g_GetCustomPrimarykey];
        } else {
            property_name_array = @[GAUTOPRIMARYKEY];
        }
        if (property_name_array == nil || property_name_array.count<= 0) {
            NSAssert(property_name_array, @"can't find primaryKey");
        }
        
        NSString* condition = nil;
        
        if (property_name_array.count > 1) {
            condition = [self formatMutableConditionSQLWithObjc:data_obj pkArr:property_name_array];
        } else {
            condition = [self formatSingleConditionSQLWithObjc:data_obj property_name:property_name_array.firstObject];
        }
        
        query = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@ WHERE %@", table_name, condition];
    }
    
    return query;
}

- (NSString *)formatSingleConditionSQLWithObjc:(id<GDataObjectProtocol>)data_obj property_name:(NSString *)property_name
{
    NSObject *OBJECT = data_obj;
    NSString* condition = nil;
    if ([property_name isEqualToString:GAUTOPRIMARYKEY]) {
        NSNumber* autoPrimarykey = [OBJECT valueForKey:GAUTOPRIMARYKEY];
        if (autoPrimarykey) {
            if ([autoPrimarykey respondsToSelector:@selector(stringValue)]) {
                condition = [NSString stringWithFormat:@"%@ = '%@',", property_name, [autoPrimarykey stringValue]];
            }
        }
    } else {
        objc_property_t property = class_getProperty([data_obj class], property_name.UTF8String);
        NSString *proName = [self processReservedWord:property_name];
        if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
            
            NSString* value = [NSString stringWithFormat:@"%@" , [OBJECT valueForKey:property_name]];
            NSString* property_sign = [self getPropertySign:property];
            if ([property_sign isEqualToString:@"@\"NSString\""] ||
                [property_sign isEqualToString:@"@"]) {
                value = [ self base64Str:value];
            }
            
            condition = [NSString stringWithFormat:@"%@ = '%@',", proName, value];
        } else {
            condition = [NSString stringWithFormat:@"%@ = %@,", proName, [[OBJECT valueForKey:property_name] stringValue]];
        }
    }
    if ([condition hasSuffix:@","]) {
        NSMutableString *mutableString = [NSMutableString stringWithString:condition];
        [mutableString replaceCharactersInRange:NSMakeRange(mutableString.length - 1, 1) withString:@""];
        condition = mutableString;
    }
    
    return condition;
}

- (NSString *)formatMutableConditionSQLWithObjc:(id<GDataObjectProtocol>)data_obj pkArr:(NSArray *)pkArr
{
    NSMutableString *condition = [[NSMutableString alloc] init];
    NSObject *OBJECT = data_obj;
    for (NSString *property_name in pkArr) {
        objc_property_t property = class_getProperty([data_obj class], property_name.UTF8String);
        NSString *proName = [self processReservedWord:property_name];
        if ([[self getSqlKindbyProperty:property] isEqualToString:@"text"]) {
            
            NSString* value = [NSString stringWithFormat:@"%@" , [OBJECT valueForKey:property_name]];
            NSString* property_sign = [self getPropertySign:property];
            if ([property_sign isEqualToString:@"@\"NSString\""] ||
                [property_sign isEqualToString:@"@"]) {
                value = [ self base64Str:value];
            }
            [condition appendString:[NSString stringWithFormat:@"%@ = '%@'", proName, value]];
        } else {
            [condition appendString:[NSString stringWithFormat:@"%@ = %@", proName, [[OBJECT valueForKey:property_name] stringValue]]];
        }
        
        if (NO == [property_name isEqual:pkArr.lastObject]) {
            [condition appendString:@" AND "];
        }
    }
    
    return condition;
}


- (NSString*)getPropertySign:(objc_property_t)property
{
    return [[[[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
}

//    @"f":@"float",
//    @"i":@"int",
//    @"d":@"double",
//    @"l":@"long",
//    @"c":@"BOOL",
//    @"s":@"short",
//    @"q":@"long",
//    @"I":@"NSInteger",
//    @"Q":@"NSUInteger",
//    @"B":@"BOOL",
//    @"@":@"id"
- (NSString*)getSqlKindbyProperty:(objc_property_t)property
{
    NSString *firstType = [self getPropertySign:property];
    
    if ([firstType isEqualToString:@"f"]) {
        return @"real";
    } else if([firstType isEqualToString:@"i"]){
        return @"integer";
    } else if([firstType isEqualToString:@"d"]){
        return @"real";
    } else if([firstType isEqualToString:@"l"] || [firstType isEqualToString:@"q"]){
        return @"real";
    } else if([firstType isEqualToString:@"c"] || [firstType isEqualToString:@"B"]){
        return @"bool";
    } else if([firstType isEqualToString:@"s"]){
        return @"integer";
    } else if([firstType isEqualToString:@"I"]){
        return @"integer";
    } else if([firstType isEqualToString:@"Q"]){
        return @"integer";
    } else if([firstType isEqualToString:@"@\"NSData\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@\"NSDate\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@\"NSString\""]){
        return @"text";
    } else if([firstType isEqualToString:@"@"]){
        return @"text";
    }else {
        return @"text";
    }
    return nil;
}

#pragma mark - convert Model Method

- (void)setProperty:(id)model value:(FMResultSet *)rs columnName:(NSString *)columnName property:(objc_property_t)property
{
    if ([rs columnIsNull:columnName]) {
        return;
    }

    id<GDataObjectProtocol> object = model;
    Class objectClass = [object class];
    if ([objectClass respondsToSelector:@selector(g_customArchiveList)]) {
        NSDictionary *dict = [objectClass g_customArchiveList];
        NSString *sqlType = [dict objectForKey:columnName];
        if (sqlType) {
            if ([model respondsToSelector:@selector(g_UnarchiveSetData:property:)]) {
                
                id value =nil;
                if ([sqlType isEqualToString:GTEXT_TYPE]) {
                    value = [rs stringForColumn:columnName];
                    value = [self base64EncodedString:value];
                } else if([sqlType isEqualToString:GBLOB_TYPE]) {
                    value = [rs dataForColumn:columnName];
                    value = [self base64EncodedData:value];
                }
                
                [model g_UnarchiveSetData:value property:columnName];
                return;
            }
        }
    }
   
    NSString *firstType = [self getPropertySign:property];
    
    if ([firstType isEqualToString:@"f"]) {
        NSNumber *number = [rs objectForColumn:columnName];
        [model setValue:@(number.floatValue) forKey:columnName];
        
    } else if([firstType isEqualToString:@"i"]){
        NSNumber *number = [rs objectForColumn:columnName];
        [model setValue:@(number.intValue) forKey:columnName];
        
    } else if([firstType isEqualToString:@"d"]){
        [model setValue:[rs objectForColumn:columnName] forKey:columnName];
        
    } else if([firstType isEqualToString:@"l"] || [firstType isEqualToString:@"q"]){
        [model setValue:[rs objectForColumn:columnName] forKey:columnName];
        
    } else if([firstType isEqualToString:@"c"] || [firstType isEqualToString:@"B"]){
        NSNumber *number = [rs objectForColumn:columnName];
        [model setValue:@(number.boolValue) forKey:columnName];
        
    } else if([firstType isEqualToString:@"s"]){
        NSNumber *number = [rs objectForColumn:columnName];
        [model setValue:@(number.shortValue) forKey:columnName];
        
    } else if([firstType isEqualToString:@"I"]){
        NSNumber *number = [rs objectForColumn:columnName];
        [model setValue:@(number.integerValue) forKey:columnName];
        
    } else if([firstType isEqualToString:@"Q"]){
        NSNumber *number = [rs objectForColumn:columnName];
        [model setValue:@(number.unsignedIntegerValue) forKey:columnName];
        
    } else if([firstType isEqualToString:@"@\"NSData\""]){
        
        NSData* value = [self convertHexStrToData:[rs stringForColumn:columnName]];
        [model setValue:value forKey:columnName];
        
    } else if([firstType isEqualToString:@"@\"NSDate\""]){
        NSDate *value = [rs dateForColumn:columnName];
        [model setValue:value forKey:columnName];
        
    } else if([firstType isEqualToString:@"@\"NSString\""]){
        
        NSString *encodeStr = [rs stringForColumn:columnName];
        NSString *value = [self base64EncodedString:encodeStr];
        [model setValue:value forKey:columnName];
        
    }
    else if([firstType isEqualToString:@"@"]){
        id value = [rs objectForColumn:columnName];
        value = [self base64EncodedString:value];
        [model setValue:value forKey:columnName];
    }
    else {
        [model setValue:[rs objectForColumn:columnName] forKey:columnName];
    }
}

#pragma mark - help Method

- (NSData *)convertHexStrToData:(NSString *)_str {
    
    NSString* str = [_str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"<" withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    if (!str || [str length] == 0) {
        return nil;
    }
    
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:8];
    NSRange range;
    if ([str length] % 2 == 0) {
        range = NSMakeRange(0, 2);
    } else {
        range = NSMakeRange(0, 1);
    }
    for (NSInteger i = range.location; i < [str length]; i += 2) {
        unsigned int anInt;
        NSString *hexCharStr = [str substringWithRange:range];
        NSScanner *scanner = [[NSScanner alloc] initWithString:hexCharStr];
        
        [scanner scanHexInt:&anInt];
        NSData *entity = [[NSData alloc] initWithBytes:&anInt length:1];
        [hexData appendData:entity];
        
        range.location += range.length;
        range.length = 2;
    }
    
    return hexData;
}

- (NSString*)formatConditionString:(NSString*)condition
{
    __block NSString *formatString = condition;
    
    NSString *regexString1 = @"([\\w]+)\\s*=\\s*'?([\\w]+)'?";
    NSError* error1;
    NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:regexString1 options:NSRegularExpressionCaseInsensitive error:&error1];
    NSMutableArray<NSString*>* needEncode1 = [[NSMutableArray<NSString*> alloc] init];
    
    [regex1 enumerateMatchesInString:condition options:0 range:NSMakeRange(0, [condition length]) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        [needEncode1 addObject:[condition substringWithRange:[result rangeAtIndex:1]]];
    }];
    [needEncode1 enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            
            NSString* origin_str = [NSString stringWithFormat:@"%@", obj];
            NSString* replace_str = [NSString stringWithFormat:@"%@", [self processReservedWord:obj]];
            NSRange range = [formatString rangeOfString:origin_str];
            formatString = [formatString stringByReplacingCharactersInRange:range withString:replace_str];
        }
        
    }];
    
    if (!_isEncrypt) {
        return formatString;
    }
    
    NSError* error;
    NSString *regexString = @"([\\w]+)\\s*=\\s*'([\\w]+)'";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
    NSMutableArray<NSString*>* needEncode = [[NSMutableArray<NSString*> alloc] init];
    
    [regex enumerateMatchesInString:condition options:0 range:NSMakeRange(0, [condition length]) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        [needEncode addObject:[condition substringWithRange:[result rangeAtIndex:1]]];
        [needEncode addObject:[condition substringWithRange:[result rangeAtIndex:2]]];
    }];
    
    
    [needEncode enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            
        } else if(idx == 1) {
            NSString* origin_str = [NSString stringWithFormat:@"'%@'", obj];
            NSString* replace_str = [NSString stringWithFormat:@"'%@'", [self base64Str:obj]];
            formatString = [formatString stringByReplacingOccurrencesOfString:origin_str withString:replace_str];
        }
        
    }];
    return formatString;
}

- (NSString*)removeLastOneChar:(NSString*)origin
{
    NSString* cutted;
    if([origin length] > 0){
        cutted = [origin substringToIndex:([origin length]-1)];// 去掉最后一个","
    }else{
        cutted = origin;
    }
    return cutted;
}

- (NSString *)base64Str:(NSString*)str
{
    if (_isEncrypt) {
        return [GDataBaseUtils base64EncodedString:str];
    }
    return str;
}

- (NSString*)base64Data:(NSData*)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)base64EncodedData:(NSData*)data
{
    return data;
}

- (NSString *)base64EncodedString:(NSString *)base64Str
{
    if (_isEncrypt) {
        return [GDataBaseUtils base64DecodedString:base64Str];
    }
    return base64Str;
}

- (NSString*)processReservedWord:(NSString*)property_key
{
    NSString *str = property_key;
    if ([self.sqliteReservedWordMap objectForKey:[str uppercaseString]]) {
        str = [NSString stringWithFormat:@"[%@]",property_key];
    }
    return str;
}

- (NSString*)DeProcessReservedWord:(NSString*)property_key
{
    NSString *str = property_key;
    if ([self.sqliteReservedWordMap objectForKey:[str uppercaseString]]) {
        if ([str hasPrefix:@"["] && [str hasSuffix:@"]"]) {
            str = [str stringByReplacingOccurrencesOfString:@"[" withString:@""];
            str = [str stringByReplacingOccurrencesOfString:@"]" withString:@""];
        }
    }
    return str;
}
@end
