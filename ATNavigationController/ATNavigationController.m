//
//  ATNavigationController.m
//  AT
//
//  Created by CoderAT on 15/1/24.
//  Copyright (c) 2015年 AT. All rights reserved.
//

#import "ATNavigationController.h"
#import <objc/runtime.h>

#define enableDrag (!self.disableDragBack && self.viewControllers.count > 1 && !self.topViewController.disableDragBack)

const void *keyDisableDragBack = &keyDisableDragBack;
@implementation UIViewController (ATNavigationControllerAdd)

- (BOOL)disableDragBack {
    return [objc_getAssociatedObject(self, keyDisableDragBack) boolValue];
}

- (void)setDisableDragBack:(BOOL)disableDragBack {
    objc_setAssociatedObject(self, keyDisableDragBack, @(disableDragBack), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


typedef NS_ENUM(int, ATNavMovingStateEnumes) {
    ATNavMovingStateStanby = 0,
    ATNavMovingStateDragBegan,
    ATNavMovingStateDragChanged,
    ATNavMovingStateDragEnd,
    ATNavMovingStateDecelerating,
};
@interface ATNavigationController () <UIGestureRecognizerDelegate>
/**
 *  黑色的蒙版
 */
@property (nonatomic, strong) UIView *lastScreenBlackMask;
/**
 *  显示上一个界面的截屏
 */
@property (nonatomic, strong) UIImageView *lastScreenShotView;
/**
 *  显示上一个界面的截屏黑色背景
 */
@property (nonatomic,retain) UIView *backgroundView;
/**
 *  存放截屏的字典数组 key：控制器指针字符串  value：截屏图片
 */
@property (nonatomic,retain) NSMutableDictionary *screenShotsDict;
/**
 *  正在移动
 */
@property (nonatomic,assign) ATNavMovingStateEnumes movingState;

@end

@implementation ATNavigationController

- (NSMutableDictionary *)screenShotsDict {
    if (_screenShotsDict == nil) {
        _screenShotsDict = [NSMutableDictionary dictionary];
    }
    return _screenShotsDict;
}
- (UIView *)backgroundView {
    if (_backgroundView == nil) {
        _backgroundView = [[UIView alloc]initWithFrame:self.view.bounds];
        _backgroundView.backgroundColor = [UIColor blackColor];
        
        _lastScreenShotView = [[UIImageView alloc] initWithFrame:_backgroundView.bounds];
        _lastScreenShotView.backgroundColor = [UIColor whiteColor];
        [_backgroundView addSubview:_lastScreenShotView];
        
        _lastScreenBlackMask = [[UIView alloc] initWithFrame:_backgroundView.bounds];
        _lastScreenBlackMask.backgroundColor = [UIColor blackColor];
        [_backgroundView addSubview:_lastScreenBlackMask];
    }
    if (_backgroundView.superview == nil) {
        [self.view.superview insertSubview:_backgroundView belowSubview:self.view];
    }
    return _backgroundView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // 为导航控制器view，添加拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] init];
    [pan addTarget:self action:@selector(paningGestureReceive:)];
    [pan setDelegate:self];
    [pan delaysTouchesBegan];
    [self.view addGestureRecognizer:pan];
}

- (void)dealloc {
    self.screenShotsDict = nil;
    [self.backgroundView removeFromSuperview];
    self.backgroundView = nil;
}

#pragma mark - 截屏相关方法
/**
 *  当前导航栏界面截屏
 */
- (UIImage *)capture {
    UIView *view = self.view;
    if (self.tabBarController) {
        view = self.tabBarController.view;
    }
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
/**
 *  得到OC对象的指针字符串
 */
- (NSString *)pointer:(id)objet {
    return [NSString stringWithFormat:@"%p", objet];
}
/**
 *  获取前一个界面的截屏
 */
- (UIImage *)lastScreenShot {
    UIViewController *lastVC = [self.viewControllers objectAtIndex:self.viewControllers.count - 2];
    return [self.screenShotsDict objectForKey:[self pointer:lastVC]];
}

#pragma mark - 监听导航栏栈控制器改变 截屏
/**
 *  push前添加当前界面截屏
 */
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewControllers.count > 0) {
        [self.screenShotsDict setObject:[self capture] forKey:[self pointer:self.topViewController]];
    }
    [super pushViewController:viewController animated:animated];
}
/**
 *  pop后移除当前界面截屏
 */
- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *popped = [super popViewControllerAnimated:animated];
    [self.screenShotsDict removeObjectForKey:[self pointer:self.topViewController]];
    return popped;
}
- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<UIViewController *> *popedVcs = [super popToViewController:viewController animated:animated];
    for (UIViewController *vc in popedVcs) {
        [self.screenShotsDict removeObjectForKey:[self pointer:vc]];
    }
    [self.screenShotsDict removeObjectForKey:[self pointer:self.topViewController]];
    return popedVcs;
}
- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<UIViewController *> *popedVcs = [super popToRootViewControllerAnimated:animated];
    for (UIViewController *vc in popedVcs) {
        [self.screenShotsDict removeObjectForKey:[self pointer:vc]];
    }
    [self.screenShotsDict removeObjectForKey:[self pointer:self.topViewController]];
    return popedVcs;
}
/**
 *  重置界面的截屏(新增了界面会缺失截屏)
 */
- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    if ([viewControllers containsObject:self.topViewController]) {
        [self.screenShotsDict setObject:[self capture] forKey:[self pointer:self.topViewController]];
    }
    [super setViewControllers:viewControllers animated:animated];
    
    NSMutableDictionary *newDic = [NSMutableDictionary dictionary];
    for (UIViewController *vc in viewControllers) {
        id obj = [self.screenShotsDict objectForKey:[self pointer:vc]];
        if (obj) {
            [newDic setObject:obj forKey:[self pointer:vc]];
        }
    }
    self.screenShotsDict = newDic;
}

#pragma mark - 拖拽移动界面
- (BOOL)shouldMoveWith:(UIWindow *)window {
    // UIRemoteKeyboardWindow || UITextEffectsWindow
    NSString *windowName = NSStringFromClass([window class]);
    return ((windowName.length == 22
             && [windowName hasPrefix:@"UI"]
             && [windowName hasSuffix:@"RemoteKeyboardWindow"])
            || (windowName.length == 19
                && [windowName hasPrefix:@"UI"]
                && [windowName hasSuffix:@"TextEffectsWindow"]));
}
- (void)moveViewWithX:(float)x
{
    // 设置水平位移在 [0, ATNavViewW] 之间
    x = MAX(MIN(x, ATNavViewW), 0);
    // 设置frame的x
    self.view.frame = (CGRect){ {x, self.view.frame.origin.y}, self.view.frame.size};
    // 设置黑色蒙版的不透明度
    self.lastScreenBlackMask.alpha = 0.6 * (1 - (x / ATNavViewW));
    // 设置上一个截屏的缩放比例
    CGFloat scale = x / ATNavViewW * 0.05 + 0.95;
    self.lastScreenShotView.transform = CGAffineTransformMakeScale(scale, scale);
    
    // 移动键盘
    if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 9)) {
        [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(__kindof UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self shouldMoveWith:obj]) {
                [(UIWindow *)obj setTransform:CGAffineTransformMakeTranslation(x, 0)];
            }
        }];
    }
    else {
        if ([[[UIApplication sharedApplication] windows] count] > 1) {
            [((UIWindow *)[[[UIApplication sharedApplication] windows] objectAtIndex:1]) setTransform:CGAffineTransformMakeTranslation(x, 0)];
        }
    }
}

- (void)paningGestureReceive:(UIPanGestureRecognizer *)recoginzer
{
    if (!enableDrag) return;
    
    if (UIGestureRecognizerStateBegan == recoginzer.state) {
        if (self.movingState == ATNavMovingStateStanby) {
            self.movingState = ATNavMovingStateDragBegan;
            self.backgroundView.hidden = NO;
            self.lastScreenShotView.image = [self lastScreenShot];
        }
    }else if (recoginzer.state == UIGestureRecognizerStateEnded || recoginzer.state == UIGestureRecognizerStateCancelled){
        if (self.movingState == ATNavMovingStateDragBegan || self.movingState == ATNavMovingStateDragChanged) {
            self.movingState = ATNavMovingStateDragEnd;
            [self panGestureRecognizerDidFinish:recoginzer];
        }
    } else if (recoginzer.state == UIGestureRecognizerStateChanged) {
        if (self.movingState == ATNavMovingStateDragBegan || self.movingState == ATNavMovingStateDragChanged) {
            self.movingState = ATNavMovingStateDragChanged;
            [self moveViewWithX:[recoginzer translationInView:ATKeyWindow].x];
        }
    }
}

