//
//  LRQWebImageCompat.h
//  LRQWebImage
//
//  Created by lirenqiang on 2018/2/6.
//  Copyright © 2018年 lirenqiang. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void(^LRQWebImageNoParamsBlcok)(void);

#define dispatch_main_sync_safe(block)\
if ([NSThread isMainThread]) {\
    block();\
} else {\
    dispatch_sync(dispatch_get_main_queue(), block);\
}

extern NSString *const LRQWebImageErrorDomain;
