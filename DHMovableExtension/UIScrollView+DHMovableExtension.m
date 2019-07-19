//
//  UIScrollView+DHMovableExtension.m
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import "UIScrollView+DHMovableExtension.h"
#import <objc/runtime.h>
/**
 移动cell的方向
 */
typedef NS_ENUM(NSUInteger, DHMoveDirection) {
    DHMoveDirectionNone = 0,
    /// 往左
    DHMoveDirectionToLeft,
    /// 往右
    DHMoveDirectionToRight,
    /// 往上
    DHMoveDirectionToUp,
    /// 往下
    DHMoveDirectionToDown
};

@interface UIScrollView ()
/// 长按移动手势
@property (nonatomic, strong) UILongPressGestureRecognizer *moveGesture;
/// 记录初始的IndexPath
@property (nonatomic, copy) NSIndexPath *originalIndexPath;
/// 初始cell的截图View， 随手势移动
@property (nonatomic, strong) UIView *tempMoveCell;
/// 边缘滚动动画
@property (nonatomic, strong) CADisplayLink *edgeScrollTimer;

@end

@implementation UIScrollView (DHMovableExtension)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method frameInit = class_getInstanceMethod([self class], @selector(initWithFrame:));
        Method myFrameInit = class_getInstanceMethod([self class], @selector(initWithMovableFrame:));
        method_exchangeImplementations(frameInit, myFrameInit);
        
        Method codeInit = class_getInstanceMethod([self class], @selector(initWithCoder:));
        Method myCodeInit = class_getInstanceMethod([self class], @selector(initWithMovableCoder:));
        method_exchangeImplementations(codeInit, myCodeInit);
    });
}


#pragma mark - initial
- (instancetype)initWithMovableFrame:(CGRect)frame {
    if (self = [self initWithMovableFrame:frame]) {
        [self movable_initializeData];
    }
    return self;
}

- (instancetype)initWithMovableCoder:(NSCoder *)aDecoder {
    if (self = [self initWithMovableCoder:aDecoder]) {
        [self movable_initializeData];
    }
    return self;
}

- (void)movable_initializeData {
    if ([self isKindOfClass:[UICollectionView class]]
        || [self isKindOfClass:[UITableView class]]) {
        self.minimumResponseDuration = .5f;
        self.edgeScrollEnable = YES;
        self.movable = NO;
        self.movableCellAnimationDuration = 0.25f;
        self.allExchangeable = YES;
        self.edgeScrollInsets = UIEdgeInsetsZero;
    }
}


#pragma mark - gesture method
- (void)movable_addGesture {
    if ([self.gestureRecognizers containsObject:self.moveGesture]) return ;
    self.moveGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(movable_processGesture:)];
    self.moveGesture.minimumPressDuration = self.minimumResponseDuration;
    [self addGestureRecognizer:self.moveGesture];
}

- (void)movable_removeGesture {
    if (!self.moveGesture) return ;
    
    [self removeGestureRecognizer:self.moveGesture];
    self.moveGesture = nil;
}

- (void)movable_processGesture:(UIGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self movable_gestureBegan:gesture];
            break;
        case UIGestureRecognizerStateChanged:
            [self movable_gestureChanged:gesture];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [self movable_gestureEndedOrCancelled:gesture];
            break;
            
        default:
            break;
    }
}

- (void)movable_gestureBegan:(UIGestureRecognizer *)gesture {
    CGPoint point = [gesture locationOfTouch:0 inView:gesture.view];
    // 获取indexPath
    NSIndexPath *selectedIndexPath = [self movable_indexPathForCellAtPoint:point];
    if (!selectedIndexPath) return ;
    
    // 判断是否可移动
    BOOL cellMovable = [self movable_isCellMovableAtIndexPath:selectedIndexPath];
    if (!cellMovable) {
        self.originalIndexPath = selectedIndexPath;
        return ;
    }
    
    // 边缘滚动
    if (self.isEdgeScrollEnable) {
        [self movable_startEdgeScrollTimer];
    }
    
    self.originalIndexPath = selectedIndexPath;
    
    // 绘制移动的Cell
    [self movable_drawMovableCellAtIndexPath:selectedIndexPath];
    
    // 将移动的Cell的中心移动到手势的位置
    [UIView animateWithDuration:self.movableCellAnimationDuration animations:^{
        self.tempMoveCell.center = CGPointMake(point.x, point.y);
    }];
    
    // 通知代理临时cell即将开始移动
    if (self.movableDelegate && [self.movableDelegate respondsToSelector:@selector(movable_scrollView:movableCell:willMoveFromIndexPath:)]) {
        [self.movableDelegate movable_scrollView:self movableCell:self.tempMoveCell willMoveFromIndexPath:selectedIndexPath];
    }
}

