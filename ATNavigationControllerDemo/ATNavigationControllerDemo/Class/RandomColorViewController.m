//
//  RandomColorViewController.m
//  ATNavigationControllerDemo
//
//  Created by AT on 15/3/11.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "RandomColorViewController.h"
#import "ATNavigationController.h"

@interface RandomColorViewController ()

@end

@implementation RandomColorViewController

#pragma mark - lifeCycle
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    int index = (int)[self.navigationController.viewControllers indexOfObject:self];
    self.navigationItem.title = [NSString stringWithFormat:@"我是第 %d 个控制器", index];
    if (index == 4) {
        self.disableDragBack = YES;
        self.navigationItem.title = @"我不能拖拽返回";
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"< 返回" style:UIBarButtonItemStyleDone target:self action:@selector(pop)];
    // 设置view背景色
    self.view.backgroundColor = [UIColor colorWithRed:(arc4random()%256)/255.0f
                                                green:(arc4random()%256)/255.0f
                                                 blue:(arc4random()%256)/255.0f
                                                alpha:1.0f];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"QQ头像"]];
    imageView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
    [self.view insertSubview:imageView atIndex:0];
    
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    effectView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    [self.view insertSubview:effectView atIndex:1];
}

#pragma mark - actions
- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)push:(id)sender {
    // push 一个界面
    [self.navigationController pushViewController:[[RandomColorViewController alloc] init]  animated:YES];
}
- (IBAction)popToVCr:(id)sender {
    // pop 指定控制器
    NSArray<UIViewController *> *vcs = self.navigationController.viewControllers;
    [self.navigationController popToViewController:[vcs objectAtIndex:(rand()%vcs.count)]  animated:YES];
}
- (IBAction)popToRootVC:(id)sender {
    // pop 到更控制器
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (IBAction)setVCs:(id)sender {
    // set 控制器
    NSMutableArray<UIViewController *> *vcs = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    for (int i = 0; i < 2; i++) {
        if (vcs.count == 0) {
            break;
        }
        UIViewController *removeVC = [vcs objectAtIndex:(rand()%vcs.count)];
        if (removeVC) {
            [vcs removeObject:removeVC];
        }
    }
    [vcs addObject:[[RandomColorViewController alloc] init]];
    [self.navigationController setViewControllers:vcs animated:YES];
}

@end
