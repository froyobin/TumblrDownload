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
            self.errorCount++;
        } else {
            [self saveFile:data toLocation:destinationFilePath alterPath:[_saveLocation stringByAppendingPathComponent:urlStr.lastPathComponent]];
        }
    }];
    [self.downloadQueue addOperation:downloadOperation];
}

- (BOOL)saveFile:(NSData *)data toLocation:(NSString *)filePath alterPath:(NSString *)alterFilePath
{
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingLastPathComponent]
                               withIntermediateDirectories:YES
                                                attributes:nil
                                                     error:&error];
    if (error != nil) {
        NSLog(@"error creating directory: %@", error.localizedDescription);
        self.errorCount++;
        return NO;
    } else {
        BOOL succeed = [data writeToFile:filePath
                                 options:NSDataWritingWithoutOverwriting
                                   error:&error];
        if (!succeed) {
            NSLog(@"save file %@ failed : %@", filePath, error.localizedDescription);
            
            succeed = [data writeToFile:alterFilePath
                                options:NSDataWritingWithoutOverwriting
                                  error:&error];
            if (succeed) {
                NSLog(@"Trying to save to %@.....and succeeded.", alterFilePath);
                self.successCount++;
            } else {
                NSLog(@"Trying to save to %@.....still failed : %@", alterFilePath, error.localizedDescription);
                self.errorCount++;
            }
        } else {
            self.successCount++;
        }
        return succeed;
    }
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