- (void)movable_gestureChanged:(UIGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:gesture.view];
    // 当前手指移动到的触及的cell
    NSIndexPath *currentIndexPath = [self movable_indexPathForCellAtPoint:point];
    
    // 每次移动之前先设定一次隐藏属性，避免hidden属性被重用时导致的其它cell被隐藏
    NSArray *visibleCells = [self movable_visibleCells];
    for (UIView *cell in visibleCells) {
        @autoreleasepool {
            NSIndexPath *indexPath = [self movable_indexPathForCell:cell];
            BOOL hidden = self.originalIndexPath && indexPath.row == self.originalIndexPath.row && indexPath.section == self.originalIndexPath.section;
            cell.hidden = hidden;
        }
    }
    
    // 移动
    [self movable_processCellMoveFrom:self.originalIndexPath to:currentIndexPath];
    
    //让截图跟随手势
    self.tempMoveCell.center = CGPointMake(point.x, point.y);
    
    // 代理截图正在移动
    if (self.movableDelegate && [self.movableDelegate respondsToSelector:@selector(movable_scrollView:movableCellIsMoving:)]) {
        [self.movableDelegate movable_scrollView:self movableCellIsMoving:self.tempMoveCell];
    }
}

- (void)movable_gestureEndedOrCancelled:(UIGestureRecognizer *)gesture {
    // 关闭边缘滚动
    [self movable_stopEdgeScrollTimer];
    
    // 结束移动到指定位置
    if (self.movableDelegate && [self.movableDelegate respondsToSelector:@selector(movable_scrollView:movableCell:didEndMovedAtIndexPath:)]) {
        [self.movableDelegate movable_scrollView:self movableCell:self.tempMoveCell didEndMovedAtIndexPath:self.originalIndexPath];
    }
    
    UIView *cell = [self movable_cellAtIndexPath:self.originalIndexPath];
    // 结束清理截图，以及恢复cell
    __weak typeof(self) weakself = self;
    [UIView animateWithDuration:self.movableCellAnimationDuration animations:^{
        weakself.tempMoveCell.frame = cell.frame;
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        [weakself.tempMoveCell removeFromSuperview];
        weakself.tempMoveCell = nil;
        [weakself movable_reloadData];
    }];
}


#pragma mark - edge scrolling
- (void)movable_startEdgeScrollTimer {
    self.edgeScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(movable_processEdgeScrolling)];
    [self.edgeScrollTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)movable_stopEdgeScrollTimer {
    if (!self.edgeScrollTimer) return ;
    [self.edgeScrollTimer invalidate];
    self.edgeScrollTimer = nil;
}

- (void)movable_processEdgeScrolling {
    DHMoveDirection moveDirection = [self movable_moveDirection];
    CGFloat moveDistance = 5;
    switch (moveDirection) {
        case DHMoveDirectionToLeft:{
            // 这里的动画必须设为NO
            [self setContentOffset:CGPointMake(self.contentOffset.x - moveDistance, self.contentOffset.y) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x - moveDistance, self.tempMoveCell.center.y);
            
        }
            break;
        case DHMoveDirectionToRight:{
            [self setContentOffset:CGPointMake(self.contentOffset.x + moveDistance, self.contentOffset.y) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x + moveDistance, self.tempMoveCell.center.y);
            
        }
            break;
        case DHMoveDirectionToUp:{
//            [self setContentInset:self.contentInset];// 可能解决跳变问题
            [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y - moveDistance) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x, self.tempMoveCell.center.y - moveDistance);
        }
            break;
        case DHMoveDirectionToDown:{
            [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y + moveDistance) animated:NO];
            self.tempMoveCell.center = CGPointMake(self.tempMoveCell.center.x, self.tempMoveCell.center.y + moveDistance);
        }
            break;
        default:
            break;
    }
}

