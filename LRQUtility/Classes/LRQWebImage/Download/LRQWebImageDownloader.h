//
//  LRQWebImageDownloader.h
//  LRQWebImage
//
//  Created by lirenqiang on 2018/2/6.
//  Copyright © 2018年 lirenqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LRQWebImageOperation.h"
#import "LRQWebImageCompat.h"

typedef NS_OPTIONS(NSInteger, LRQWebImageDownloaderOption) {
    LRQWebImageDownloaderLowPriority = 1 << 0,
    LRQWebImageDownloaderProgressiveDownload = 1 << 1,
    
    /**
     * By default, request prevent the use of NSURLCache. With this flag, NSURLCache
     * is used with default policies.
     */
    LRQWebImageDownloaderUseNSURLCache = 1 << 2,
    
    /**
     * Call completion block with nil image/imageData if the image was read from NSURLCache
     * (to be combined with `LRQWebImageDownloaderUseNSURLCache`).
     */
    
    LRQWebImageDownloaderIgnoreCachedResponse = 1 << 3,
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    
    LRQWebImageDownloaderContinueInBackground = 1 << 4,
    
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    LRQWebImageDownloaderHandleCookies = 1 << 5,
    
    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    LRQWebImageDownloaderAllowInvalidSSLCertificates = 1 << 6,
    
    /**
     * Put the image in the high priority queue.
     */
    LRQWebImageDownloaderHighPriority = 1 << 7,
};

typedef void(^LRQWebImageDownloaderProgressBlock)(NSInteger receviedSize, NSInteger expectedSize);
typedef void(^LRQWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);

@interface LRQWebImageDownloader : NSObject

//请求超时时间
@property (assign, nonatomic) NSUInteger downloadTimeout;

+ (instancetype)sharedDownloader;

- (id<LRQWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(LRQWebImageDownloaderOption)options
                                        progress:(LRQWebImageDownloaderProgressBlock)progressBlock
                                       completed:(LRQWebImageDownloaderCompletedBlock)completedBlock;

@end
