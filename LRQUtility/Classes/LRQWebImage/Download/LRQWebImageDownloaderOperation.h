//
//  LRQWebImageDownloaderOperation.h
//  LRQWebImage
//
//  Created by lirenqiang on 2018/2/6.
//  Copyright © 2018年 lirenqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LRQWebImageDownloader.h"

extern NSString *const LRQWebImageDownloadStartNotification;
extern NSString *const LRQWebImageDownloadStartNotification;
extern NSString *const LRQWebImageDownloadStopNotification;
extern NSString *const LRQWebImageDownloadReceiveResponseNotification;
extern NSString *const LRQWebImageDownloadFinishNotification;

@interface LRQWebImageDownloaderOperation : NSOperation <LRQWebImageOperation, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (strong, nonatomic) NSURLSessionTask *dataTask;
@property (strong, nonatomic) NSURLResponse *response;
@property (assign, nonatomic) NSUInteger expectedSize;

@property (assign, nonatomic, readonly) LRQWebImageDownloaderOption options;

- (instancetype)initWithRequest:(NSURLRequest *)request
                        options:(LRQWebImageDownloaderOption)options
                       progress:(LRQWebImageDownloaderProgressBlock)progressBlock
                      completed:(LRQWebImageDownloaderCompletedBlock)completedBlock
                      cancelled:(LRQWebImageNoParamsBlcok)cancelBlock;

- (instancetype)initWithRequest:(NSURLRequest *)request
                      inSession:(NSURLSession *)session
                         options:(LRQWebImageDownloaderOption)options
                       progress:(LRQWebImageDownloaderProgressBlock)progressBlock
                      completed:(LRQWebImageDownloaderCompletedBlock)completedBlock
                      cancelled:(LRQWebImageNoParamsBlcok)cancelBlock;

@end