- (void)panGestureRecognizerDidFinish:(UIPanGestureRecognizer *)panGestureRecognizer {
#define decelerationTime (0.4)
    // 获取手指离开时候的速率
    CGFloat velocityX = [panGestureRecognizer velocityInView:ATKeyWindow].x;
    // 手指拖拽的距离
    CGFloat translationX = [panGestureRecognizer translationInView:ATKeyWindow].x;
    // 按照一定decelerationTime的衰减时间，计算出来的目标位置
    CGFloat targetX = MIN(MAX(translationX + (velocityX * decelerationTime / 2), 0), ATNavViewW);
    // 是否pop
    BOOL pop = ( targetX > ATMinX );
    // 设置动画初始化速率为当前瘦子离开的速率
    CGFloat initialSpringVelocity = fabs(velocityX) / (pop ? ATNavViewW - translationX : translationX);
    
    self.movingState = ATNavMovingStateDecelerating;
    CGRect frame = (CGRect){ {0, self.view.frame.origin.y}, self.view.frame.size };
    BOOL adjustTabbarFrame = NO;
    if (self.tabBarController) {
        if (CGRectEqualToRect(frame, self.tabBarController.view.frame)) {
            adjustTabbarFrame = YES;
        }
        UIView *superView = self.view;
        while (superView != self.tabBarController.view && superView) {
            if (!CGRectEqualToRect(frame, self.tabBarController.view.frame)) {
                adjustTabbarFrame = NO;
                break;
            }
            superView = superView.superview;
        }
    }
    [UIView animateWithDuration:ATAnimationDuration
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:initialSpringVelocity
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self moveViewWithX:pop ? ATNavViewW : 0];
                     } completion:^(BOOL finished) {
                         self.backgroundView.hidden = YES;
                         if ( pop ) {
                             [self popViewControllerAnimated:NO];
                         }
                         self.view.frame = frame;
                         if (adjustTabbarFrame) {
                             UIView *superView = self.view;
                             while (superView != self.tabBarController.view && superView) {
                                 superView.frame = frame;
                                 superView = superView.superview;
                             }
                         }
                         self.movingState = ATNavMovingStateStanby;
                         
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((pop ? 0.3f : 0.0f) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             // 移动键盘
                             if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 9)) {
                                 [[[UIApplication sharedApplication] windows] enumerateObjectsUsingBlock:^(__kindof UIWindow * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                     if ([self shouldMoveWith:obj]) {
                                         [(UIWindow *)obj setTransform:CGAffineTransformIdentity];
                                     }
                                 }];
                             }
                             else {
                                 if ([[[UIApplication sharedApplication] windows] count] > 1) {
                                     [((UIWindow *)[[[UIApplication sharedApplication] windows] objectAtIndex:1]) setTransform:CGAffineTransformIdentity];
                                 }
                             }
                         });
                     }];
}

#pragma mark - 拖拽手势代理
/**
 *  不响应的手势则传递下去
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 手势落点在屏幕右边1/3, 不响应手势
    if ([touch locationInView:nil].x >= [UIScreen mainScreen].bounds.size.width * 2 / 3) {
        return NO;
    }
    return enableDrag;
}
/**
 *  适配cell左滑删除
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    UIPanGestureRecognizer *ges = (UIPanGestureRecognizer *)otherGestureRecognizer;
    // 手势不是 UIPanGestureRecognizer
    if (![ges isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO;
    }
    // 手势落点在屏幕左边1/3
    if ([ges locationInView:nil].x <= [UIScreen mainScreen].bounds.size.width / 3) {
        return NO;
    }
    // 手势是 上下滑动
    CGPoint offset = [ges translationInView:nil];
    if (fabs(offset.x) <= fabs(offset.y)) {
        return NO;
    }
    // 手势是 右滑
    if (offset.x >= 0) {
        return NO;
    }
    // 应该是左滑了
    return YES;
}

@end
