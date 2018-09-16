//
//  WSLRollViewFlowLayout.h
//  WSL_RollView
//
//  Created by 王双龙 on 2018/9/14.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 滚动样式
 */
typedef NS_ENUM(NSInteger, WSLRollViewScrollStyle) {
    WSLRollViewScrollStylePage = 0, /** 分页 必须等宽或高*/
    WSLRollViewScrollStyleStep   /** 渐进 可以不等宽或高*/
};

@interface WSLRollViewFlowLayout : UICollectionViewFlowLayout

/**
 轮播样式 默认是 WSLRollViewScrollStylePage 分页
 */
@property (nonatomic, assign) WSLRollViewScrollStyle scrollStyle;

@end
