//
//  TableViewController.h
//  DHMovableExtensionDemo
//
//  Created by Daniel on 2019/7/15.
//  Copyright © 2019 Daniel. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TableViewController : UIViewController


@property (nonatomic, assign) NSUInteger row;
@property (nonatomic, assign) NSUInteger section;
@property (nonatomic, assign) BOOL movable;
@property (nonatomic, assign) BOOL edgeScrollEnable;
@end

NS_ASSUME_NONNULL_END
