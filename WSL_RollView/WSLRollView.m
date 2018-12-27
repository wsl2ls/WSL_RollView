//
//  WSLRollView.m
//  WSL_RollView
//
//  Created by 王双龙 on 2018/9/8.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

//----------------------ABOUT PRINTING LOG 打印日志 ----------------------------
//Using dlog to print while in debug model.        调试状态下打印日志
#ifdef DEBUG
#   define WSL_Log(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define WSL_Log(...)
#endif

#import "WSLRollView.h"

/**
 默认样式
 */
@interface WSLRollViewCell ()
@end
@implementation WSLRollViewCell
@end

//自定义分页布局
@interface WSLRollViewFlowLayout : UICollectionViewFlowLayout

/**
 轮播样式 默认是 WSLRollViewScrollStylePage 分页
 */
@property (nonatomic, assign) WSLRollViewScrollStyle scrollStyle;

@end

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
    /*
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
     */
    return array;
}

// Invalidate:刷新
// 在滚动的时候是否允许刷新布局
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return NO;
}

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

@end

//临时弱引用对象，解决循环引用的问题  引自 YYWeakProxy
@interface WSLWeakProxy : NSProxy <NSObject>
/**
 The proxy target.
 */
@property (nullable, nonatomic, weak, readonly) id target;

@end

@implementation WSLWeakProxy

+ (instancetype)proxyWithTarget:(id)target {
    return [[WSLWeakProxy alloc] initWithTarget:target];
}
- (instancetype)initWithTarget:(id)target {
    _target = target;
    return self;
}
//将消息接收对象改为 _target
- (id)forwardingTargetForSelector:(SEL)selector {
    return _target;
}
//self 对 target 是弱引用，一旦 target 被释放将调用下面两个方法，如果不实现的话会 crash
- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}
- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}
- (BOOL)isEqual:(id)object {
    return [_target isEqual:object];
}
- (NSUInteger)hash {
    return [_target hash];
}
- (Class)superclass {
    return [_target superclass];
}
- (Class)class {
    return [_target class];
}
- (BOOL)isKindOfClass:(Class)aClass {
    return [_target isKindOfClass:aClass];
}
- (BOOL)isMemberOfClass:(Class)aClass {
    return [_target isMemberOfClass:aClass];
}
- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    return [_target conformsToProtocol:aProtocol];
}
- (BOOL)isProxy {
    return YES;
}
- (NSString *)description {
    return [_target description];
}
- (NSString *)debugDescription {
    return [_target debugDescription];
}
@end


@interface WSLRollView ()<UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>

//计时器
@property (nonatomic, strong) NSTimer * timer;
//列表视图
@property (nonatomic, strong) UICollectionView * collectionView;
//处理重组后的数据源
@property (nonatomic, strong) NSMutableArray * dataSource;

//弥补轮播右侧首尾相连需要增加的cell数量 比如：0 1 2 3 4 0 1 2 ，这时addRightCount = 3
@property (nonatomic, assign) NSInteger addRightCount;
//弥补轮播左侧首尾相连需要增加的cell数量 比如：3 4 0 1 2 3 4 ，这时addLeftCount = 2 只有分页效果用的到
@property (nonatomic, assign) NSInteger addLeftCount;
//轮播右侧首尾相连的交汇点位置坐标 只有渐进效果用到
@property (nonatomic, assign) CGPoint connectionPoint;

//当前源数据的索引
@property (nonatomic, assign) NSInteger currentPage;