- (DHMoveDirection)movable_moveDirection{
    DHMoveDirection scrollDirection = DHMoveDirectionNone;
    // 算法: 移动cell的的中心与边界,偏移的关系
    if (self.bounds.size.height + self.contentOffset.y - self.tempMoveCell.center.y < self.tempMoveCell.bounds.size.height / 2 + self.edgeScrollInsets.bottom && self.bounds.size.height + self.contentOffset.y < self.contentSize.height) {
        scrollDirection = DHMoveDirectionToDown;
    }
    if (self.tempMoveCell.center.y - self.contentOffset.y < self.tempMoveCell.bounds.size.height / 2 + self.edgeScrollInsets.top && self.contentOffset.y > 0) {
        scrollDirection = DHMoveDirectionToUp;
    }
    if (self.bounds.size.width + self.contentOffset.x - self.tempMoveCell.center.x < self.tempMoveCell.bounds.size.width / 2 + self.edgeScrollInsets.right && self.bounds.size.width + self.contentOffset.x < self.contentSize.width) {
        scrollDirection = DHMoveDirectionToRight;
    }
    
    if (self.tempMoveCell.center.x - self.contentOffset.x < self.tempMoveCell.bounds.size.width / 2 + self.edgeScrollInsets.left && self.contentOffset.x > 0) {
        scrollDirection = DHMoveDirectionToLeft;
    }
    
    return scrollDirection;
}


#pragma mark - private method
/** 数据源更新交换 */
- (void)movable_exchangeDataSourceFromIndexPath:(NSIndexPath *)from to:(NSIndexPath *)to {
    
    // 数据源交换更新
    if (self.exchangeDataSourceBlock) {
        self.exchangeDataSourceBlock(from, to);
        
    } else if (self.movableDataSource && [self.movableDataSource respondsToSelector:@selector(movable_scrollView:exchangeDataSourceAtIndexPath:to:)]) {
        [self.movableDataSource movable_scrollView:self exchangeDataSourceAtIndexPath:from to:to];
        
    } else {
        // 默认的交换数据方式
        NSAssert((self.movableDataSource && [self.movableDataSource respondsToSelector:@selector(movable_dataSource:)]) && (self.movableDataSource && [self.movableDataSource respondsToSelector:@selector(movable_scrollView:dataSourceExchanged:)]), @"-movable_dataSource:与-movable_scrollView:dataSourceExchanged:实现一个就都必须实现");
        
        // 获取数据源
        // 没办法验证数据的正确性，务必保证外部传参正确
        NSArray *dataSource = [self.movableDataSource movable_dataSource:self];
        
        NSMutableArray *temp = [NSMutableArray arrayWithArray:dataSource];
        
        // 判断数据源是单个数组还是数组套数组的多section形式，YES表示数组套数组
        NSInteger sections = [self movable_numberOfSections];
        BOOL mutiSectionCheck = (sections != 1 || (sections == 1 && [temp[0] isKindOfClass:[NSArray class]]));
        
        if (mutiSectionCheck) {
            // 将子数组 设置 为可变数组
            for (int i = 0; i < temp.count; i ++) {
                [temp replaceObjectAtIndex:i withObject:[temp[i] mutableCopy]];
            }
        }
        
        if (to.section == from.section) {
            // 同组之间的数据交换
            NSMutableArray *orignalSection = mutiSectionCheck ? temp[from.section] : temp;
            id obj = [orignalSection objectAtIndex:from.row];
            [orignalSection removeObjectAtIndex:from.row];
            [orignalSection insertObject:obj atIndex:to.row];
            
        } else {
            // 异组之间的数据交换
            // 将初始cell的行删除此数据，然后加到指定行的手势位置
            NSMutableArray *orignalSection = temp[from.section];
            NSMutableArray *currentSection = temp[to.section];
            
            [currentSection insertObject:orignalSection[from.row] atIndex:to.row];
            [orignalSection removeObject:orignalSection[from.row]];
            
        }
        
        //将重排好的数据传递给外部
        [self.movableDataSource movable_scrollView:self dataSourceExchanged:[temp copy]];
    }
    
}

/** cell是否可移动 */
- (BOOL)movable_isCellMovableAtIndexPath:(NSIndexPath *)indexPath {
    if (self.movableDelegate && [self.movableDelegate respondsToSelector:@selector(movable_scrollView:isCellMovableAtIndexPath:)]) {
        BOOL movable = [self.movableDelegate movable_scrollView:self isCellMovableAtIndexPath:indexPath];
        return movable;
    }
    
    return self.isMovable;
}

/** cell是否位置可交换 */
- (BOOL)movable_isCellExchangeableFromIndexPath:(NSIndexPath *)from to:(NSIndexPath *)to {
    if (self.movableDelegate && [self.movableDelegate respondsToSelector:@selector(movable_scrollView:isCellExchangeableFromIndexPath:toIndexPath:)]) {
        return [self.movableDelegate movable_scrollView:self isCellExchangeableFromIndexPath:from toIndexPath:to];
    }
    
    return self.isAllExchangeable;
}

