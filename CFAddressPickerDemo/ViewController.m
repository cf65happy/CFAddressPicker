//
//  ViewController.m
//  CFAddressPicker
//
//  Created by chenfei on 2018/12/7.
//  Copyright © 2018 chenfei. All rights reserved.
//

#import "ViewController.h"
#import "CFAddressPickerView.h"

@interface ViewController ()
{
    UILabel     *_label;
}

@property(nonatomic, copy) NSArray *selectedCitys;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _label = [[UILabel alloc] initWithFrame:self.view.bounds];
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CFAddressPickerView *addresPickerView = [[CFAddressPickerView alloc] init];
    addresPickerView.selectCitys = _selectedCitys;
    __weak typeof(self) _self = self;
    [addresPickerView showWithBlock:^(NSArray * _Nonnull selectCitys) {
        __strong typeof(_self) __self = _self;
        __self.selectedCitys = selectCitys;
    }];
}

- (void)setSelectedCitys:(NSArray *)selectedCitys {
    _selectedCitys = selectedCitys;
    NSMutableString *_str = [NSMutableString new];
    for (NSString *city in _selectedCitys) {
        [_str appendString:city];
    }
    _label.text = _str;
}

@end
