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
//修改后的数据
@property (nonatomic, strong) NSMutableArray * dataSource;

//弥补轮播无缝对接需要增加的cell数量 比如：0 1 2 3 4 0 1 2 ，这时addCount = 3
@property (nonatomic, assign) NSInteger addCount;
//轮播无缝对接的交汇点位置坐标
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
        [self setupUi];
    }
    return self;
}

//- (void)drawRect:(CGRect)rect{
//
//}

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
    if(_scrollStyle == WSLRollViewScrollStylePage){
        _timer = [NSTimer scheduledTimerWithTimeInterval:_interval target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
    }else{
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60 target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
    }
}

- (void)close{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(play) object:nil];
    [_timer invalidate];
    _timer = nil;
}

- (void)reloadData{
    
    [_dataSource removeAllObjects];
    _dataSource = [NSMutableArray arrayWithArray:_sourceArray];
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        //刷新操作
    } completion:^(BOOL finished) {
        //刷新完成，其他操作
        if(finished){
            if (weakSelf.collectionView.contentSize.width < self.frame.size.width || weakSelf.collectionView.contentSize.height < self.frame.size.height){
                //如果不够一屏就停止滚动效果
                [self close];
                return ;
            }
            if(weakSelf.scrollDirection == UICollectionViewScrollDirectionHorizontal){
                //用于无限循环轮播过渡的元素数量
                weakSelf.addCount = [weakSelf.collectionView  indexPathForItemAtPoint:CGPointMake(self.frame.size.width - 1, 0)].row + 1;
            }else{
                //用于无限循环轮播过渡的元素数量
                weakSelf.addCount = [weakSelf.collectionView  indexPathForItemAtPoint:CGPointMake(0, self.frame.size.height - 1)].row + 1;
            }
            
            NSArray * subArray = [weakSelf.sourceArray subarrayWithRange:NSMakeRange(0, weakSelf.addCount)];
            //增加用于无限循环轮播过渡的元素
            [weakSelf.dataSource addObjectsFromArray:subArray];
            
            [weakSelf.collectionView reloadData];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(play) object:nil];
            [self performSelector:@selector(play) withObject:nil afterDelay:0.6];
        }
    }];
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
        [self horizontalRollAnimation];
    }else{
        [self verticalRollAnimation];
    }
}

/**
 水平方向跑马灯 翻页/渐进动画
 */
- (void)horizontalRollAnimation{
    // 没有滚动新闻时退出
    if (_collectionView.contentSize.width == 0){
        return;
    }
    [self resetContentOffset];
    if (self.scrollStyle == WSLRollViewScrollStylePage){
        //翻页动画
        [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x + self.frame.size.width, _padding.top) animated:YES];
    }else{
        //渐进动画
        [_collectionView setContentOffset:CGPointMake(_collectionView.contentOffset.x + _speed * 1.0/60, _padding.top) animated:NO];
    }
}

/**
 垂直方向跑马灯 翻页/渐进动画
 */
- (void)verticalRollAnimation{
    // 没有滚动新闻时退出
    if (_collectionView.contentSize.height == 0){
        return;
    }
    [self resetContentOffset];
    if (self.scrollStyle == WSLRollViewScrollStylePage){
        //翻页动画
        [_collectionView setContentOffset:CGPointMake(_padding.left,  _collectionView.contentOffset.y + self.frame.size.height) animated:YES];
    }else{
        //渐进动画
        [_collectionView setContentOffset:CGPointMake(_padding.left, _collectionView.contentOffset.y + _speed * 1.0/60) animated:NO];
    }
}

/**
 复原至初始位置
 */
- (void)resetContentOffset{
    
    //只有当IndexPath位置上的cell可见时，才能用如下方法获取到对应的cell，否则为nil
    WSLRollViewCell * item = (WSLRollViewCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_dataSource.count - (self.addCount) inSection:0]];
    //获取轮播无缝对接的交汇点位置坐标
    _connectionPoint = [_collectionView convertRect:item.frame toView:_collectionView].origin;
    //        WSL_Log(@"轮播无缝对接的交汇点位置坐标: %@", NSStringFromCGPoint(_connectionPoint));
    
    if(self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        if ((_collectionView.contentOffset.x >= _connectionPoint.x) && _connectionPoint.x != 0) {
            [_collectionView setContentOffset:CGPointMake(_padding.left,_padding.top) animated:NO];
        }
    }else{
        if ((_collectionView.contentOffset.y >= _connectionPoint.y) && _connectionPoint.y != 0) {
            [_collectionView setContentOffset:CGPointMake(_padding.left,_padding.top) animated:NO];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    NSIndexPath * indexPath = [_collectionView  indexPathForItemAtPoint:scrollView.contentOffset];
    //    NSLog(@"滑到了第 %ld 组 %ld个",indexPath.section, indexPath.row);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (_timer != nil) {
        [self pause];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{

}

//拖拽之后减速完成
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (self.scrollStyle == WSLRollViewScrollStylePage){
        [self resetContentOffset];
    }
    [self play];
}

//设置偏移量的动画结束之后
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    if (self.scrollStyle == WSLRollViewScrollStylePage){
        [self resetContentOffset];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

/**
 item的大小
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.delegate respondsToSelector:@selector(rollView:sizeForItemAtIndex:)]) {
        NSInteger index = 0;
        if (indexPath.row >= self.sourceArray.count) {
            index = (NSInteger)(indexPath.row)%self.sourceArray.count;
        }else{
            index = (NSInteger)indexPath.row;
        }
        return [self.delegate rollView:self sizeForItemAtIndex:index];
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
        NSInteger index = 0;
        if (indexPath.row >= self.sourceArray.count) {
            index = (NSInteger)(indexPath.row)%self.sourceArray.count;
        }else{
            index = (NSInteger)indexPath.row;
        }
        return [self.delegate rollView:self cellForItemAtIndex:index];
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
        NSInteger index = 0;
        if (indexPath.row >= self.sourceArray.count) {
            index = (NSInteger)(indexPath.row)%self.sourceArray.count;
        }else{
            index = (NSInteger)indexPath.row;
        }
        [self.delegate rollView:self didSelectItemAtIndex:index];
    }
}

#pragma mark - Setter

- (void)setScrollStyle:(WSLRollViewScrollStyle)scrollStyle{
    _scrollStyle = scrollStyle;
    _collectionView.pagingEnabled = scrollStyle == WSLRollViewScrollStylePage ? YES : NO;
    _collectionView.scrollEnabled = scrollStyle == WSLRollViewScrollStylePage ? YES : NO;
}

- (void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection{
    _scrollDirection = scrollDirection;
    UICollectionViewFlowLayout * layout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    layout.scrollDirection = scrollDirection;
    [_collectionView reloadData];
}

#pragma mark - Getter

- (UICollectionView *)collectionView{
    
    if (_collectionView == nil) {
        
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, self.frame.size.height) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.scrollEnabled = YES;
        
        //    [_collectionView reloadData];
        //    [_collectionView layoutIfNeeded];
        //    dispatch_async(dispatch_get_main_queue(),^{
        //        //刷新完成，其他操作
        //    });
        
    }
    return _collectionView;
}

@end
