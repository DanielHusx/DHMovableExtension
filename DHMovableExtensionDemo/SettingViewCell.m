//
//  SettingViewCell.m
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import "SettingViewCell.h"

@implementation SettingViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = textField.text;
    BOOL delete = [string isEqualToString:@""];
    
    if (text.length == 2 && !delete) return NO;
    if (!delete) {
        char character = [string characterAtIndex:0];
        if (character > '0' && character < '9') return YES;
        return NO;
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.text.length == 0) {
        textField.text = @"1";
    }
}



@end
