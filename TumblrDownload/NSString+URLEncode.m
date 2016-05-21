//
//  NSString+URLEncode.m
//  TumblrDownload
//
//  Created by zxd on 16/5/21.
//
//

#import "NSString+URLEncode.h"

@implementation NSString (URLEncode)

- (NSString *)urlEncode
{
    //Not the fancy way because unicode
    return [[[[self stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"] stringByReplacingOccurrencesOfString:@"@" withString:@"%40"] stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"] stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
    
}

@end
