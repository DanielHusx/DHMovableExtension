# [DHMovableExtension](https://github.com/DanielHusx/DHMovableExtension)

优雅的长按Cell移动，针对UITableView与UICollectionView的Cell长按移动。
- 耦合低，代码侵入性低
- 支持分组移动
- 可定制化移动，设置不可移动或不可交换的位置
- 极易使用



## 安装

```shell
pod 'DHMovableExtension'
```

- 当前版本：1.0.2



## 使用方式

### 1. 引用头文件

```objective-c
#import "UIScrollView+DHMovableExtension.h"
```

### 2. 配置UITableView/UICollectionView必要参数

```objective-c
self.tableView.movable = YES;	// 必要开关
self.tableView.movableDataSource = self;	// 数据源获取代理
```

### 3. 实现数据源（[DHMovableDataSource详细说明](#DHMovableDataSource说明)）

```objective-c
> 推荐使用exchangeDataSourceBlock(from, to) 或 -movableDataSource: -movable_scrollView:exchangeDataSourceAtIndexPath:to: 自定义实现数据交换

> 数据量小的情况下可使用以下默认方式，因为存在数据拷贝，可能影响效率
> 其中self.data为UITableView/UICollectionView的数据数组
- (NSArray *)movable_dataSource:(UIScrollView *)scrollView {
    return [self.data copy];
}

- (void)movable_scrollView:(UIScrollView *)scrollView dataSourceExchanged:(NSArray *)dataSource {
  	// 将重排后的数据重新赋值
    self.dataSource = [data copy];
}
```



## 参数说明

- `edgeScrollEnable`: 边缘滚动使能。当跟随手指的截图cell移动到屏幕边缘时，触发引起UIScrollView是否能跟着滚动
- `edgeScrollInsets`: 边缘触发距离，四个方向与边缘距离达到此值将触发UIScrollView滚动。默认为UIEdgeInsetsZero
- `minimumResponseDuration`: 最小响应手势。长按反应时长
- `movableCellAnimationDuration`: 动画时长。当长按生效后，cell中心点移动到手指的位置的动画时长
- `drawMovableCellBlock`: 绘制cell截图样式Block。参数是截图后的视图，即`UIImageView`，旨在修改样式，以区分静态的cell。其中此优先级最高，其次代理方法`-movable_scrollView:drawMovableCell:`。如若此block与代理方法都没有实现，将使用默认截图样式
- `exchangeDataSourceBlock`: 交换数据源，切勿期间刷新数据



## DHMovableDataSource说明

**注意：切勿在有关方法中调用UITableView/UICollectionView的刷新数据（如`-reloadData`）方法。因为此代理响应期间正处于手势Change状态，刷新数据状况将不可控。**



### 默认交换数据方法（**注意：如使用，必须两个方法同时实现**）

提供两种数据数组的交换方式：

- 一种元素为非数组，例如：`@[@"1", @"2"]`
- 一种元素为数组，例如：`@[@[@"0-0", @"0-1"], @[@"1-0"]]`

```objective-c
/** UITableView/UICollectionView数据数组 -- 交换前 */
- (NSArray *)movable_dataSource:(UIScrollView *)scrollView;
/** 交换后数据反馈 -- 一般操作为重新复制给 原数据对象 */
- (void)movable_scrollView:(UIScrollView *)scrollView dataSourceExchanged:(NSArray *)dataSource;
```



### 自定义交换数据方法

```objective-c
/// 如设置此变量，将优先只用此block进行交换数据，不用movableDataSource代理
@property (nonatomic, copy) void(^exchangeDataSourceBlock) (NSIndexPath *from, NSIndexPath *to);
/// 效果同exchangeDataSourceBlock
- (void)movable_scrollView:(UIScrollView *)scrollView exchangeDataSourceAtIndexPath:(NSIndexPath *)from to:(NSIndexPath *)to;
```



## DHMovableDelegate 说明

```objective-c
/** 判断两个位置的cell是否可以替换 */
- (BOOL)movable_scrollView:(UIScrollView *)scrollView isCellExchangeableFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

/** 判断某个IndexPath的cell是否可以移动 */
- (BOOL)movable_scrollView:(UIScrollView *)scrollView isCellMovableAtIndexPath:(NSIndexPath *)indexPath;

/**
 cell将要开始移动
 
 @param movableCell 移动的cell截图
 @param indexPath 起始位置
 */
- (void)movable_scrollView:(UIScrollView *)scrollView movableCell:(UIView *)movableCell willMoveFromIndexPath:(NSIndexPath *)indexPath;

/** 完成一次cell从from到to的移动 */
- (void)movable_scrollView:(UIScrollView *)scrollView cellDidMovedFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

/**
 截图正在移动
 
 @param movableCell 移动的cell截图
 */
- (void)movable_scrollView:(UIScrollView *)scrollView movableCellIsMoving:(UIView *)movableCell;

/**
 结束移动
 
 @param movableCell 移动的cell截图
 @param indexPath 终止位置
 */
- (void)movable_scrollView:(UIScrollView *)scrollView movableCell:(UIView *)movableCell didEndMovedAtIndexPath:(NSIndexPath *)indexPath;

/**
 绘制可移动的cell截图，给已经截图的cell添加样式
 
 @param movableCell 移动的cell截图
 */
- (void)movable_scrollView:(UIScrollView *)scrollView drawMovableCell:(UIView *)movableCell;
```

## 效果图

![tableGif](https://github.com/DanielHusx/DHMovableExtension/blob/master/table.gif)



![collectionGif](https://github.com/DanielHusx/DHMovableExtension/blob/master/collection.gif)

> [DHMovableExtensionDemo](https://github.com/DanielHusx/DHMovableExtension)



如果你觉得好用，请**Star**，谢谢！

> [许可证](https://github.com/DanielHusx/DHMovableExtension/blob/master/LISCENSE)