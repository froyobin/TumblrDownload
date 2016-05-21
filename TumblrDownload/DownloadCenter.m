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
        NSError *error;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        } else {
            NSString *destinationPath = relativePath.length ? [_saveLocation stringByAppendingPathComponent:relativePath] :_saveLocation;
            
            [[NSFileManager defaultManager] createDirectoryAtPath:destinationPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error != nil) {
                NSLog(@"error creating directory: %@", error);
                
            } else {
                NSString *destinationFilePath = filename.length ? [[destinationPath stringByAppendingPathComponent:filename.urlEncode] stringByAppendingPathExtension:urlStr.pathExtension]  : [destinationPath stringByAppendingPathComponent:urlStr.lastPathComponent];
                
                BOOL succeed = [data writeToFile:destinationFilePath options:NSDataWritingAtomic error:&error];
                if (!succeed) {
                    NSLog(@"save file %@ failed : %@", destinationFilePath, error.localizedDescription);
                }
            }
        }
    }];
    [self.downloadQueue addOperation:downloadOperation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.downloadQueue && [change[NSKeyValueChangeNewKey] integerValue] == 0) {
        NSLog(@"Download finished");
    }
}

@end
