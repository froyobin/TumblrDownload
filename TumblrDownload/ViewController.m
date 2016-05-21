//
//  ViewController.m
//  TumblrDownload
//
//  Created by zxd on 16/5/20.
//
//

#import "ViewController.h"
#import <TMTumblrSDK/TMAPIClient.h>
#import "DownloadCenter.h"

#define kKEY_PATH @"save path"
#define kKEY_API_KEY @"API key"
#define kKEY_BLOG_NAME @"blog name"


@interface ViewController () <NSTextDelegate>

@property (strong) IBOutlet NSTextField *apiKey;
@property (strong) IBOutlet NSTextView *logOutput;
@property (strong) IBOutlet NSTextField *savePath;
@property (strong) IBOutlet NSTextField *blogName;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *api = [[NSUserDefaults standardUserDefaults] stringForKey:kKEY_API_KEY];
    api ? self.apiKey.stringValue = api : nil;
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:kKEY_PATH];
    path ? self.savePath.stringValue = path : nil;
    NSString *blog = [[NSUserDefaults standardUserDefaults] stringForKey:kKEY_BLOG_NAME];
    blog ? self.blogName.stringValue = blog : nil;
}

- (IBAction)clickSelectSavePath:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    
    if ([openPanel runModal] == NSModalResponseOK) {
        NSString *path = openPanel.URL.path;
        self.savePath.stringValue = path;
        path ? [[NSUserDefaults standardUserDefaults] setValue:path forKey:kKEY_PATH] : nil;
    }
}

- (IBAction)clickDownload:(id)sender {
    NSString *api = self.apiKey.stringValue;
    NSString *blog = self.blogName.stringValue;
    NSAssert(api.length && blog.length, @"warn user later");

    [[NSUserDefaults standardUserDefaults] setValue:api forKey:kKEY_API_KEY];
    [[NSUserDefaults standardUserDefaults] setValue:blog forKey:kKEY_BLOG_NAME];
    
    [TMAPIClient sharedInstance].OAuthConsumerKey = api;
    NSString *fullBlog = [NSString stringWithFormat:@"%@.tumblr.com", self.blogName.stringValue];
    
    [self downloadLikesFromBlog:fullBlog];
}

- (void)downloadLikesFromBlog:(NSString *)fullBlog
{
    [[TMAPIClient sharedInstance] likes:fullBlog
                             parameters:@{@"limit" : @"5", @"before" : @"1444630196"}
                               callback:^(NSDictionary *result, NSError *error) {
                                   if (error) {
                                       return;
                                   }
                                   [DownloadCenter sharedInstance].saveLocation = self.savePath.stringValue;
                                   [self downloadPostsIn:result];
                            }];
}

- (void)downloadPostsIn:(NSDictionary *)response
{
    NSNumber *likedCount = [response valueForKey:@"liked_count"];
    NSArray *posts = [response valueForKey:@"liked_posts"];
    [self logMessageToScreen:[NSString stringWithFormat:@"returned posts: %lu", posts.count]];
    for (NSDictionary *post in posts) {
        [self downloadPost:post];
    }
}

- (NSString *)downloadPost:(NSDictionary *)post
{
    NSMutableString *postSummary = [NSMutableString new];
    [postSummary appendFormat:@"%@ posted %@ liked %@ %@ %@", post[@"type"], post[@"timestamp"], post[@"liked_timestamp"], post[@"post_url"], [self postTitle:post]];

    if ([post[@"type"] isEqualToString:@"video"]) {
        NSString *videoURL = post[@"video_url"];
        [[DownloadCenter sharedInstance] addURLtoDownloadQueue:videoURL filename:[self postTitle:post] relativePath:nil];
        
    } else if ([post[@"type"] isEqualToString:@"photo"]) {
        NSArray *allPhotos = post[@"photos"];
        
        if (allPhotos.count == 1) {
            
            NSString *photoURL = [[allPhotos firstObject] valueForKeyPath:@"original_size.url"];
            [[DownloadCenter sharedInstance] addURLtoDownloadQueue:photoURL filename:[self postTitle:post] relativePath:nil];
            
        } else {
            [postSummary appendFormat:@" count %lu", allPhotos.count];
            for (NSDictionary *singlePhoto in allPhotos) {
                NSString *photoURL = [singlePhoto valueForKeyPath:@"original_size.url"];
                [[DownloadCenter sharedInstance] addURLtoDownloadQueue:photoURL filename:nil relativePath:[self postTitle:post]];
            }
        }
    }
    
    [self logMessageToScreen:postSummary];
    
    return [NSString stringWithFormat:@"%@", post[@"liked_timestamp"]];
}

- (NSString *)postTitle:(NSDictionary *)post
{
    NSString *content = post[@"content"];
    NSString *summary = post[@"summary"];
    NSString *postID = [NSString stringWithFormat:@"%@", post[@"id"]];
    if (content.length == 0 && summary.length == 0) {
        return postID;
    }
    return content.length > summary.length ? content : summary;
}

- (void)logMessageToScreen:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAttributedString* attr = [[NSAttributedString alloc] initWithString:[message stringByAppendingString:@"\n"]];
        
        [[self.logOutput textStorage] appendAttributedString:attr];
        [self.logOutput scrollRangeToVisible:NSMakeRange([[_logOutput string] length], 0)];
    });
}

#pragma mark delegate

@end
