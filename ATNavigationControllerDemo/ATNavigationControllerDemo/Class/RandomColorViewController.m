//
//  RandomColorViewController.m
//  ATNavigationControllerDemo
//
//  Created by AT on 15/3/11.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "RandomColorViewController.h"

@interface RandomColorViewController ()

@end

@implementation RandomColorViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置view背景色
    self.view.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0f
                                                green:(arc4random()%256)/255.0f
                                                 blue:(arc4random()%256)/255.0f
                                                alpha:1.0f];
}
- (IBAction)push:(id)sender {
    // push 一个界面
    [self.navigationController pushViewController:[[RandomColorViewController alloc] init]  animated:YES];
}

@end
