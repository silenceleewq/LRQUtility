//
//  LRQImageCache.m
//  LRQWebImage
//
//  Created by lirenqiang on 2018/2/18.
//  Copyright © 2018年 lirenqiang. All rights reserved.
//

#import "LRQImageCache.h"

static unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
static NSData *kPNGSignatureData = nil;

BOOL ImageDataHasPNGPreffix(NSData *data);

BOOL ImageDataHasPNGPreffix(NSData *data) {
    NSUInteger pngSignatureLength = [kPNGSignatureData length];
    if ([data length] >= pngSignatureLength) {
        if ([[data subdataWithRange:NSMakeRange(0, pngSignatureLength)] isEqualToData:kPNGSignatureData]) {
            return YES;
        }
    }
    
    return NO;
}

FOUNDATION_STATIC_INLINE NSUInteger LRQCacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale;
}

@interface AutoPurgeCache : NSCache
@end

@implementation AutoPurgeCache
- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects)  name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}
@end

@interface LRQImageCache()
@property (strong, nonatomic) AutoPurgeCache *memCache;
@property (strong, nonatomic) dispatch_queue_t ioQueue;
@end

@implementation LRQImageCache

+ (instancetype)sharedImageCache {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    return [self initWithNameSpace:@"default"];
}

- (instancetype)initWithNameSpace:(NSString *)ns
{
    NSString *directory = [self makeDiskCachePath:ns];
    return [self initWithNameSpace:ns diskCacheDirectory:directory];
}

- (instancetype)initWithNameSpace:(NSString *)ns diskCacheDirectory:(NSString *)directory
{
    self = [super init];
    if (self) {
//        NSString *fullNameSpace = [@"com.lrq.LRQWebImageCache." stringByAppendingString:ns];
        kPNGSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];
        _memCache = [AutoPurgeCache new];
        _shouldCacheImagesInMemory = YES;
        _ioQueue = dispatch_queue_create("com.lrq.", DISPATCH_QUEUE_SERIAL);
        
    }
    return self;
}

- (NSString *)makeDiskCachePath:(NSString *)fullNameSpace {
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    return [cachePath stringByAppendingPathComponent:fullNameSpace];
}

#pragma mark - Store


- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk {
    if (!image || !key) {
        return;
    }
    
    if (self.shouldCacheImagesInMemory) {
        NSUInteger cost = LRQCacheCostForImage(image);
        [self.memCache setObject:image forKey:key cost:cost];
    }
    
    if (toDisk) {
        dispatch_async(self.ioQueue, ^{
            NSData *data = imageData;
            if (image && (recalculate || !data)) {
                
            }
        });
    }
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:toDisk];
}

- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key {
    
}

@end
























