//
//  GDataBaseUtils.m
//  GDataBase
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "GDataBaseUtils.h"

@implementation GDataBaseUtils

static const char GEncodingTable[64]
= "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short GDecodingTable[256] = {
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2,  -1,  -1, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62,  -2,  -2, -2, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2,  -2,  -2, -2, -2,
    -2, 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10,  11,  12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2,  -2,  -2, -2, -2,
    -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36,  37,  38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,  -2,  -2, -2, -2
};

+ (NSString *)base64EncodedString:(NSString*)original
{
    NSData *data = [original dataUsingEncoding:NSUTF8StringEncoding];
    return [GDataBaseUtils getbase64EncodedStringWithData:data];
}

+ (NSString *)base64DecodedString:(NSString *)base64EncodedString
{
    NSData *data = [GDataBaseUtils dataWithBase64EncodedString:base64EncodedString];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (NSString *)getbase64EncodedStringWithData:(NSData *)data
{
    NSUInteger length = data.length;
    if (length == 0)
        return @"";
    
    NSUInteger out_length = ((length + 2) / 3) * 4;
    uint8_t *output = malloc(((out_length + 2) / 3) * 4);
    if (output == NULL)
        return nil;
    
    const char *input = data.bytes;
    NSInteger i, value;
    for (i = 0; i < length; i += 3) {
        value = 0;
        for (NSInteger j = i; j < i + 3; j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        NSInteger index = (i / 3) * 4;
        output[index + 0] = GEncodingTable[(value >> 18) & 0x3F];
        output[index + 1] = GEncodingTable[(value >> 12) & 0x3F];
        output[index + 2] = ((i + 1) < length)
        ? GEncodingTable[(value >> 6) & 0x3F]
        : '=';
        output[index + 3] = ((i + 2) < length)
        ? GEncodingTable[(value >> 0) & 0x3F]
        : '=';
    }
    
    NSString *base64 = [[NSString alloc] initWithBytes:output
                                                length:out_length
                                              encoding:NSASCIIStringEncoding];
    free(output);
    return base64;
}

+ (NSData *)dataWithBase64EncodedString:(NSString *)base64EncodedString
{
    NSInteger length = base64EncodedString.length;
    const char *string = [base64EncodedString cStringUsingEncoding:NSASCIIStringEncoding];
    if (string  == NULL)
        return nil;
    
    while (length > 0 && string[length - 1] == '=')
        length--;
    
    NSInteger outputLength = length * 3 / 4;
    NSMutableData *data = [NSMutableData dataWithLength:outputLength];
    if (data == nil)
        return nil;
    if (length == 0)
        return data;
    
    uint8_t *output = data.mutableBytes;
    NSInteger inputPoint = 0;
    NSInteger outputPoint = 0;
    while (inputPoint < length) {
        char i0 = string[inputPoint++];
        char i1 = string[inputPoint++];
        char i2 = inputPoint < length ? string[inputPoint++] : 'A';
        char i3 = inputPoint < length ? string[inputPoint++] : 'A';
        
        output[outputPoint++] = (GDecodingTable[i0] << 2)
        | (GDecodingTable[i1] >> 4);
        if (outputPoint < outputLength) {
            output[outputPoint++] = ((GDecodingTable[i1] & 0xf) << 4)
            | (GDecodingTable[i2] >> 2);
        }
        if (outputPoint < outputLength) {
            output[outputPoint++] = ((GDecodingTable[i2] & 0x3) << 6)
            | GDecodingTable[i3];
        }
    }
    
    return data;
}

+ (BOOL)isEmpty:(NSString *)string
{
    
    
    if (!string) {
        return YES;
    } else {
        if (![string isKindOfClass:[NSString class]]) {
            return NO;
        }
        //A character set containing only the whitespace characters space (U+0020) and tab (U+0009) and the newline and nextline characters (U+000A–U+000D, U+0085).
        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        //Returns a new string made by removing from both ends of the receiver characters contained in a given character set.
        NSString *trimedString = [string stringByTrimmingCharactersInSet:set];
        
        if ([trimedString length] == 0) {
            return YES;
        } else {
            return NO;
        }
    }
}

/**
 获取sqlite 保留字段集合
 
 @return NSDictionary
 */
/**
 获取sqlite 保留字段集合
 
 @return NSDictionary
 */
+ (NSArray * )getSQLiteReservedWords
{
    return @[@"ABORT" ,
             @"ACTION"  ,
             @"ADD"   ,
             @"AFTER" ,
             @"ALL"  ,
             @"ALTER"  ,
             @"ANALYZE"  ,
             @"AND"  ,
             @"AS",
             @"ASC" ,
             @"ATTACH" ,
             @"AUTOINCREMENT" ,
             @"BEFORE"   ,
             @"BEGIN"  ,
             @"BETWEEN"  ,
             @"BY"   ,
             @"CASCADE" ,
             @"CASE"    ,
             @"CAST"     ,
             @"CHECK"     ,
             @"COLLATE"     ,
             @"COLUMN"     ,
             @"COMMIT"     ,
             @"CONFLICT"     ,
             @"CONSTRAINT"     ,
             @"CREATE"     ,
             @"CROSS"     ,
             @"CURRENT_DATE"     ,
             @"CURRENT_TIME"     ,
             @"CURRENT_TIMESTAMP"     ,
             @"DATABASE"     ,
             @"DEFAULT"     ,
             @"DEFERRABLE"     ,
             @"DEFERRED"     ,
             @"DELETE"     ,
             @"DESC"     ,
             @"DETACH"     ,
             @"DISTINCT"     ,
             @"DROP"     ,
             @"EACH"     ,
             @"ELSE"     ,
             @"END"     ,
             @"ESCAPE"     ,
             @"EXCEPT"     ,
             @"EXCLUSIVE"     ,
             @"EXISTS"     ,
             @"EXPLAIN"     ,
             @"FAIL"     ,
             @"FOR"     ,
             @"FOREIGN"     ,
             @"FROM"     ,
             @"FULL"     ,
             @"GLOB"     ,
             @"GROUP"     ,
             @"HAVING"     ,
             @"IF"     ,
             @"IGNORE"     ,
             @"IMMEDIATE"     ,
             @"IN"     ,
             @"INDEX"     ,
             @"INDEXED"     ,
             @"INITIALLY"     ,
             @"INNER"     ,
             @"INSERT"     ,
             @"INSTEAD"     ,
             @"INTERSECT"     ,
             @"INTO"     ,
             @"IS"     ,
             @"ISNULL"     ,
             @"JOIN"     ,
             @"KEY"     ,
             @"LEFT"     ,
             @"LIKE"     ,
             @"LIMIT"     ,
             @"MATCH"     ,
             @"NATURAL"     ,
             @"NO"     ,
             @"NOT"     ,
             @"NOTNULL"     ,
             @"NULL"     ,
             @"OF"     ,
             @"OFFSET"     ,
             @"ON"     ,
             @"OR"     ,
             @"ORDER"     ,
             @"OUTER"     ,
             @"PLAN"     ,
             @"PRAGMA"     ,
             @"PRIMARY"     ,
             @"QUERY"     ,
             @"RAISE"     ,
             @"RECURSIVE"     ,
             @"REFERENCES"     ,
             @"REGEXP"     ,
             @"REINDEX"     ,
             @"RELEASE"     ,
             @"RENAME"     ,
             @"REPLACE"     ,
             @"RESTRICT"     ,
             @"RIGHT"     ,
             @"TO"    ,
             @"ROLLBACK"    ,
             @"SAVEPOINT"    ,
             @"SELECT"    ,
             @"SET"    ,
             @"TABLE"    ,
             @"TEMP"    ,
             @"TEMPORARY"    ,
             @"THEN",
             @"TRANSACTION",
             @"TRIGGER",
             @"UNION" ,
             @"UNIQUE",
             @"UPDATE",
             @"USING",
             @"VACUUM",
             @"VALUES",
             @"VIEW",
             @"VIRTUAL" ,
             @"WHEN" ,
             @"WHERE",
             @"WITH",
             @"WITHOU",];
}

@end
