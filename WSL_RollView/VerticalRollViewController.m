//
//  VerticalRollViewController.m
//  WSL_RollView
//
//  Created by 王双龙 on 2018/9/4.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import "VerticalRollViewController.h"
#import "WSLRollView.h"
#import "PrefixHeader.pch"

#define KRollViewHeight 200

@interface WSLRollViewVerticalCell : WSLRollViewCell
@property (strong, nonatomic) UILabel * titleLabel;
@end

@implementation WSLRollViewVerticalCell
- (instancetype)initWithFrame:(CGRect)frame{
    if (self == [super initWithFrame:frame]) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:30];
        self.titleLabel.userInteractionEnabled = YES;
        [self.contentView addSubview:self.titleLabel];
        self.contentView.clipsToBounds = YES;
    }
    return self;
}
- (void)refreshData{
    self.titleLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}
@end

@interface VerticalRollViewController ()<WSLRollViewDelegate>
{
    NSArray * _array;
}
@end

@implementation VerticalRollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"垂直滚动";
    _array = @[
               @{@"title":@"0",@"color":RGBRANDOMCOLOR,@"height":@(arc4random()%(int)(KRollViewHeight)),@"width":@(SCREEN_WIDTH)},
               @{@"title":@"1",@"color":RGBRANDOMCOLOR,@"height":@(arc4random()%(int)(KRollViewHeight)),@"width":@(SCREEN_WIDTH)},
               @{@"title":@"2",@"color":RGBRANDOMCOLOR,@"height":@(arc4random()%(int)(KRollViewHeight)),@"width":@(SCREEN_WIDTH)}];
    
    WSLRollView * pageRollView = [[WSLRollView alloc] initWithFrame:CGRectMake(0,StatusBarAndNavigationBarHeight + 50 , SCREEN_WIDTH, KRollViewHeight)];
    pageRollView.sourceArray = [NSMutableArray arrayWithArray:_array];
    pageRollView.backgroundColor = [UIColor blackColor];
    pageRollView.scrollStyle = WSLRollViewScrollStylePage;
    pageRollView.scrollDirection = UICollectionViewScrollDirectionVertical;
    pageRollView.interval = 2;
    pageRollView.delegate = self;
    [pageRollView registerClass:[WSLRollViewVerticalCell class] forCellWithReuseIdentifier:@"PageRollID"];
    [self.view addSubview:pageRollView];
    [pageRollView reloadData];
    
    WSLRollView * stepRollView = [[WSLRollView alloc] initWithFrame:CGRectMake(0,pageRollView.frame.origin.y + KRollViewHeight + 50, SCREEN_WIDTH, KRollViewHeight)];
    stepRollView.sourceArray = [NSMutableArray arrayWithArray:_array];
    stepRollView.backgroundColor = [UIColor blackColor];
    stepRollView.scrollStyle = WSLRollViewScrollStyleStep;
    stepRollView.scrollDirection = UICollectionViewScrollDirectionVertical;
    stepRollView.speed = 120;
    stepRollView.delegate = self;
    [stepRollView registerClass:[WSLRollViewVerticalCell class] forCellWithReuseIdentifier:@"StepRollID"];
    [self.view addSubview:stepRollView];
    [stepRollView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated{
    for (UIView * view in self.view.subviews) {
        if ([view isKindOfClass:[WSLRollView class]]) {
            [(WSLRollView *)view close];
        }
    }
}

- (void)dealloc{
    WSL_Log(@"WSLRollView计时器已释放");
}

#pragma mark - WSLRollViewDelegate

//返回itemSize
- (CGSize)rollView:(WSLRollView *)rollView sizeForItemAtIndex:(NSInteger)index{
    if (rollView.scrollStyle == WSLRollViewScrollStylePage){
        return CGSizeMake(SCREEN_WIDTH, 150);
    }else{
        NSNumber * width = _array[index][@"width"];
        NSNumber * height = _array[index][@"height"];
        return CGSizeMake([width floatValue], [height floatValue]);
    }
}

//间隔
- (CGFloat)spaceOfItemInRollView:(WSLRollView *)rollView{
    if (rollView.scrollStyle == WSLRollViewScrollStylePage){
        return 0;
    }else{
        return 10;
    }
}

//内边距
- (UIEdgeInsets)paddingOfRollView:(WSLRollView *)rollView{
    if (rollView.scrollStyle == WSLRollViewScrollStylePage){
        return UIEdgeInsetsMake(0,0,0,0);
    }else{
        return UIEdgeInsetsMake(0,0,0,0);
    }
}

//点击事件
- (void)rollView:(WSLRollView *)rollView didSelectItemAtIndex:(NSInteger)index{
    WSL_Log(@" 点击了 %ld",index);
}

//当前页码
- (void)rollView:(WSLRollView *)rollView didRollItemToIndex:(NSInteger)currentIndex{
    WSL_Log(@"当前页码 %ld",currentIndex);
}

//返回自定义cell样式
-(WSLRollViewCell *)rollView:(WSLRollView *)rollView cellForItemAtIndex:(NSInteger)index{
    
    WSLRollViewVerticalCell * cell;
    if (rollView.scrollStyle == WSLRollViewScrollStylePage){
        cell = (WSLRollViewVerticalCell *)[rollView dequeueReusableCellWithReuseIdentifier:@"PageRollID" forIndex:index];
    }else{
        cell = (WSLRollViewVerticalCell *)[rollView dequeueReusableCellWithReuseIdentifier:@"StepRollID" forIndex:index];
    }
    
    cell.backgroundColor = _array[index][@"color"];
    cell.titleLabel.text = _array[index][@"title"];
    [cell refreshData];
    
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