/** 根据点获取cell位置 */
- (NSIndexPath * _Nullable)movable_indexPathForCellAtPoint:(CGPoint)point {
    if ([self isKindOfClass:[UITableView class]]) {
        return [(UITableView *)self indexPathForRowAtPoint:point];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        return [(UICollectionView *)self indexPathForItemAtPoint:point];
    }
    return nil;
}

/** 根据位置获取cell */
- (UIView * _Nullable)movable_cellAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isKindOfClass:[UITableView class]]) {
        return [(UITableView *)self cellForRowAtIndexPath:indexPath];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        return [(UICollectionView *)self cellForItemAtIndexPath:indexPath];
    }
    return nil;
}

/** 截图视图 */
- (UIView *)movable_snapshotViewWithInputView:(UIView *)inputView {
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    return snapshot;
}

/** 可见cell */
- (NSArray * _Nullable)movable_visibleCells {
    if ([self isKindOfClass:[UITableView class]]) {
        return [(UITableView *)self visibleCells];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        return [(UICollectionView *)self visibleCells];
    }
    
    return nil;
}

/** section */
- (NSInteger)movable_numberOfSections {
    if ([self isKindOfClass:[UITableView class]]) {
        return [(UITableView *)self numberOfSections];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        return [(UICollectionView *)self numberOfSections];
    }
    
    return 0;
}

/** 刷新方法 */
- (void)movable_reloadData {
    if ([self isKindOfClass:[UITableView class]]) {
        return [(UITableView *)self reloadData];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        return [(UICollectionView *)self reloadData];
    }
}

/** 根据cell获取位置 */
- (NSIndexPath * _Nullable)movable_indexPathForCell:(UIView *)cell {
    if ([self isKindOfClass:[UITableView class]]) {
        return [(UITableView *)self indexPathForCell:(UITableViewCell *)cell];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        return [(UICollectionView *)self indexPathForCell:(UICollectionViewCell *)cell];
    }
    return nil;
}

/** 绘制移动中的cell */
- (void)movable_drawMovableCellAtIndexPath:(NSIndexPath *)indexPath {
    // 获取被点击的cell
    UIView *cell = [self movable_cellAtIndexPath:indexPath];
    
    // 截图
    self.tempMoveCell = [self movable_snapshotViewWithInputView:cell];
    
    // 进一步修饰截图
    if (self.drawMovableCellBlock) {
        self.drawMovableCellBlock(self.tempMoveCell);
    } else if (self.movableDelegate && [self.movableDelegate respondsToSelector:@selector(movable_scrollView:drawMovableCell:)]) {
        [self.movableDelegate movable_scrollView:self drawMovableCell:self.tempMoveCell];
    } else {
        // 配置默认样式
        self.tempMoveCell.layer.shadowColor = [UIColor grayColor].CGColor;
        self.tempMoveCell.layer.masksToBounds = NO;
        self.tempMoveCell.layer.cornerRadius = 0;
        self.tempMoveCell.layer.shadowOffset = CGSizeMake(-5, 0);
        self.tempMoveCell.layer.shadowOpacity = 0.4;
        self.tempMoveCell.layer.shadowRadius = 5;
    }
    
    self.tempMoveCell.frame = cell.frame;
    
    [self addSubview:self.tempMoveCell];
    //隐藏cell
    cell.hidden = YES;
}

/** 移动cell */
- (void)movable_moveCellFromIndexPath:(NSIndexPath *)from to:(NSIndexPath *)to {
    if ([self isKindOfClass:[UITableView class]]) {
        [(UITableView *)self moveRowAtIndexPath:from toIndexPath:to];
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        [(UICollectionView *)self moveItemAtIndexPath:from toIndexPath:to];
    }
}

