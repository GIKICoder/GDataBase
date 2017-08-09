//
//  GDataBaseUtils.h
//  GDataBase
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GDataBaseUtils : NSObject

/**
 获取sqlite 保留字段集合
 
 @return NSDictionary
 */
+ (NSDictionary *)getSQLiteReservedWord;

/**
 base64 加密

 @param original 加密字符串
 @return 加密后字符串
 */
+ (NSString *)base64EncodedString:(NSString*)original;

+ (NSString *)getbase64EncodedStringWithData:(NSData *)data;

/**
 base64 解密

 @param base64EncodedString base64 字符串
 @return 解密后字符串
 */
+ (NSString *)base64DecodedString:(NSString *)base64EncodedString;

/**
 字符串是否为空,或者为空字符串

 @return YES/NO
 */
+ (BOOL)isEmpty:(NSString *)string;

@end
