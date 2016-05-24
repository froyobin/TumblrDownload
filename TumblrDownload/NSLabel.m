//
//  NSLabel.m
//  TumblrDownload
//
//  Created by zxd on 16/5/24.
//
//

#import "NSLabel.h"


@implementation NSLabel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setLabelStyle];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setLabelStyle];
    }
    return self;
}

- (void)setLabelStyle
{
    [self setBezeled:NO];
    [self setDrawsBackground:NO];
    [self setEditable:NO];
    [self setSelectable:NO];
}

@end