//处理后的数据cell索引
@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation WSLRollView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self == [super initWithFrame:frame]) {
        _scrollStyle = WSLRollViewScrollStylePage;
        _scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _startingPosition = 0;
        _speed = 60;
        _interval = 3.0;
        _spaceOfItem = 0;
        _padding = UIEdgeInsetsMake(0, 0, 0, 0);
        _loopEnabled = YES;
        _scrollEnabled = YES;
        [self setupUi];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame scrollDirection:(UICollectionViewScrollDirection)direction{
    if (self == [super initWithFrame:frame]) {
        _scrollStyle = WSLRollViewScrollStylePage;
        _startingPosition = 0;
        _scrollDirection = direction;
        _speed = 60;
        _interval = 3.0;
        _spaceOfItem = 0;
        _padding = UIEdgeInsetsMake(0, 0, 0, 0);
        _loopEnabled = YES;
        _scrollEnabled = YES;
        [self setupUi];
    }
    return self;
}

//获取某视图所在的控制器
+ (UIViewController *)viewControllerFromView:(UIView *)view {
    for (UIView *next = [view superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

#pragma mark - Help Methods

- (void)setupUi{
    //注册默认cell
    [self.collectionView registerClass:[WSLRollViewCell class] forCellWithReuseIdentifier:@"WSLItemID"];
    [self addSubview:self.collectionView];
}

//获取首尾相连循环滚动时需要用到的元素，并重组数据源
- (void)resetDataSourceForLoop{
    
    if(_loopEnabled == NO){
        return;
    }
    
    CGSize contentSize = CGSizeMake(0, 0);
    for (int i = 0; i < self.sourceArray.count; i++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        if (_scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            contentSize.width = contentSize.width + (i == 0 ? _padding.left : 0) + [self collectionView:_collectionView layout:_collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath].width + (i == self.sourceArray.count - 1 ? _padding.right : _spaceOfItem);
            contentSize.height = self.frame.size.height;
        }else{
            contentSize.height = contentSize.height + (i == 0 ? _padding.top : 0) + [self collectionView:_collectionView layout:_collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath].height + (i == self.sourceArray.count - 1 ? _padding.bottom : _spaceOfItem);
            contentSize.width = self.frame.size.width;
        }
    }
    
    if(_scrollDirection == UICollectionViewScrollDirectionHorizontal && contentSize.width >= self.frame.size.width){
        
        //用于右侧连接元素数量
        _addRightCount = [_collectionView  indexPathForItemAtPoint:CGPointMake(self.frame.size.width - 1, 0)].row + 1 ;
        if (_scrollStyle == WSLRollViewScrollStylePage){
            //如果是分页，还需要用于左侧连接元素数量
            _addLeftCount = _sourceArray.count - [_collectionView  indexPathForItemAtPoint:CGPointMake(contentSize.width - self.frame.size.width + 1, 0)].row;
        }
    }else if(_scrollDirection == UICollectionViewScrollDirectionVertical && contentSize.height >= self.frame.size.height){
        
        //用于右侧连接元素数量
        _addRightCount = [_collectionView  indexPathForItemAtPoint:CGPointMake(0, self.frame.size.height - 1)].row + 1 ;
        if (_scrollStyle == WSLRollViewScrollStylePage){
            //用于左侧连接元素数量
            _addLeftCount = _sourceArray.count - [_collectionView  indexPathForItemAtPoint:CGPointMake(0, contentSize.height - self.frame.size.height + 1)].row;
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

//根据处理后的数据源的索引row 返回原数据的索引index
- (NSInteger)indexOfSourceArray:(NSInteger)row{
    NSInteger index = 0;
    if(row < _addLeftCount){
        index = _sourceArray.count - _addLeftCount + row;
    }else if (row < _sourceArray.count + _addLeftCount && row >= _addLeftCount) {
        index = row - _addLeftCount;
    }else{
        index = row % (_sourceArray.count + _addLeftCount);
    }
    return index;
}

//根据原数据的索引index 返回处理后的数据源索引row
- (NSInteger)rowOfDataSource:(NSInteger)index{
    NSInteger row = 0;
    row = index + _addLeftCount;
    return row;
}

//分页效果  指定原数据的索引index页滚动到当前位置
- (void)rollToIndex:(NSInteger)index{
    if (index >= self.sourceArray.count) {
        index = 0;
    }
    if(_scrollStyle == WSLRollViewScrollStylePage){
        if (_scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self rowOfDataSource:index] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }else{
            [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self rowOfDataSource:index] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        }
        if ([self.delegate respondsToSelector:@selector(rollView:didRollItemToIndex:)]) {
            [self.delegate rollView:self didRollItemToIndex:index];
        }
    }
}

//获得当前页码  只针对分页效果
- (void)getCurrentIndex{
    if (_scrollStyle == WSLRollViewScrollStylePage){
        NSInteger currentIndex= 0;
        if(_scrollDirection == UICollectionViewScrollDirectionHorizontal){
            currentIndex= [_collectionView indexPathForItemAtPoint:CGPointMake(_collectionView.contentOffset.x + self.frame.size.width/2, 0)].row;
        }else{
            currentIndex= [_collectionView indexPathForItemAtPoint:CGPointMake(0,_collectionView.contentOffset.y + self.frame.size.height/2)].row;
        }
        NSInteger currentPage = [self indexOfSourceArray:currentIndex];
        if ([self.delegate respondsToSelector:@selector(rollView:didRollItemToIndex:)] && _currentPage != currentPage) {
            _currentPage = currentPage;
            [self.delegate rollView:self didRollItemToIndex:_currentPage];
        }
    }
}

//传递进来自定义item的样式，用法和UICollectionView相似
- (void)registerClass:(nullable Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier{
    [_collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}
- (void)registerNib:(nullable UINib *)nib forCellWithReuseIdentifier:(NSString *)identifier{
    [_collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
}
- (WSLRollViewCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index{
    return [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:_indexPath];
}
- (WSLRollViewCell *)cellForItemAtIndexPath:(NSInteger)index{
    return (WSLRollViewCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[self rowOfDataSource:index] inSection:0]];
}


#pragma mark - Event Handle

- (void)pause{
    [self invalidateTimer];
}

- (void)play{
    
    [self invalidateTimer];
    //如果速率或者时间间隔为0，表示不启用计时器
    if(_interval == 0 || _speed == 0 || _loopEnabled == NO){
        _collectionView.scrollEnabled = self.scrollEnabled;
        return;
    }
    
    if(_scrollStyle == WSLRollViewScrollStylePage){
        _timer = [NSTimer scheduledTimerWithTimeInterval:_interval target:[WSLWeakProxy proxyWithTarget:self] selector:@selector(timerEvent) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }else if(_scrollStyle == WSLRollViewScrollStyleStep){
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60 target:[WSLWeakProxy proxyWithTarget:self] selector:@selector(timerEvent) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}

- (void)close{
    [self invalidateTimer];
    for (UIView * subView in self.subviews) {
        [subView removeFromSuperview];
    }
    //    [self removeFromSuperview];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    if (!newSuperview && _timer) {
        // 销毁定时器
        [self close];
    }
}

- (void)didMoveToSuperview{
    [super didMoveToSuperview];
    if (self.superview) {
        //处理collectionView 内容视图自动下移的问题
        UIViewController * superVC = [WSLRollView viewControllerFromView:self];
        superVC.automaticallyAdjustsScrollViewInsets = NO;
        [self reloadData];
    }
}

/**
 释放计时器 必须执行，防止内存暴涨
 */
- (void)invalidateTimer{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(play) object:nil];
    if(_timer != nil){
        [_timer invalidate];
        _timer = nil;
    }
}

//刷新
- (void)reloadData{
    
    _addLeftCount = 0;
    _addRightCount = 0;
    [_dataSource removeAllObjects];
    _dataSource = [NSMutableArray arrayWithArray:_sourceArray];
    
    [self resetDataSourceForLoop];
    [self.collectionView reloadData];
    
    if (_sourceArray.count == 0) {
        return;
    }
    
    if (self.scrollStyle == WSLRollViewScrollStylePage) {
        [self.collectionView layoutIfNeeded];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(),^{
            if (weakSelf.startingPosition >= weakSelf.sourceArray.count || weakSelf.startingPosition < 0) {
                weakSelf.startingPosition = 0;
            }
            [weakSelf rollToIndex:weakSelf.startingPosition];
        });
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(play) object:nil];
    [self performSelector:@selector(play) withObject:nil afterDelay:0.6];
}

/**
 计时器任务
 */
- (void)timerEvent{
    
    if(self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        //如果不够一屏就停止滚动效果
        if (_collectionView.contentSize.width < self.frame.size.width) {
            [self pause];
            return;
        }
        [self horizontalRollAnimation];
    }else{
        if (_collectionView.contentSize.height < self.frame.size.height) {
            [self pause];
            return;
        }
        [self verticalRollAnimation];
    }
}

/**
 水平方向跑马灯 分页/渐进动画
 */
- (void)horizontalRollAnimation{
    // 没有滚动新闻时退出
    if (_collectionView.contentSize.width == 0){
        return;
    }
    [self resetContentOffset];
    if (self.scrollStyle == WSLRollViewScrollStylePage){
        //分页动画
        NSInteger currentMiddleIndex= [_collectionView indexPathForItemAtPoint:CGPointMake(_collectionView.contentOffset.x + self.frame.size.width/2, 0)].row;
        NSIndexPath * nextIndexPath = [NSIndexPath indexPathForRow:(currentMiddleIndex + 1) inSection:0];
        [_collectionView scrollToItemAtIndexPath:nextIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }else if (self.scrollStyle == WSLRollViewScrollStyleStep){
        //渐进动画
        [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x + _speed * 1.0/60, _padding.top) animated:NO];
    }
}

/**
 垂直方向跑马灯 分页/渐进动画
 */
- (void)verticalRollAnimation{
    // 没有滚动新闻时退出
    if (_collectionView.contentSize.height == 0){
        return;
    }
    [self resetContentOffset];
    if (self.scrollStyle == WSLRollViewScrollStylePage){
        //分页动画
        NSInteger currentMiddleIndex= [_collectionView indexPathForItemAtPoint:CGPointMake(0, _collectionView.contentOffset.y + self.frame.size.height/2)].row;
        NSIndexPath * nextIndexPath = [NSIndexPath indexPathForRow:(currentMiddleIndex + 1) inSection:0];
        [_collectionView scrollToItemAtIndexPath:nextIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    }else if (self.scrollStyle == WSLRollViewScrollStyleStep){
        //渐进动画
        [_collectionView setContentOffset:CGPointMake(_padding.left, _collectionView.contentOffset.y + _speed * 1.0/60) animated:NO];
    }
}

/**
 滑动到首尾连接处时需要复原至对应的位置
 */
- (void)resetContentOffset{
    
    if (self.scrollStyle == WSLRollViewScrollStyleStep){
        //只有当IndexPath位置上的cell可见时，才能用如下方法获取到对应的cell，否则为nil
        WSLRollViewCell * item = (WSLRollViewCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_dataSource.count - (self.addRightCount) inSection:0]];
        //获取渐进轮播首尾相连的交汇点位置坐标
        _connectionPoint = [_collectionView convertRect:item.frame toView:_collectionView].origin;
    }
    
    if(self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        //水平
        if (self.scrollStyle == WSLRollViewScrollStylePage) {
            NSInteger currentMiddleIndex = [_collectionView indexPathForItemAtPoint:CGPointMake(_collectionView.contentOffset.x + self.frame.size.width/2, 0)].row;
            if (currentMiddleIndex >= _sourceArray.count + _addLeftCount) {
                //右侧循环
                [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:currentMiddleIndex - _sourceArray.count inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            }else if (currentMiddleIndex < _addLeftCount) {
                //左侧循环
                [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow: _sourceArray.count + currentMiddleIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            }
            
        }else if (self.scrollStyle == WSLRollViewScrollStyleStep){
            if ((_collectionView.contentOffset.x >= _connectionPoint.x) && _connectionPoint.x != 0){
                [_collectionView setContentOffset:CGPointMake(_padding.left,_padding.top) animated:NO];
            }
        }
        
    }else{
        //垂直
        if (self.scrollStyle == WSLRollViewScrollStylePage) {
            NSInteger currentMiddleIndex = [_collectionView indexPathForItemAtPoint:CGPointMake(0, _collectionView.contentOffset.y + self.frame.size.height/2)].row;
            if (currentMiddleIndex >= _sourceArray.count + _addLeftCount) {
                //右侧循环
                [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:currentMiddleIndex - _sourceArray.count inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            }else if (currentMiddleIndex < _addLeftCount) {
                //左侧循环
                [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow: _sourceArray.count + currentMiddleIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
            }
            
        }else if (self.scrollStyle == WSLRollViewScrollStyleStep){
            if ((_collectionView.contentOffset.y >= _connectionPoint.y) && _connectionPoint.y != 0){
                [_collectionView setContentOffset:CGPointMake(_padding.left,_padding.top) animated:NO];
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self getCurrentIndex];
    if (!_loopEnabled) {
        return;
    }
    if ((scrollView.contentOffset.x < 1 || scrollView.contentOffset.x > scrollView.contentSize.width - self.frame.size.width - 1) && _scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        [self resetContentOffset];
    }else if ((scrollView.contentOffset.y < 1 || scrollView.contentOffset.y > scrollView.contentSize.height - self.frame.size.height - 1) && _scrollDirection == UICollectionViewScrollDirectionVertical){
        [self resetContentOffset];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (_timer != nil) {
        [self pause];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if (decelerate == NO && _loopEnabled) {
        [self resetContentOffset];
    }
}

//拖拽之后减速完成
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (_loopEnabled) {
        [self resetContentOffset];
        [self play];
    }
}

//设置偏移量的动画结束之后
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    if (_loopEnabled) {
        [self resetContentOffset];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

/**
 item的大小
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.delegate respondsToSelector:@selector(rollView:sizeForItemAtIndex:)]) {
        return [self.delegate rollView:self sizeForItemAtIndex:[self indexOfSourceArray:indexPath.row]];
    }
    return CGSizeMake(self.frame.size.width, self.frame.size.height);
}

/**
 行间距
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    if ([self.delegate respondsToSelector:@selector(spaceOfItemInRollView:)]) {
        _spaceOfItem = [self.delegate spaceOfItemInRollView:self];
    }
    return _spaceOfItem;
}

/**
 列间距
 */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    if ([self.delegate respondsToSelector:@selector(spaceOfItemInRollView:)]) {
        _spaceOfItem = [self.delegate spaceOfItemInRollView:self];
    }
    return _spaceOfItem;
}

/**
 组间距
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    if ([self.delegate respondsToSelector:@selector(paddingOfRollView:)]){
        _padding = [self.delegate paddingOfRollView:self];
    }
    return _padding;
}

#pragma mark - UICollectionViewDelegate UICollectionViewDataSource

//组个数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

//组内成员个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _dataSource.count;
}

// 返回每个cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    _indexPath = indexPath;
    if ([self.delegate respondsToSelector:@selector(rollView:cellForItemAtIndex:)]) {
        return [self.delegate rollView:self cellForItemAtIndex:[self indexOfSourceArray:indexPath.row]];
    }else{
        //默认样式
        WSLRollViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WSLItemID" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor whiteColor];
        return cell;
    }
}

//点击事件
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([self.delegate respondsToSelector:@selector(rollView:didSelectItemAtIndex:)]) {
        [self.delegate rollView:self didSelectItemAtIndex:[self indexOfSourceArray:indexPath.row]];
    }
}

#pragma mark - Setter

- (void)setScrollStyle:(WSLRollViewScrollStyle)scrollStyle{
    _scrollStyle = scrollStyle;
    WSLRollViewFlowLayout * layout = (WSLRollViewFlowLayout *)_collectionView.collectionViewLayout;
    layout.scrollStyle = scrollStyle;
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection{
    _scrollDirection = scrollDirection;
    WSLRollViewFlowLayout * layout = (WSLRollViewFlowLayout *)_collectionView.collectionViewLayout;
    layout.scrollDirection = scrollDirection;
}
- (void)setScrollEnabled:(BOOL)scrollEnabled{
    _scrollEnabled = scrollEnabled;
    self.collectionView.scrollEnabled = scrollEnabled;
}

#pragma mark - Getter

- (UICollectionView *)collectionView{
    if (_collectionView == nil) {
        WSLRollViewFlowLayout * layout = [[WSLRollViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.scrollStyle = WSLRollViewScrollStylePage;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, self.frame.size.height) collectionViewLayout:layout];
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
        }
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.decelerationRate = 0;
        _collectionView.scrollEnabled = self.scrollEnabled;
    }
    return _collectionView;
}

@end
