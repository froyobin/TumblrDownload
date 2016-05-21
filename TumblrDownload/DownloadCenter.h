//
//  DownloadCenter.h
//  TumblrDownload
//
//  Created by zxd on 16/5/21.
//
//

#import <Foundation/Foundation.h>

@interface DownloadCenter : NSObject

@property (nonatomic, copy) NSString *saveLocation;

+ (instancetype)sharedInstance;

- (void)addURLtoDownloadQueue:(NSString *)url filename:(NSString *)filename relativePath:(NSString *)relativePath;

@end
