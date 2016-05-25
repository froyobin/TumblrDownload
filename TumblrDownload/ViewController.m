//
//  ViewController.m
//  TumblrDownload
//
//  Created by zxd on 16/5/20.
//
//

#define MAS_SHORTHAND

#import "ViewController.h"
#import <TMTumblrSDK/TMAPIClient.h>
#import "Masonry.h"
#import "DownloadCenter.h"
#import "NSLabel.h"

#define kKEY_PATH @"save path"
#define kKEY_API_KEY @"API key"
#define kKEY_BLOG_NAME @"blog name"
#define kDEFAULT_POSTS_TO_DOWNLOAD @20
#define kKEY_DEFAULT_OFFSET 10.0f
#define defaultOffset with.offset(kKEY_DEFAULT_OFFSET)


@interface ViewController () <NSTextDelegate>

@property (strong) IBOutlet NSTextField *apiKey;
@property (strong) IBOutlet NSTextView *logOutput;
@property (strong) IBOutlet NSTextField *savePath;
@property (strong) IBOutlet NSTextField *blogName;
@property (nonatomic) NSUInteger totalPosts;

@property (nonatomic) NSMutableDictionary<NSString *, NSNumber *> *postsToUnlike;

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

- (IBAction)clickUnlike:(id)sender {

    if (![self readOAuthTokenFromUser]) {
        return;
    }
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"Select posts records to unlike"];
    
    if ([openPanel runModal] == NSModalResponseOK) {
        NSString *filePath = openPanel.URL.path;
        [self readUnlikePostsFromFile:filePath];
        [self unlikeNextPost];
    }
}

- (BOOL)readOAuthTokenFromUser
{
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Input OAuth token";
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSView *view = [[NSView alloc]initWithFrame:NSMakeRect(0, 0, 560, 100)];
    
    NSLabel *consumerSecretLabel = [[NSLabel alloc]init];
    consumerSecretLabel.stringValue = @"Consumer Secret";
    NSTextField *consumerSecret = [[NSTextField alloc]init];
    
    NSLabel *tokenLabel = [[NSLabel alloc]init];
    tokenLabel.stringValue = @"Token";
    NSTextField *token = [[NSTextField alloc]init];
    
    NSLabel *tokenSecretLabel = [[NSLabel alloc]init];
    tokenSecretLabel.stringValue = @"Token Secret";
    NSTextField *tokenSecret = [[NSTextField alloc]init];
    [view addSubview:consumerSecretLabel];
    [view addSubview:consumerSecret];
    [view addSubview:tokenLabel];
    [view addSubview:token];
    [view addSubview:tokenSecretLabel];
    [view addSubview:tokenSecret];
    [consumerSecretLabel makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(view.left).defaultOffset;
        make.top.equalTo(view.top).defaultOffset;
    }];
    [consumerSecret makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(consumerSecretLabel.right).defaultOffset;
        make.centerY.equalTo(consumerSecretLabel);
        make.right.equalTo(view.right).with.offset(-kKEY_DEFAULT_OFFSET);
    }];
    [tokenLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(consumerSecretLabel.bottom).defaultOffset;
        make.left.equalTo(view.left).defaultOffset;
    }];
    [token makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(consumerSecret);
        make.centerY.equalTo(tokenLabel);
        make.right.equalTo(view.right).with.offset(-kKEY_DEFAULT_OFFSET);
    }];
    [tokenSecretLabel makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tokenLabel.bottom).defaultOffset;
        make.left.equalTo(view.left).defaultOffset;
    }];
    [tokenSecret makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(token);
        make.centerY.equalTo(tokenSecretLabel);
        make.right.equalTo(view.right).with.offset(-kKEY_DEFAULT_OFFSET);
    }];
    alert.accessoryView = view;
    
    consumerSecret.stringValue = [TMAPIClient sharedInstance].OAuthConsumerSecret ?: @"";
    token.stringValue = [TMAPIClient sharedInstance].OAuthToken ?: @"";
    tokenSecret.stringValue = [TMAPIClient sharedInstance].OAuthTokenSecret ?: @"";
    
    NSModalResponse selectedButton = [alert runModal];
    
    if (selectedButton == NSAlertFirstButtonReturn) {
        [TMAPIClient sharedInstance].OAuthConsumerSecret = consumerSecret.stringValue;
        [TMAPIClient sharedInstance].OAuthToken = token.stringValue;
        [TMAPIClient sharedInstance].OAuthTokenSecret = tokenSecret.stringValue;
        return YES;
    }
    return NO;
}

