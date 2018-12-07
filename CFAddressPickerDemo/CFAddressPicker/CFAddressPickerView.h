//
//  CFAddressPickerView.h
//  test
//
//  Created by chenfei on 2018/12/4.
//  Copyright © 2018 chenfei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CFAddressPickerViewBlock)(NSArray *selectCitys);

@interface CFAddressPickerView : UIView

@property(nonatomic, copy) NSString *title;

//选择的城市名称数组，例 @[@"北京",@"海淀区"]
@property(nonatomic, copy) NSArray *selectCitys;


- (void)showWithBlock:(CFAddressPickerViewBlock)block;

@end


#pragma mark 数据模型

@interface CFCityModel : NSObject

@property(nonatomic, copy) NSString *name;

@property(nonatomic, copy) NSArray<CFCityModel *> *list;

@end


NS_ASSUME_NONNULL_END
