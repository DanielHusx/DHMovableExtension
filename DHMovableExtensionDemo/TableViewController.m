//
//  TableViewController.m
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import "TableViewController.h"
#import "UIScrollView+DHMovableExtension.h"

@interface TableViewController () <UITableViewDelegate, UITableViewDataSource, DHMovableDelegate, DHMovableDataSource>
@property (nonatomic, strong) UITableView *movableTable;
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dataSource = _section > 1 ? [self groupDataSourceWithCount:_section randomMax:_row]:[self plainDataSourceWithCount:_row];
    self.movableTable = _section > 1?[self groupTable]:[self plainTable];
    [self.view addSubview:self.movableTable];
}

- (void)setMovable:(BOOL)movable {
    _movable = movable;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[self.dataSource firstObject] isKindOfClass:[NSArray class]])
        return [self.dataSource count];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[self.dataSource firstObject] isKindOfClass:[NSArray class]])
        return [[self.dataSource objectAtIndex:section] count];
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    cell.textLabel.text = [[self.dataSource firstObject] isKindOfClass:[NSArray class]]? self.dataSource[indexPath.section][indexPath.row] : self.dataSource[indexPath.row];
    
    return cell;
}


#pragma mark - DHMovableDelegate, DHMovableDataSource
- (NSArray *)movable_dataSource:(UIScrollView *)scrollView {

    return [self.dataSource copy];
}

- (void)movable_scrollView:(UIScrollView *)scrollView dataSourceExchanged:(NSArray *)dataSource {
    self.dataSource = [dataSource copy];
}





#pragma mark - getters
- (UITableView *)plainTable {
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    
    return [self tableViewCommonConfig:tableView];
}

- (UITableView *)groupTable {
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    
    return [self tableViewCommonConfig:tableView];
}

- (UITableView *)tableViewCommonConfig:(UITableView *)tableView {
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.movable = _movable;
    tableView.movableDelegate = self;
    tableView.movableDataSource = self;
    tableView.edgeScrollEnable = _edgeScrollEnable;
    
    return tableView;
}

- (NSArray *)plainDataSourceWithCount:(NSUInteger)count {
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [temp addObject:[NSString stringWithFormat:@"%d", i]];
    }
    return [temp copy];
}

- (NSArray *)groupDataSourceWithCount:(NSUInteger)count randomMax:(NSUInteger)randomMax {
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSInteger subCount = arc4random() % randomMax + 1;
        NSMutableArray *sub = [NSMutableArray arrayWithCapacity:subCount];
        for (int j = 0; j < subCount; j++) {
            [sub addObject:[NSString stringWithFormat:@"%d-%d", i, j]];
        }
        [temp addObject:[sub copy]];
    }
    return [temp copy];
}

@end