- (void)readUnlikePostsFromFile:(NSString *)filePath
{
    self.postsToUnlike = [NSMutableDictionary new];
    
    NSError *error;
    NSString *contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        NSArray *substrings = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \n"]];
        NSAssert(substrings.count % 2 == 0, @"Make sure there is always one reblog key with one id");
        for (int i=0; i<substrings.count; i+=2) {
            [self.postsToUnlike setObject:[NSNumber numberWithLong:[substrings[i+1] longLongValue]] forKey:substrings[i]];
        }
    }
}

- (void)unlikeNextPost
{
    if (self.postsToUnlike.count == 0) {
        NSLog(@"No more to unlike");
        return;
    }
    NSString *reblog_key = [[self.postsToUnlike allKeys] firstObject];
    NSNumber *blog_id = [self.postsToUnlike objectForKey:reblog_key];
    [self.postsToUnlike removeObjectForKey:reblog_key];
    [[TMAPIClient sharedInstance] unlike:blog_id.stringValue
                               reblogKey:reblog_key
                                callback:^(id result, NSError *error) {
                                    if (error) {
                                        NSLog(@"%@", error.localizedDescription);
                                    }
                                    [self unlikeNextPost];
                                }];
}

- (void)downloadLikesFromBlog:(NSString *)fullBlog
{
    [DownloadCenter sharedInstance].saveLocation = self.savePath.stringValue;
    [[DownloadCenter sharedInstance] resetCounter];
    self.totalPosts = 0;
    [self downloadPostsFromBlog:fullBlog atOffset:@0 count:@1 callBack:^(id timeStamp) {
        if (timeStamp) {
            [self recursivelyDownloadPostsFromBlog:fullBlog before:timeStamp count:kDEFAULT_POSTS_TO_DOWNLOAD];
        }
    }];
    
}

- (void)downloadPostsFromBlog:(NSString *)fullBlog atOffset:(NSNumber *)offset count:(NSNumber *)count callBack:(void(^)(id timeStamp))callback
{
    [[TMAPIClient sharedInstance] likes:fullBlog
                             parameters:@{@"limit" : count, @"offset" : offset}
                               callback:^(NSDictionary *result, NSError *error) {
                                   if (error) {
                                       return;
                                   }
                                   id timeStamp = [self downloadPostsIn:result];
                                   if (callback) {
                                       callback(timeStamp);
                                   }
                               }];
}

- (void)recursivelyDownloadPostsFromBlog:(NSString *)fullBlog before:(NSNumber *)timestamp count:(NSNumber *)count
{
    [[TMAPIClient sharedInstance] likes:fullBlog
                             parameters:@{@"limit" : count, @"before" : timestamp}
                               callback:^(NSDictionary *result, NSError *error) {
                                   if (error) {
                                       return;
                                   }
                                   id newtimeStamp = [self downloadPostsIn:result];
                                   if (newtimeStamp) {
                                       [self recursivelyDownloadPostsFromBlog:fullBlog before:newtimeStamp count:kDEFAULT_POSTS_TO_DOWNLOAD];
                                   }
                               }];
}

- (id)downloadPostsIn:(NSDictionary *)response
{
    NSArray *posts = [response valueForKey:@"liked_posts"];
    
    id lastPostLikedTime = nil;
    for (NSDictionary *post in posts) {
        lastPostLikedTime = [self downloadPost:post];
    }
    
    self.totalPosts += posts.count;
    return lastPostLikedTime;
}

- (id)downloadPost:(NSDictionary *)post
{
    NSMutableString *postSummary = [NSMutableString new];
    [postSummary appendFormat:@"%@ %@", post[@"reblog_key"], post[@"id"]];

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
    
    return post[@"liked_timestamp"];
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
