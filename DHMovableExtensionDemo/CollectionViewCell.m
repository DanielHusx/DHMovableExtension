//
//  CollectionViewCell.m
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/16.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.nameLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
        self.nameLabel.textColor = [UIColor whiteColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.font = [UIFont systemFontOfSize:20];
        [self.contentView addSubview:self.nameLabel];
    }
    return self;
}
@end
