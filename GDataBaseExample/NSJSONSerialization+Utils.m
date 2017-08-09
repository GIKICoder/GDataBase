//
//  NSJSONSerialization+Utils.m
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import "NSJSONSerialization+Utils.h"

@implementation NSJSONSerialization (Utils)
+ (id)JSONObjectWithContentsOfFile:(NSString*)fileName
{
    return [self JSONObjectWithContentsOfFile:fileName inBundle:[NSBundle mainBundle]];
}

+ (id)JSONObjectWithContentsOfFile:(NSString*)fileName inBundle:(NSBundle *)bundle
{
    NSString *filePath = [bundle pathForResource:[fileName stringByDeletingPathExtension]
                                          ofType:[fileName pathExtension]];
    
    NSAssert(filePath, @"JSONFile: File not found");
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    NSError *error = nil;
    
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingMutableContainers
                                                  error:&error];
    
    if (error) NSLog(@"JSONFile error: %@", error);
    
    if (error != nil) return nil;
    
    return result;
}
@end
