//
//  WSLRollViewFlowLayout.m
//  WSL_RollView
//
//  Created by 王双龙 on 2018/9/14.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import "WSLRollViewFlowLayout.h"

@implementation WSLRollViewFlowLayout

- (void)prepareLayout{
    
    // 必须要调用父类(父类也有一些准备操作)
    [super prepareLayout];
}

/*
 返回collectionView上面所有元素（比如cell）的布局属性:这个方法决定了cell怎么排布
 每个cell都有自己对应的布局属性：UICollectionViewLayoutAttributes
 要求返回的数组中装着UICollectionViewLayoutAttributes对象
 */
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        // 计算 CollectionView 的中点
        CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.frame.size.width * 0.5;
        for (UICollectionViewLayoutAttributes *attrs in array){
            // 计算 cell 中点的 x 值 与 centerX 的差值
            CGFloat delta = ABS(centerX - attrs.center.x);
            CGFloat scale = 1 - delta / self.collectionView.frame.size.width;
            scale = 1;
            attrs.transform = CGAffineTransformMakeScale(scale, scale);
        }
    }else{
        CGFloat centerY = self.collectionView.contentOffset.y + self.collectionView.frame.size.height * 0.5;
        for (UICollectionViewLayoutAttributes *attrs in array){
            // 计算 cell 中点的 y 值 与 centerY 的差值
            CGFloat delta = ABS(centerY - attrs.center.y);
            CGFloat scale = 1 - delta / self.collectionView.frame.size.height;
            scale = 1;
            attrs.transform = CGAffineTransformMakeScale(scale, scale);
        }
    }
    return array;
}

// Invalidate:刷新
// 在滚动的时候是否允许刷新布局
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return YES;
}

/** 返回值决定了collectionView停止滚动时的偏移量 手指松开后执行
 * proposedContentOffset：原本情况下，collectionView停止滚动时最终的偏移量
 * velocity 滚动速率，通过这个参数可以了解滚动的方向
 */
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity{
    
    // NSLog(@"%@",NSStringFromCGPoint(proposedContentOffset));
    CGSize size = self.collectionView.frame.size;
    
    // 计算可见区域的面积
    CGRect rect = CGRectMake(proposedContentOffset.x, proposedContentOffset.y, size.width, size.height);
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    // 标记 cell 的中点与 UICollectionView 中点最小的间距
    CGFloat minDetal = MAXFLOAT;
    
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        // 计算 CollectionView 中点值
        CGFloat centerX = proposedContentOffset.x + self.collectionView.frame.size.width * 0.5;
        for (UICollectionViewLayoutAttributes *attrs in array){
            if (ABS(minDetal) > ABS(centerX - attrs.center.x)){
                minDetal = attrs.center.x - centerX;
            }
        }
        return CGPointMake(proposedContentOffset.x + minDetal, proposedContentOffset.y);
    }else{
        // 计算 CollectionView 中点值
        CGFloat centerY = proposedContentOffset.y + self.collectionView.frame.size.height * 0.5;
        for (UICollectionViewLayoutAttributes *attrs in array){
            if (ABS(minDetal) > ABS(centerY - attrs.center.y)){
                minDetal = attrs.center.y - centerY;
            }
        }
        return CGPointMake(proposedContentOffset.x, proposedContentOffset.y + minDetal);
    }
    
}



@end
