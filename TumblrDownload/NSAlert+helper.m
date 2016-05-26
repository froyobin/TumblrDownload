//
//  NSAlert+helper.m
//  TumblrDownload
//
//  Created by zxd on 16/5/26.
//
//

#import "NSAlert+helper.h"


@implementation NSAlert (helper)

+ (NSModalResponse)alert:(NSString *)message
{
    NSAlert *alert = [NSAlert new];
    alert.alertStyle = NSInformationalAlertStyle;
    alert.messageText = message;
    return [alert runModal];
}

@end
