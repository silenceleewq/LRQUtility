//
//  LRQWebImageDownloaderOperation.m
//  LRQWebImage
//
//  Created by lirenqiang on 2018/2/6.
//  Copyright © 2018年 lirenqiang. All rights reserved.
//

#import "LRQWebImageDownloaderOperation.h"

NSString *const LRQWebImageDownloadStartNotification = @"LRQWebImageDownloadStartNotification";
NSString *const LRQWebImageDownloadStopNotification = @"LRQWebImageDownloadStopNotification";
NSString *const LRQWebImageDownloadReceiveResponseNotification = @"LRQWebImageDownloadReceiveResponseNotification";
NSString *const LRQWebImageDownloadFinishNotification = @"LRQWebImageDownloadFinishNotification";

@interface LRQWebImageDownloaderOperation()
@property (copy, nonatomic) LRQWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) LRQWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) LRQWebImageNoParamsBlcok cancelBlock;

@property (assign, nonatomic, getter=isExecuting) BOOL executing;
@property (assign, nonatomic, getter=isFinished) BOOL finished;

@property (strong, nonatomic) NSURLSession *unownedSession;

@property (strong, nonatomic) NSMutableData *imageData;
@property (strong, atomic) NSThread *thread;
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
#endif
@end

@implementation LRQWebImageDownloaderOperation {
    size_t width, height;
    UIImageOrientation orientation;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithRequest:(NSURLRequest *)request options:(LRQWebImageDownloaderOption)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageDownloaderCompletedBlock)completedBlock cancelled:(LRQWebImageNoParamsBlcok)cancelBlock {
    return [self initWithRequest:request
                       inSession:nil options:options
                        progress:progressBlock
                       completed:completedBlock
                       cancelled:cancelBlock];
}

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(LRQWebImageDownloaderOption)options progress:(LRQWebImageDownloaderProgressBlock)progressBlock completed:(LRQWebImageDownloaderCompletedBlock)completedBlock cancelled:(LRQWebImageNoParamsBlcok)cancelBlock {
    if (self = [super init]) {
        _request = request;
        _options = options;
        _progressBlock = progressBlock;
        _completedBlock = completedBlock;
        _cancelBlock = cancelBlock;
        
        _finished = NO;
        _executing = NO;
        
        _unownedSession = session;
    }
    return self;
}

- (void)start {
    @synchronized(self) {
        if (self.isCancelled) {
            self.finished = YES;
            [self reset];
            return;
        }
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
        //1. 根据字符串获取类对象
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        //2. 判断类对象是否存在 和 类对象是否支持某个SEL 以及是否支持 后台任务运行
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        if ( hasApplication && [self shouldContinueWhenAppEntersBackground] ) {
            __weak typeof (self)wself = self;
            UIApplication *application = [UIApplicationClass performSelector:@selector(sharedApplication)];
            //开启后台任务
            self.backgroundTaskId = [application beginBackgroundTaskWithExpirationHandler:^{
                __strong __typeof__(wself) sself = wself;
                if (!sself) return;
                
                //取消所有操作.
                [sself cancel];
                //调用endBackgroundTask方法, 将taskId置为 invalid
                [application endBackgroundTask:self.backgroundTaskId];
                self.backgroundTaskId = UIBackgroundTaskInvalid;
            }];
            
        }
#endif
        
        NSURLSession *session = self.unownedSession;
        if (!session) {
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = 15;
            
            self.unownedSession = [NSURLSession sessionWithConfiguration:config
                                                                delegate:self
                                                           delegateQueue:nil];
            session = self.unownedSession;
        }
        
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
        self.thread = [NSThread currentThread];
    }
    
    [self.dataTask resume];
    
    if (self.dataTask) {
        if (self.progressBlock) {
            self.progressBlock(0, NSURLResponseUnknownLength);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadStartNotification object:self];
    } else {
        if (self.completedBlock) {
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"Connection can't be initialized"}], YES);
        }
    }
    
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    //2. 判断类对象是否存在 和 类对象是否支持某个SEL 以及是否支持 后台任务运行
    BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
    if (!hasApplication) {
        return;
    }
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        UIApplication *application = [UIApplicationClass performSelector:@selector(sharedApplication)];
        [application endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
    
#endif
}

