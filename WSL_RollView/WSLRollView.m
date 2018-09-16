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

@interface WSLRollViewCell ()
@end
@implementation WSLRollViewCell
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

@end

@implementation WSLRollView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self == [super initWithFrame:frame]) {
        _scrollStyle = WSLRollViewScrollStylePage;
        _scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _speed = 60;
        _interval = 3.0;
        _spaceOfItem = 0;
        _padding = UIEdgeInsetsMake(0, 0, 0, 0);
        _loopEnabled = YES;
        [self setupUi];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame scrollDirection:(UICollectionViewScrollDirection)direction{
    if (self == [super initWithFrame:frame]) {
        _scrollStyle = WSLRollViewScrollStylePage;
        _scrollDirection = direction;
        _speed = 60;
        _interval = 3.0;
        _spaceOfItem = 0;
        _padding = UIEdgeInsetsMake(0, 0, 0, 0);
        _loopEnabled = YES;
        [self setupUi];
    }
    return self;
}

#pragma mark - Help Methods

- (void)setupUi{
    //注册默认cell
    [self.collectionView registerClass:[WSLRollViewCell class] forCellWithReuseIdentifier:@"WSLItemID"];
    [self addSubview:self.collectionView];
}

- (void)pause{
    [self close];
}

- (void)play{
    [self close];
    //如果速率或者时间间隔为0，表示不启用计时器
    if(_interval == 0 || _speed == 0 || _loopEnabled == NO){
        _collectionView.scrollEnabled = YES;
        return;
    }
    
    if(_scrollStyle == WSLRollViewScrollStylePage){
        _timer = [NSTimer scheduledTimerWithTimeInterval:_interval target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:UITrackingRunLoopMode];
    }else if(_scrollStyle == WSLRollViewScrollStyleStep){
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60 target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:UITrackingRunLoopMode];
    }
}

- (void)close{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(play) object:nil];
    [_timer invalidate];
    _timer = nil;
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
    if(_scrollStyle == WSLRollViewScrollStylePage){
        if (_scrollDirection == UICollectionViewScrollDirectionHorizontal) {
            [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self rowOfDataSource:index] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }else{
            [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[self rowOfDataSource:index] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
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
    return [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

#pragma mark - Event Handle

/**
 计时器任务
 */
- (void)timerEvent{
    
    if(self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        //如果不够一屏就停止滚动效果
        if (_collectionView.contentSize.width < self.frame.size.width) {
            [self close];
            return;
        }
        [self horizontalRollAnimation];
    }else{
        if (_collectionView.contentSize.height < self.frame.size.height) {
            [self close];
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
    
    //只有当IndexPath位置上的cell可见时，才能用如下方法获取到对应的cell，否则为nil
    WSLRollViewCell * item = (WSLRollViewCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_dataSource.count - (self.addRightCount) inSection:0]];
    //获取轮播首尾相连的交汇点位置坐标
    _connectionPoint = [_collectionView convertRect:item.frame toView:_collectionView].origin;
    //    WSL_Log(@"轮播首尾相连的交汇点位置坐标: %@", NSStringFromCGPoint(_connectionPoint));
    
    if(self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        
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

//刷新
- (void)reloadData{
    
    [_dataSource removeAllObjects];
    _dataSource = [NSMutableArray arrayWithArray:_sourceArray];
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        //刷新操作
    } completion:^(BOOL finished) {
        //刷新完成，其他操作
        if(finished){
            
            [weakSelf resetDataSourceForLoop];
            [weakSelf.collectionView reloadData];
            
            if (weakSelf.scrollStyle == WSLRollViewScrollStylePage && weakSelf.addLeftCount != 0) {
                [weakSelf.collectionView layoutIfNeeded];
                dispatch_async(dispatch_get_main_queue(),^{
                    [weakSelf rollToIndex:0];
                });
            }
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(play) object:nil];
            [self performSelector:@selector(play) withObject:nil afterDelay:0.6];
        }
    }];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
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
    
    if (decelerate == NO) {
        [self resetContentOffset];
    }
}

//拖拽之后减速完成
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self resetContentOffset];
    [self play];
}

//设置偏移量的动画结束之后
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self resetContentOffset];
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
    _collectionView.scrollEnabled = scrollStyle == WSLRollViewScrollStylePage ? YES : NO;
    WSLRollViewFlowLayout * layout = (WSLRollViewFlowLayout *)_collectionView.collectionViewLayout;
    layout.scrollStyle = scrollStyle;
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection{
    _scrollDirection = scrollDirection;
    WSLRollViewFlowLayout * layout = (WSLRollViewFlowLayout *)_collectionView.collectionViewLayout;
    layout.scrollDirection = scrollDirection;
}

#pragma mark - Getter

- (UICollectionView *)collectionView{
    
    if (_collectionView == nil) {
        
        WSLRollViewFlowLayout * layout = [[WSLRollViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.scrollStyle = WSLRollViewScrollStylePage;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, self.frame.size.height) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.decelerationRate = 0;
        _collectionView.scrollEnabled = YES;
        
    }
    return _collectionView;
}

@end
