# [DHMovableExtension](https://github.com/DanielHusx/DHMovableExtension)

优雅的长按Cell移动，针对UITableView与UICollectionView的Cell长按移动。耦合低，支持分组移动、可定制化移动，极易使用

## 使用方式

```objective-c
// 1. 引用
#import "UIScrollView+DHMovableExtension.h"

// 2. 配置UITableView or UICollectionView必要参数
self.tableView.movable = YES;
self.tableView.dataSource = self;

// 3. 实现movableDataSource代理即可
- (NSArray *)movable_dataSource:(UIScrollView *)scrollView {
		// dataSource为数据数组
    return [self.dataSource copy];
}
- (void)movable_scrollView:(UIScrollView *)scrollView dataSourceExchanged:(NSArray *)dataSource {
  	// 将重排后的数据重新赋值
    self.dataSource = [dataSource copy];
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

```objective-c

/**
 交换数据源
 
 @note
 exchangeDataSourceBlock
 > movableDataSource: -movable_scrollView:exchangeDataSourceAtIndexPath:to:
 > movableDataSource: -movable_dataSource: & -movable_scrollView:dataSourceExchanged:
 
 @attention 如果设置exchangeDataSourceBlock，此代理就不会调用
 */
- (void)movable_scrollView:(UIScrollView *)scrollView exchangeDataSourceAtIndexPath:(NSIndexPath *)from to:(NSIndexPath *)to;

/**
 获取数据源
 
 @attention 如实现此方法，同时也必须实现-movable_scrollView:dataSourceExchanged:
 */
- (NSArray *)movable_dataSource:(UIScrollView *)scrollView;
/**
 交换之后的数据反馈
 
 @attention 如实现此方法，同时也必须实现-movable_dataSource:
 */
- (void)movable_scrollView:(UIScrollView *)scrollView dataSourceExchanged:(NSArray *)dataSource;
```

以上三个方法都是为了在移动过程中，处理数据交换。

其中最省心省力的方法是实现两个方法`-movable_dataSource:`与`-movable_scrollView:dataSourceExchanged`。提供数据源数组(`-movable_dataSource:`)，内部将会自动处理数据交换，处理结束后返回已修改的数据(`-movable_scrollView:dataSourceExchanged:`) 以此通知外部该更新数据。

另外内部自动处理的数组只有两种。一种元素为非数组，例如：`@[@"1", @"2"]`；一种元素为数组，例如：`@[@[@"0-0", @"0-1"], @[@"1-0"]]`

**注意：请勿在以上三个处理数据交换方法中调用`reloadData`方法，因为还在移动过程中，期间刷新，可能产生未知后果**



## DHMovableDelegate 说明

```objective-c
/**
 判断两个位置的cell是否可以替换
 */
- (BOOL)movable_scrollView:(UIScrollView *)scrollView isCellExchangeableFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

/**
 判断某个IndexPath的cell是否可以移动
 */
- (BOOL)movable_scrollView:(UIScrollView *)scrollView isCellMovableAtIndexPath:(NSIndexPath *)indexPath;

/**
 cell将要开始移动
 
 @param movableCell 移动的cell截图
 @param indexPath 起始位置
 */
- (void)movable_scrollView:(UIScrollView *)scrollView movableCell:(UIView *)movableCell willMoveFromIndexPath:(NSIndexPath *)indexPath;

/**
 完成一次cell从from到to的移动
 */
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

![tableGif](/Users/daniel/Desktop/tab.gif)

![collectionGif](/Users/daniel/Desktop/coll.gif)

> [DHMovableExtensionDemo](https://github.com/DanielHusx/DHMovableExtension)

