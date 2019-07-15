//
//  UIScrollView+DHMovableExtension.h
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol DHMovableDelegate;
@protocol DHMovableDataSource;

@interface UIScrollView (DHMovableExtension)
@property (nonatomic, weak) id<DHMovableDelegate> movableDelegate;
@property (nonatomic, weak) id<DHMovableDataSource> movableDataSource;

/// 是否可移动，默认关闭。总开关
@property (nonatomic, assign, getter=isMovable) BOOL movable;
/// 是否全部cell可交换，默认开启
/// 如果代理实现-scrollView:cellIsExchangeableFromIndexPath:toIndexPath，则以代理为准
@property (nonatomic, assign, getter=isAllExchangeable) BOOL allExchangeable;

/// 能否边缘滚动（当移动中的cell靠近屏幕边缘时，scrollView是否能跟着滚动），默认开启
@property (nonatomic, assign, getter=isEdgeScrollEnable) BOOL edgeScrollEnable;
/// 边缘滚动识别距离，默认UIEdgeInsetsZero
@property (nonatomic, assign) UIEdgeInsets edgeScrollInsets;

/// 响应识别（长按）最短时长，默认0.5s
@property (nonatomic, assign) NSTimeInterval minimumResponseDuration;
/// 响应生效后动画时长，默认0.25s
@property (nonatomic, assign) CGFloat movableCellAnimationDuration;

/// 绘制cell截图样式Block
/// 优先级：
/// drawMovableCellBlock
/// > movableDelegate: drawMovableCell
/// > 默认样式
@property (nonatomic, copy, nullable) void(^drawMovableCellBlock)(UIView *movableCell);

/// 数据源交换数据
/// 优先级：
/// exchangeDataSourceBlock
/// > movableDataSource: -movable_scrollView:exchangeDataSourceAtIndexPath:to:
/// > movableDataSource: -movable_dataSource: & -movable_scrollView:dataSourceExchanged:
@property (nonatomic, copy) void(^exchangeDataSourceBlock) (NSIndexPath *from, NSIndexPath *to);

@end

@protocol DHMovableDelegate <NSObject>
@optional
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

@end

@protocol DHMovableDataSource <NSObject>

@optional
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
@end

NS_ASSUME_NONNULL_END
