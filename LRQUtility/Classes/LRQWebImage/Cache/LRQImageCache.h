//
//  LRQImageCache.h
//  LRQWebImage
//
//  Created by lirenqiang on 2018/2/18.
//  Copyright © 2018年 lirenqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LRQWebImageCompat.h"

@interface LRQImageCache : NSObject

@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;

+ (instancetype)sharedImageCache;
- (instancetype)initWithNameSpace:(NSString *)ns;
- (instancetype)initWithNameSpace:(NSString *)ns diskCacheDirectory:(NSString *)directory;
- (NSString *)makeDiskCachePath:(NSString *)fullNameSpace;

#pragma mark - Store
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;
- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk;
- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key;
@end
