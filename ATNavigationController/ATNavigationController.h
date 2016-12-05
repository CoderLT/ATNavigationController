//
//  ATNavigationController.h
//  YAMI
//
//  Created by 林涛 on 15/1/24.
//  Copyright (c) 2015年 Summer. All rights reserved.
//

#import <UIKit/UIKit.h>


#define ATKeyWindow     [[UIApplication sharedApplication] keyWindow]
#define ATNavViewW      [UIScreen mainScreen].bounds.size.width

#define ATAnimationDuration     0.5f
#define ATMinX                  (0.3f * ATNavViewW)

@interface UIViewController (ATNavigationControllerAdd)
/**
 *  If yes, disable the drag back, default no.
 */
@property (nonatomic, assign) BOOL disableDragBack;
@end

@interface ATNavigationController : UINavigationController
/**
 *  If yes, disable the drag back, default no. global
 */
@property (nonatomic, assign) BOOL disableDragBack;

@end
