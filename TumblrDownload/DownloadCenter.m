//
//  DownloadCenter.m
//  TumblrDownload
//
//  Created by zxd on 16/5/21.
//
//

#import "DownloadCenter.h"
#import "NSString+URLEncode.h"

static DownloadCenter *_instance;

@interface DownloadCenter ()

@property (nonatomic) NSOperationQueue *downloadQueue;

@end

@implementation DownloadCenter

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [DownloadCenter new];
    });
    return _instance;
}

- (NSOperationQueue *)downloadQueue
{
    if (!_downloadQueue) {
        _downloadQueue = [[NSOperationQueue alloc]init];
        _downloadQueue.name = @"download queue";
        _downloadQueue.maxConcurrentOperationCount = 5;
        [_downloadQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _downloadQueue;
}

- (void)addURLtoDownloadQueue:(NSString *)urlStr filename:(NSString *)filename relativePath:(NSString *)relativePath
{
    NSBlockOperation *downloadOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSURL *url = [NSURL URLWithString:urlStr];
        
        NSString *destinationPath = relativePath.length ? [_saveLocation stringByAppendingPathComponent:relativePath] :_saveLocation;
        NSString *destinationFilePath = filename.length ? [[destinationPath stringByAppendingPathComponent:filename.urlEncode] stringByAppendingPathExtension:urlStr.pathExtension]  : [destinationPath stringByAppendingPathComponent:urlStr.lastPathComponent];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFilePath]) {
            self.successCount++;
            return;
        }
        NSError *error;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
        if (error) {
//            NSLog(@"error downloading %@ to %@/%@ %@", url, relativePath, filename, error.localizedDescription);
            self.errorCount++;
        } else {
            [[NSFileManager defaultManager] createDirectoryAtPath:destinationPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error != nil) {
                NSLog(@"error creating directory: %@", error);
                self.errorCount++;
                
            } else {
                BOOL succeed = [data writeToFile:destinationFilePath options:NSDataWritingAtomic error:&error];
                if (!succeed) {
                    NSLog(@"save file %@ failed : %@", destinationFilePath, error.localizedDescription);
                    destinationFilePath = [destinationPath stringByAppendingPathComponent:urlStr.lastPathComponent];
                    NSLog(@"Trying to save to %@", destinationFilePath);
                    succeed = [data writeToFile:destinationFilePath options:NSDataWritingAtomic error:&error];
                    if (succeed) {
                        NSLog(@".....and succeeded.");
                        self.successCount++;
                    } else {
                        NSLog(@".....still failed.");
                        self.errorCount++;
                    }
                } else {
                    self.successCount++;
                }
                
            }
        }
    }];
    [self.downloadQueue addOperation:downloadOperation];
}

- (void)resetCounter
{
    self.errorCount = 0;
    self.successCount = 0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.downloadQueue && [change[NSKeyValueChangeNewKey] integerValue] == 0) {
        NSLog(@"Download finished error = %i success = %i", self.errorCount, self.successCount);
    }
}

@end
