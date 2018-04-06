//
//  LRQViewController.m
//  LRQUtility
//
//  Created by 958246321@qq.com on 03/21/2018.
//  Copyright (c) 2018 958246321@qq.com. All rights reserved.
//

#import "LRQViewController.h"

@interface LRQViewController ()
@property (strong, nonatomic) UILabel *label;
@end

@implementation LRQViewController
@synthesize label = label;

- (void)viewDidLoad
{
    [super viewDidLoad];

    label = [UILabel new];
    label.frame = CGRectMake(100, 100, 200, 80);
    label.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14.0];
    label.text = @"HelloWorld";
    NSLog(@"point size = %f", label.font.pointSize);
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
