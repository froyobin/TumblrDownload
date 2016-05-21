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
@property (nonatomic) int errorCount;
@property (nonatomic) int successCount;

+ (instancetype)sharedInstance;

- (void)resetCounter;
- (void)addURLtoDownloadQueue:(NSString *)url filename:(NSString *)filename relativePath:(NSString *)relativePath;

@end
