//
//  CollectionViewController.m
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import "CollectionViewController.h"
#import "CollectionViewCell.h"
#import "UIScrollView+DHMovableExtension.h"

#define angelToRandian(x)  ((x)/180.0*M_PI)

@interface CellModel : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) UIColor *color;
+ (instancetype)modelWithName:(NSString *)name color:(UIColor *)color;
@end

@implementation CellModel

+ (instancetype)modelWithName:(NSString *)name color:(UIColor *)color {
    CellModel *model = [[CellModel alloc] init];
    model.name = name;
    model.color = color;
    return model;
}

@end

@interface CollectionViewController () <UICollectionViewDelegate, UICollectionViewDataSource, DHMovableDelegate, DHMovableDataSource>

@property (nonatomic, strong) UICollectionView *movableCollection;
@property (nonatomic, strong) NSArray *dataSource;
@end

@implementation CollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
     _dataSource = _section > 1 ? [self groupDataSourceWithCount:_section randomMax:_row]:[self plainDataSourceWithCount:_row];
    self.movableCollection = [self configCollection];
    [self.view addSubview:self.movableCollection];
}


#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([[self.dataSource firstObject] isKindOfClass:[NSArray class]])
        return [self.dataSource count];
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([[self.dataSource firstObject] isKindOfClass:[NSArray class]])
        return [[self.dataSource objectAtIndex:section] count];
    return [self.dataSource count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cell";
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    
    CellModel *model = [[self.dataSource firstObject] isKindOfClass:[NSArray class]]? self.dataSource[indexPath.section][indexPath.row] : self.dataSource[indexPath.row];
    cell.nameLabel.text = model.name;
    cell.backgroundColor = model.color;
    return cell;
    
}

#pragma mark - DHMovableDelegate, DHMovableDataSource
- (NSArray *)movable_dataSource:(UIScrollView *)scrollView {
    
    return [self.dataSource copy];
}

- (void)movable_scrollView:(UIScrollView *)scrollView dataSourceExchanged:(NSArray *)dataSource {
    self.dataSource = [dataSource copy];
}

// !!!: 简单的动画尝试，将此方法放入代理者下即可
- (void)movable_scrollView:(UICollectionView *)scrollView movableCell:(UIView *)movableCell willMoveFromIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat shakeLevel = 4.0;
    CAKeyframeAnimation* anim=[CAKeyframeAnimation animation];
    anim.keyPath=@"transform.rotation";
    anim.values=@[@(angelToRandian(-shakeLevel)), @(angelToRandian(shakeLevel)),@(angelToRandian(-shakeLevel))];
    anim.repeatCount=MAXFLOAT;
    anim.duration=0.2;
    NSArray *cells = [scrollView visibleCells];
    for (UICollectionViewCell *cell in cells) {
        if (indexPath == [scrollView indexPathForCell:cell]) {
            continue;
        }
        /**如果加了shake动画就不用再加了*/
        if (![cell.layer animationForKey:@"shake"]) {
            [cell.layer addAnimation:anim forKey:@"shake"];
        }
        //顺便设置各个cell的hidden属性，由于有cell被hidden，其hidden状态可能被冲用到其他cell上
        BOOL hidden = indexPath && [scrollView indexPathForCell:cell].item == indexPath.item && [scrollView indexPathForCell:cell].section == indexPath.section;
        cell.hidden = hidden;
    }
    if (![movableCell.layer animationForKey:@"shake"]) {
        [movableCell.layer addAnimation:anim forKey:@"shake"];
    }
}

- (void)movable_scrollView:(UIScrollView *)scrollView movableCell:(UIView *)movableCell didEndMovedAtIndexPath:(NSIndexPath *)indexPath {
    [movableCell.layer removeAllAnimations];
}


#pragma mark - getters
- (UICollectionView *)configCollection {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(100, 100);
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor whiteColor];
    [collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    return [self collectionViewCommonConfig:collectionView];
}

- (UICollectionView *)collectionViewCommonConfig:(UICollectionView *)collectionView {
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.movable = _movable;
    collectionView.movableDelegate = self;
    collectionView.movableDataSource = self;
    collectionView.edgeScrollEnable = _edgeScrollEnable;
    
    return collectionView;
}

- (NSArray *)plainDataSourceWithCount:(NSUInteger)count {
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:count];
    UIColor *randColor = [self randColor];
    for (int i = 0; i < count; i++) {
        [temp addObject:[CellModel modelWithName:[NSString stringWithFormat:@"%d", i] color:randColor]];
    }
    return [temp copy];
}

- (UIColor *)randColor {
    return [UIColor colorWithRed:arc4random()%255/255.0 green:arc4random()%255/255.0 blue:arc4random()%255/255.0 alpha:1];
}

- (NSArray *)groupDataSourceWithCount:(NSUInteger)count randomMax:(NSUInteger)randomMax {
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSInteger subCount = arc4random() % randomMax + 1;
        NSMutableArray *sub = [NSMutableArray arrayWithCapacity:subCount];
        UIColor *randColor = [self randColor];
        for (int j = 0; j < subCount; j++) {
            
            [sub addObject:[CellModel modelWithName:[NSString stringWithFormat:@"%d-%d", i, j] color:randColor]];
        }
        [temp addObject:[sub copy]];
    }
    return [temp copy];
}

@end
