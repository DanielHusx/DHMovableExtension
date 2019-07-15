//
//  ViewController.m
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import "ViewController.h"
#import "TableViewController.h"
#import "CollectionViewController.h"
#import "SettingViewCell.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *configTable;
@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, assign) NSUInteger row;
@property (nonatomic, assign) NSUInteger section;
@property (nonatomic, assign) BOOL movable;
@property (nonatomic, assign) BOOL edgeScrollEnable;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _movable = YES;
    _edgeScrollEnable = YES;
    _row = 20;
    _section = 1;
    
    [self.configTable reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"cell";
    SettingViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    cell.nameLabel.text = indexPath.row == 0 ?@"UITableView":@"UICollectionView";
    cell.movableSwitch.on = _movable;
    cell.edgeSwitch.on = _edgeScrollEnable;
    cell.rowTF.text = [NSString stringWithFormat:@"%zd",_row];
    cell.sectionTF.text = [NSString stringWithFormat:@"%zd",_section];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.view endEditing:YES];
    
    SettingViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    _movable = cell.movableSwitch.on;
    _edgeScrollEnable = cell.edgeSwitch.on;
    _section = [cell.sectionTF.text integerValue];
    _row = [cell.rowTF.text integerValue];
    NSString *segueId = cell.nameLabel.text;
    
    [self performSegueWithIdentifier:segueId sender:nil];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [segue.destinationViewController setValue:@(self.movable) forKey:@"movable"];
    [segue.destinationViewController setValue:@(self.section) forKey:@"section"];
    [segue.destinationViewController setValue:@(self.row) forKey:@"row"];
    [segue.destinationViewController setValue:@(self.edgeScrollEnable) forKey:@"edgeScrollEnable"];
}


@end