- (void)cancel {
    @synchronized (self) {
        if (self.thread) {
            [self performSelector:@selector(cancelInternalAndStop) onThread:self.thread withObject:nil waitUntilDone:NO];
        } else {
            [self cancelInternal];
        }
    }
}

- (void)cancelInternalAndStop {
    if (self.isFinished) {
        return;
    }
    [self cancelInternal];
}

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];
    // 如果有 cancelBlock, 执行 cancelBlock
    if (self.cancelBlock) self.cancelBlock();
    
    //如果有 dataTask, 取消掉.
    if (self.dataTask) {
        [self.dataTask cancel];
        //发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadStopNotification object:self];
        
        //将executing, finished flag 状态更改一下.
        self.executing = NO;
        self.finished = NO;
    }
    //执行reset.
    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    self.progressBlock = nil;
    self.completionBlock = nil;
    self.cancelBlock = nil;
    self.dataTask = nil;
    self.imageData = nil;
    self.thread = nil;
    
    if (self.unownedSession) {
        [self.unownedSession invalidateAndCancel];
        self.unownedSession = nil;
    }
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent {
    return YES;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"didReceiveResponse");
    if (![response respondsToSelector:@selector(statusCode)] || ([(NSHTTPURLResponse *)response statusCode] < 400 && [(NSHTTPURLResponse *)response statusCode] != 304)) {
        NSUInteger expectedSize = response.expectedContentLength > 0 ? (NSUInteger)response.expectedContentLength : 0;
        self.expectedSize = expectedSize;
        self.response = response;
        
        self.imageData = [NSMutableData dataWithCapacity:expectedSize];
        if (self.progressBlock) self.progressBlock(0, expectedSize);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadReceiveResponseNotification object:self];
        });
        
    } else {
        if ([(NSHTTPURLResponse *)response statusCode] == 304) {
            [self cancelInternal];
        } else {
            [self.dataTask cancel];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadStopNotification object:self];
        });
        
        if (self.completedBlock) {
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil], YES);
        }
        
        [self done];
    }
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // 首先将 data 追加到 imageData 里面
    NSLog(@"didReceiveData");
    [self.imageData appendData:data];
    NSLog(@"self.imageData.length = %zd", self.imageData.length);
    if ((self.options & LRQWebImageDownloaderProgressiveDownload) && self.expectedSize > 0 && self.completedBlock) {
        UIImage *image = [UIImage imageWithData:self.imageData];
        
        dispatch_main_sync_safe(^{
            if (self.completedBlock) {
                self.completedBlock(image, nil, nil, NO);
            }
        });
    }
    
    if (self.progressBlock) {
        self.progressBlock(self.imageData.length, self.expectedSize);
    }
}


#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    NSLog(@"didCompleteWithError");
    @synchronized(self) {
        self.thread = nil;
        self.dataTask = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadStopNotification object:self];
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LRQWebImageDownloadFinishNotification object:self];
            }
        });
    }
    if (error) {
        if (self.completedBlock) {
            self.completedBlock(nil, nil, error, YES);
        }
    } else {
        if (self.completedBlock) {
            if (self.imageData) {
                UIImage *image = [UIImage imageWithData:self.imageData];
                if (CGSizeEqualToSize(image.size, CGSizeZero)) {
                    self.completedBlock(nil, nil, [NSError errorWithDomain:LRQWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"image downloaded is a 0 pixel"}], YES);
                } else {
                    self.completedBlock(image, self.imageData, nil, YES);
                }
            } else {
                self.completedBlock(nil, nil, [NSError errorWithDomain:LRQWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"image data is nil"}], YES);
            }
        }
    }
    
}


- (BOOL)shouldContinueWhenAppEntersBackground {
    return self.options & LRQWebImageDownloaderContinueInBackground;
}

#pragma mark - Helper Method

+ (UIImageOrientation)orientationFromPropertyValue:(NSInteger)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

@end
























