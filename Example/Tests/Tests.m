//
//  LRQUtilityTests.m
//  LRQUtilityTests
//
//  Created by 958246321@qq.com on 03/21/2018.
//  Copyright (c) 2018 958246321@qq.com. All rights reserved.
//

@import XCTest;
#import "LRQWebImageDownloader.h"
@interface Tests : XCTestCase
@property (strong, nonatomic) LRQWebImageDownloader *downloader;
@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    
    NSString *pic = @"https://img4.duitang.com/uploads/item/201506/20/20150620000045_neawY.jpeg";

    [self.downloader downloadImageWithURL:[NSURL URLWithString:pic] options:LRQWebImageDownloaderProgressiveDownload progress:^(NSInteger receviedSize, NSInteger expectedSize) {
        NSLog(@"receviedSize: %zd, expectedSize = %zd", receviedSize, expectedSize);
    } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
//        self.imgView.image = image;
        NSLog(@"image = %@", image);
    }];
}

@end

