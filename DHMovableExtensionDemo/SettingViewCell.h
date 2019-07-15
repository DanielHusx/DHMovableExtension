//
//  SettingViewCell.h
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SettingViewCell : UITableViewCell <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UISwitch *movableSwitch;
@property (weak, nonatomic) IBOutlet UITextField *rowTF;
@property (weak, nonatomic) IBOutlet UITextField *sectionTF;
@property (weak, nonatomic) IBOutlet UISwitch *edgeSwitch;

@end

NS_ASSUME_NONNULL_END
