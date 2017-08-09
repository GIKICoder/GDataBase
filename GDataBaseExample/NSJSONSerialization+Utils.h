//
//  NSJSONSerialization+Utils.h
//  GDataBaseExample
//
//  Created by GIKI on 2017/8/7.
//  Copyright © 2017年 GIKI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSJSONSerialization (Utils)
+ (id)JSONObjectWithContentsOfFile:(NSString*)fileName inBundle:(NSBundle *)bundle;

+ (id)JSONObjectWithContentsOfFile:(NSString*)fileName;
@end
