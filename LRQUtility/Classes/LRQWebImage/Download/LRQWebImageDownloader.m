//
//  LRQWebImageDownloader.m
//  LRQWebImage
//
//  Created by lirenqiang on 2018/2/6.
//  Copyright © 2018年 lirenqiang. All rights reserved.
//

#import "LRQWebImageDownloader.h"
#import "LRQWebImageDownloaderOperation.h"
static NSString *kCompletedCallbackKey = @"kCompletedCallbackKey";
static NSString *kProgressCallbackKey = @"kProgressCallbackKey";
static LRQWebImageDownloader *_instance;

@interface LRQWebImageDownloader () <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

//开辟一个子队列
@property (strong, nonatomic) dispatch_queue_t barrierQueue;
// 用于 URL 请求的回调.
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;
// HTTP 请求头
@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;
//操作类,难道是有好几个操作类吗?
@property (strong, nonatomic) Class operationClass;
@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (strong, nonatomic) NSURLSession *session;
@end

@implementation LRQWebImageDownloader

+ (instancetype)sharedDownloader {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationClass = [LRQWebImageDownloaderOperation class];
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _downloadQueue.name = @"com.rq.LRQWebImageDownloader";
        _barrierQueue = dispatch_queue_create("com.lrq.LRQWebImageDownloader", DISPATCH_QUEUE_CONCURRENT);
        _URLCallbacks = [NSMutableDictionary new];
        _downloadTimeout = 15.0;
        _HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = _downloadTimeout;
        _session = [NSURLSession sessionWithConfiguration:config
                                                 delegate:self
                                            delegateQueue:nil];

    }
    return self;
}

- (void)dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;
    
    [self.downloadQueue cancelAllOperations];
}

- (id<LRQWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(LRQWebImageDownloaderOption)options
                                        progress:(LRQWebImageDownloaderProgressBlock)progressBlock
                                       completed:(LRQWebImageDownloaderCompletedBlock)completedBlock {
    __block LRQWebImageDownloaderOperation *operation;
    __weak typeof (self)wself = self;
    
    [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^{
        NSUInteger downloadTimeout = wself.downloadTimeout;
        if (downloadTimeout == 0.0) {
            downloadTimeout = 15.0;
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:(options&LRQWebImageDownloaderUseNSURLCache?NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:downloadTimeout];
        request.HTTPShouldUsePipelining = YES;
        request.HTTPShouldHandleCookies = (options & LRQWebImageDownloaderHandleCookies);
        request.allHTTPHeaderFields = wself.HTTPHeaders;
        
        operation = [[self.operationClass alloc] initWithRequest:request inSession:(NSURLSession *)self.session options:options progress:^(NSInteger receviedSize, NSInteger expectedSize) {
            LRQWebImageDownloader *sself = wself;
            if (!sself) { return; }
            
            __block NSArray *callbackForURL = nil;
            dispatch_sync(self.barrierQueue, ^{
                callbackForURL = [self.URLCallbacks[url] copy];
            });
           
            for (NSDictionary *callbacks in callbackForURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    LRQWebImageDownloaderProgressBlock progressBlock = callbacks[kProgressCallbackKey];
                    if (progressBlock) progressBlock(receviedSize, expectedSize);
                });
            }
            
        } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
            LRQWebImageDownloader *sself = wself;
            if (!sself) return;
            __block NSArray *callbacksForURL = nil;
            dispatch_barrier_sync(self.barrierQueue, ^{
                callbacksForURL = [sself.URLCallbacks[url] copy];
                if (finished) {
                    [sself.URLCallbacks removeObjectForKey:url];
                }
            });
            for (NSDictionary *callback in callbacksForURL) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    LRQWebImageDownloaderCompletedBlock completedBlock = callback[kCompletedCallbackKey];
                    if (completedBlock) {
                        completedBlock(image, data, error, finished);
                    }
                });
            }
        } cancelled:^{
            LRQWebImageDownloader *sself = wself;
            if (!sself) return;
            dispatch_barrier_async(self.barrierQueue, ^{
                [sself.URLCallbacks removeObjectForKey:url];
            });
        }];
        
        [wself.downloadQueue addOperation:operation];
    }];
    
    return operation;
}

- (void)addProgressCallback:(LRQWebImageDownloaderProgressBlock)progressBlock completedBlock:(LRQWebImageDownloaderCompletedBlock)completedBlock forURL:(NSURL *)url createCallback:(LRQWebImageNoParamsBlcok)createCallback {
    //判断 url 为 nil 的状况.
    if (url == nil) {
        if (completedBlock) {
            //(UIImage *image, NSData *data, NSError *error, BOOL finished)
            completedBlock(nil, nil, nil, YES);
        }
        return;
    }
    
    //单线程将 progressBlock, completedBlock 添加到一个 URLCallbacks 字典里面.
    //根据 URLCallbacks 字典来判断是否是第一次添加,如果是,那么执行 createCallback
    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL first = NO;
        if (!self.URLCallbacks[url]) {
            self.URLCallbacks[url] = [NSMutableArray new];
            first = YES;
            
        }
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        NSMutableDictionary *callbacks = [NSMutableDictionary new];
        if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
        [callbacksForURL addObject:callbacks];
        self.URLCallbacks[url] = callbacksForURL;
        
        if (first) {
            if (createCallback) {
                createCallback();
            }
        }
    });
    
}

#pragma mark - Helper Method
- (LRQWebImageDownloaderOperation *)operationWithTask:(NSURLSessionTask *)task {
    LRQWebImageDownloaderOperation *returnOperation = nil;
    for (LRQWebImageDownloaderOperation *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    LRQWebImageDownloaderOperation *operation = [self operationWithTask:dataTask];
    [operation URLSession:session dataTask:dataTask didReceiveResponse:response  completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    LRQWebImageDownloaderOperation *operation = [self operationWithTask:dataTask];
    [operation URLSession:session dataTask:dataTask didReceiveData:data];
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    LRQWebImageDownloaderOperation *operation = [self operationWithTask:task];
    [operation URLSession:session task:task didCompleteWithError:error];
}

@end
