/** 处理cell移动 */
- (void)movable_processCellMoveFrom:(NSIndexPath *)from to:(NSIndexPath *)to {
    // 两个位置不存在，则不可交换
    if (!to || !from) return ;
    // 位置相同，不可交换
    if ([from isEqual:to]) return ;
    // 判断两个位置cell是否有能力交换
    BOOL exhangeable = [self movable_isCellExchangeableFromIndexPath:from to:to];
    if (!exhangeable) return ;
    
    // 交换数据源
    [self movable_exchangeDataSourceFromIndexPath:from to:to];
    // 移动cell
    [self movable_moveCellFromIndexPath:from to:to];
    
    // 通知已经发生了移动交换
    if (self.movableDelegate && [self.movableDelegate respondsToSelector:@selector(movable_scrollView:cellDidMovedFromIndexPath:toIndexPath:)]) {
        [self.movableDelegate movable_scrollView:self cellDidMovedFromIndexPath:from toIndexPath:to];
    }
    
    // 设置新的起始位置
    self.originalIndexPath = to;
    
}


#pragma mark - getters and setters
- (id<DHMovableDelegate>)movableDelegate {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setMovableDelegate:(id<DHMovableDelegate>)movableDelegate {
    objc_setAssociatedObject(self, @selector(movableDelegate), movableDelegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<DHMovableDataSource>)movableDataSource {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setMovableDataSource:(id<DHMovableDataSource>)movableDataSource {
    objc_setAssociatedObject(self, @selector(movableDataSource), movableDataSource, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)isMovable {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setMovable:(BOOL)movable {
    objc_setAssociatedObject(self, @selector(isMovable), @(movable), OBJC_ASSOCIATION_COPY);
    if (movable) {
        [self movable_addGesture];
    } else {
        [self movable_removeGesture];
    }
}

- (BOOL)isAllExchangeable {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAllExchangeable:(BOOL)allExchangeable {
    objc_setAssociatedObject(self, @selector(isAllExchangeable), @(allExchangeable), OBJC_ASSOCIATION_COPY);
}

- (BOOL)isEdgeScrollEnable {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setEdgeScrollEnable:(BOOL)edgeScrollEnable {
    objc_setAssociatedObject(self, @selector(isEdgeScrollEnable), @(edgeScrollEnable), OBJC_ASSOCIATION_COPY);
}

- (UIEdgeInsets)edgeScrollInsets {
    return [objc_getAssociatedObject(self, _cmd) UIEdgeInsetsValue];
}
- (void)setEdgeScrollInsets:(UIEdgeInsets)edgeScrollInsets {
    objc_setAssociatedObject(self, @selector(edgeScrollInsets), [NSValue valueWithUIEdgeInsets:edgeScrollInsets], OBJC_ASSOCIATION_COPY);
}

- (NSTimeInterval)minimumResponseDuration {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setMinimumResponseDuration:(NSTimeInterval)minimumResponseDuration {
    minimumResponseDuration = MAX(0.2f, minimumResponseDuration);
    
    objc_setAssociatedObject(self, @selector(minimumResponseDuration), @(minimumResponseDuration), OBJC_ASSOCIATION_COPY);
}

- (CGFloat)movableCellAnimationDuration {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (void)setMovableCellAnimationDuration:(CGFloat)movableCellAnimationDuration {
    objc_setAssociatedObject(self, @selector(movableCellAnimationDuration), @(movableCellAnimationDuration), OBJC_ASSOCIATION_COPY);
}

- (void (^)(UIView * _Nonnull))drawMovableCellBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDrawMovableCellBlock:(void (^)(UIView * _Nonnull))drawMovableCellBlock {
    objc_setAssociatedObject(self, @selector(drawMovableCellBlock), drawMovableCellBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(NSIndexPath * _Nonnull, NSIndexPath * _Nonnull))exchangeDataSourceBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setExchangeDataSourceBlock:(void (^)(NSIndexPath * _Nonnull, NSIndexPath * _Nonnull))exchangeDataSourceBlock {
    objc_setAssociatedObject(self, @selector(exchangeDataSourceBlock), exchangeDataSourceBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIView *)tempMoveCell {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setTempMoveCell:(UIView *)tempMoveCell {
    objc_setAssociatedObject(self, @selector(tempMoveCell), tempMoveCell, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CADisplayLink *)edgeScrollTimer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setEdgeScrollTimer:(CADisplayLink *)edgeScrollTimer {
    objc_setAssociatedObject(self, @selector(edgeScrollTimer), edgeScrollTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSIndexPath *)originalIndexPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOriginalIndexPath:(NSIndexPath *)originalIndexPath {
    objc_setAssociatedObject(self, @selector(originalIndexPath), originalIndexPath, OBJC_ASSOCIATION_COPY);
}

- (UILongPressGestureRecognizer *)moveGesture {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setMoveGesture:(UILongPressGestureRecognizer *)moveGesture {
    objc_setAssociatedObject(self, @selector(moveGesture), moveGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
