# WSL_RollView

简书地址：https://www.jianshu.com/p/e73f54f2ea51

![iOS UICollectionView实现跑马灯和轮播效果.gif](https://upload-images.jianshu.io/upload_images/1708447-b45d768d5895dfc1.gif?imageMogr2/auto-orient/strip)

>功能描述：[WSL_RollView](https://github.com/wslcmk/WSL_RollView) 是基于UICollectionView实现的支持水平和垂直两个方向上的的分页和渐进循环轮播效果，可以设置时间间隔、渐进速率、是否循环、分页宽度和间隔，还支持高度自定义分页视图的控件。

#### 一、实现方法

#####  ①、 首先用UICollectionView和计时器实现一个基本的水平滚动效果，如下图，这个太简单就不在此详述。

![iOS UICollectionView](https://upload-images.jianshu.io/upload_images/1708447-4f6d268a3df79ee2.gif?imageMogr2/auto-orient/strip)

#####  ②、对比上面的效果图，我们还需要解决分页的宽度和循环滚动的问题。

>  *  自定义分页宽度：默认的分页宽度是UICollectionView的宽度，所以当分页宽度的不等于UICollectionView的宽度或分页间隔不等于0时会出现错误，这时就需要我们通过自定义UICollectionViewFlowLayout来实现效果。

```

/** 返回值决定了collectionView停止滚动时的偏移量 手指松开后执行
 * proposedContentOffset：原本情况下，collectionView停止滚动时最终的偏移量
 * velocity 滚动速率，通过这个参数可以了解滚动的方向
 */
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity{
    
    if (_scrollStyle == WSLRollViewScrollStylePage) {
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
    return proposedContentOffset;
}

```

> * 循环滚动：思想当然还是3 >4 >0 >1 >2 >3 >4 >0 >1，关键就在于怎么确定弥补两端轮播首尾相连需要增加的cell，前边尾首相连需要UICollectionView可见范围内的数据源后边的元素cell，后边首尾相连需要UICollectionView可见范围内的数据源前边的元素cell

```

//获取首尾相连循环滚动时需要用到的元素，并重组数据源
- (void)resetDataSourceForLoop{
    if(_loopEnabled == NO){
        return;
    }
    if(_scrollDirection == UICollectionViewScrollDirectionHorizontal && _collectionView.contentSize.width >= self.frame.size.width){
        //用于右侧连接元素数量
        _addRightCount = [_collectionView  indexPathForItemAtPoint:CGPointMake(self.frame.size.width - 1, 0)].row + 1 ;
        if (_scrollStyle == WSLRollViewScrollStylePage){
            //如果是分页，还需要用于左侧连接元素数量
            _addLeftCount = _sourceArray.count - [_collectionView  indexPathForItemAtPoint:CGPointMake(_collectionView.contentSize.width - self.frame.size.width + 1, 0)].row;
        }
    }else if(_scrollDirection == UICollectionViewScrollDirectionVertical && _collectionView.contentSize.height >= self.frame.size.height){
        //用于右侧连接元素数量
        _addRightCount = [_collectionView  indexPathForItemAtPoint:CGPointMake(0, self.frame.size.height - 1)].row + 1 ;
        if (_scrollStyle == WSLRollViewScrollStylePage){
            //用于左侧连接元素数量
            _addLeftCount = _sourceArray.count - [_collectionView  indexPathForItemAtPoint:CGPointMake(0, _collectionView.contentSize.height - self.frame.size.height + 1)].row;
        }
    }
    NSArray * rightSubArray = [_sourceArray subarrayWithRange:NSMakeRange(0, _addRightCount)];
    //增加右侧连接元素
    [_dataSource addObjectsFromArray:rightSubArray];
    
    if (_scrollStyle == WSLRollViewScrollStylePage){
        NSArray * leftSubArray = [_sourceArray subarrayWithRange:NSMakeRange(_sourceArray.count - _addLeftCount, _addLeftCount)];
        //增加左侧连接元素
        [_dataSource insertObjects:leftSubArray atIndexes: [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,_addLeftCount)]];
    }
}

```

#### 二、WSL_RollView用法

> 请看WSLRollView.h文件中的注释，属性和用法很明朗，详情和效果请前往我的Github查看示例：[WSL_RollView](https://github.com/wslcmk/WSL_RollView)

```
//
//  WSLRollView.h
//  WSL_RollView
//
//  Created by 王双龙 on 2018/9/8.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 默认cell样式 WSLItemID
 */
@interface WSLRollViewCell : UICollectionViewCell
@end

@class WSLRollView;

//代理协议
@protocol WSLRollViewDelegate <NSObject>
@optional
/**
 返回itemSize 默认值是CGSizeMake(self.frame.size.width, self.frame.size.height);
 */
- (CGSize)rollView:(WSLRollView *)rollView sizeForItemAtIndex:(NSInteger)index;
/**
 item的间隔 默认值0
 */
- (CGFloat)spaceOfItemInRollView:(WSLRollView *)rollView;
/**
 内边距 上 左 下 右 默认值UIEdgeInsetsMake(0, 0, 0, 0)
 */
- (UIEdgeInsets)paddingOfRollView:(WSLRollView *)rollView;
/**
 点击事件
 */
- (void)rollView:(WSLRollView *)rollView didSelectItemAtIndex:(NSInteger)index;
/**
 自定义item样式
 */
- (WSLRollViewCell *)rollView:(WSLRollView *)rollView cellForItemAtIndex:(NSInteger )index;
@end

/**
 滚动样式
 */
typedef NS_ENUM(NSInteger, WSLRollViewScrollStyle) {
    WSLRollViewScrollStylePage = 0, /** 分页 必须等宽或高*/
    WSLRollViewScrollStyleStep   /** 渐进 可以不等宽或高*/
};

@interface WSLRollView : UIView

/**
 原始数据源
 */
@property (nonatomic, strong) NSMutableArray * sourceArray;

/**
 是否循环轮播 默认YES
 */
@property (nonatomic, assign) BOOL loopEnabled;

/**
 轮播方向 默认是 UICollectionViewScrollDirectionHorizontal 水平
 */
@property (nonatomic, assign) UICollectionViewScrollDirection scrollDirection;

/**
 轮播样式 默认是 WSLRollViewScrollStylePage 分页
 */
@property (nonatomic, assign) WSLRollViewScrollStyle scrollStyle;

/**
 渐进轮播速率 单位是Point/s，以坐标系单位为准 默认60/s 如果为0 表示禁止计时器
 */
@property (nonatomic, assign) CGFloat speed;
/**
 分页轮播间隔时长 单位是s  默认3s 如果为0 表示禁止计时器
 */
@property (nonatomic, assign) CGFloat interval;

/**
 item的间隔 默认值0
 */
@property (nonatomic, assign) CGFloat spaceOfItem;

/**
 内边距 上 左 下 右 默认值UIEdgeInsetsMake(0, 0, 0, 0)
 */
@property (nonatomic, assign) UIEdgeInsets padding;

/** delegate*/
@property (nonatomic, weak) id<WSLRollViewDelegate> delegate;

/**
  初始化方法 direction 滚动方向
 */
- (instancetype)initWithFrame:(CGRect)frame scrollDirection:(UICollectionViewScrollDirection)direction;

/**
 注册item样式 用法和UICollectionView相似
 */
- (void)registerClass:(nullable Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
/**
 注册item样式 用法和UICollectionView相似
 */
- (void)registerNib:(nullable UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier;
/**
 用于初始化和获取WSLRollViewCell，自定义cell样式 用法和UICollectionView相似
 */
- (WSLRollViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index;
/**
 刷新数据源
 */
- (void)reloadData;
/**
 暂停自动轮播
 */
- (void)pause;
/**
 继续自动轮播
 */
- (void)play;

@end

```

> 以上就是我实现这个效果的过程，如果小伙伴们有其他的实现方法，欢迎再此留言交流😊😊😀😀🤗🤗

推荐阅读：
[iOS UITableView/UICollectionView获取特定位置的cell](https://www.jianshu.com/p/70cdcdcb6764)
[iOS 图片浏览的放大缩小](https://www.jianshu.com/p/b5a55099f4fc)
[UIScrollerView当前显示3张图](https://www.jianshu.com/p/2aa464ae84ca)
[iOS 自定义转场动画](https://www.jianshu.com/p/a9b1307b305b)
[iOS 瀑布流封装](https://www.jianshu.com/p/9fafd89c97ad)
[WKWebView的使用](https://www.jianshu.com/p/5cf0d241ae12)
[UIScrollView视觉差动画](https://www.jianshu.com/p/3b30b9cdd274)
[iOS 传感器集锦](https://www.jianshu.com/p/5fc26af852b6)
[iOS 音乐播放器之锁屏歌词+歌词解析+锁屏效果](https://www.jianshu.com/p/35ce7e1076d2)
[UIActivityViewController系统原生分享-仿简书分享](https://www.jianshu.com/p/b6b44662dfda)


![😁😁](https://upload-images.jianshu.io/upload_images/1708447-826d458d52c32bb6.gif?imageMogr2/auto-orient/strip)
