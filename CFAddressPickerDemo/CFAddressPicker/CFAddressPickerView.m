//
//  CFAddressPickerView.m
//  CFAddressPicker
//
//  Created by chenfei on 2018/12/4.
//  Copyright © 2018 chenfei. All rights reserved.
//

#import "CFAddressPickerView.h"

#define kCFScreenHeight       ([UIScreen mainScreen].bounds.size.height)
#define kCFScreenWidth        ([UIScreen mainScreen].bounds.size.width)

// 是否是iPhone X系列
#define kCF_iPhoneX (([UIScreen mainScreen].bounds.size.height/[UIScreen mainScreen].bounds.size.width) >= 2.16)

#define kCFBottomOffset   (kCF_iPhoneX?34:0)

#define kCFRGBHex(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define TAG_START  100

#pragma mark frame定义
static CGFloat leftPadding = 15;
static CGFloat titleHeight = 39;
static CGFloat headerHeight = 41;
static CGFloat closeWidth = 39;

@interface CFAddressPickerView ()<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
{
    UIControl   *_bg;
    UIView      *_headerView;
    UIView      *_selectline;
    NSMutableArray<CFCityModel *>  *_selectModels;
}

@property(nonatomic, copy) NSArray *dataSource;

/*
 * 标题
 */
@property(nonatomic, strong) UILabel    *titleLabel;
/*
 * 关闭按钮
 */
@property(nonatomic, strong) UIButton   *closeButton;

@property(nonatomic, strong) UIScrollView *scrollView;

@property(nonatomic, copy) CFAddressPickerViewBlock block;

@end

@implementation CFAddressPickerView

- (void)getData {
    NSString *path = [[NSBundle mainBundle]pathForResource:@"CityList" ofType:@"plist"];
    NSArray *arr = [[NSArray alloc] initWithContentsOfFile:path];
    self.dataSource = [self list:arr];
    if (self.selectCitys.count) {
        [self addCity:self.dataSource];
    }
}

- (void)addCity:(NSArray *)list {
    if (!_selectModels) {
        _selectModels = [NSMutableArray new];
    }
    for (CFCityModel *model in list) {
        if ([_selectCitys containsObject:model.name]) {
            [_selectModels addObject:model];
            if (model.list) {
                [self addCity:model.list];
            }
        }
    }
}

- (NSArray *)list:(NSArray *)list {
    NSMutableArray *_arr = [NSMutableArray new];
    for (NSDictionary *obj in list) {
        CFCityModel *model = [CFCityModel new];
        model.name = obj[@"name"];
        model.list = [self list:obj[@"list"]];
        [_arr addObject:model];
    }
    return _arr;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    self.frame = CGRectMake(0, kCFScreenHeight, kCFScreenWidth, 367+kCFBottomOffset);
    
    self.backgroundColor = [UIColor whiteColor];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.frame = CGRectMake(leftPadding, 0, kCFScreenWidth-leftPadding-closeWidth, titleHeight);
    _titleLabel.textColor = kCFRGBHex(0x303030);
    _titleLabel.text = @"请选择地址";
    _titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self addSubview:_titleLabel];
    
    _closeButton = [[UIButton alloc] init];
    [_closeButton addTarget:self action:@selector(hidden) forControlEvents:UIControlEventTouchUpInside];
    _closeButton.frame = CGRectMake(kCFScreenWidth-closeWidth, _titleLabel.center.y-closeWidth/2.0, closeWidth, closeWidth);
    [_closeButton setImage:[UIImage imageNamed:@"ic_menu_close"] forState:UIControlStateNormal];
    [self addSubview:_closeButton];
    
    _headerView = [[UIView alloc] init];
    _headerView.frame = CGRectMake(0, CGRectGetMaxY(_titleLabel.frame), kCFScreenWidth-leftPadding*2, headerHeight);
    [self addSubview:_headerView];
    UIView *line = [[UIView alloc] init];
    line.frame = CGRectMake(0, CGRectGetMaxY(_headerView.frame), kCFScreenWidth, 1);
    line.backgroundColor = kCFRGBHex(0xeeeeee);
    [self addSubview:line];
    
    _selectline = [[UIView alloc] init];
    _selectline.backgroundColor = kCFRGBHex(0xF95714);
    [line addSubview:_selectline];
    
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.frame = CGRectMake(0, CGRectGetMaxY(_headerView.frame)+1, kCFScreenWidth, (self.frame.size.height-(CGRectGetMaxY(_headerView.frame)+1)));
    [self addSubview:_scrollView];
}

- (void)setData {
    
    if (_selectModels.count) {
        //有选中的值
        for (int index = 0 ; index <_selectModels.count; index++) {
            UITableView *_tb = [[UITableView alloc] init];
            _tb.tag = index + TAG_START;
            _tb.delegate = self;
            _tb.dataSource = self;
            _tb.frame = CGRectMake(kCFScreenWidth*index, 0, kCFScreenWidth, _scrollView.frame.size.height);
            [_scrollView addSubview:_tb];
            UIView *footerView = [[UIView alloc] init];
            footerView.frame = CGRectMake(0, 0, kCFScreenWidth, kCFBottomOffset);
            _tb.tableFooterView = footerView;
        }
        _scrollView.contentSize = CGSizeMake(kCFScreenWidth*_selectModels.count, _scrollView.frame.size.height);
        [self layoutHeader];
        if ([[[_selectModels lastObject] list] count]) {
            [_scrollView setContentOffset:CGPointMake(kCFScreenWidth*_selectModels.count, 0) animated:NO];
        } else {
            [_scrollView setContentOffset:CGPointMake(kCFScreenWidth*(_selectModels.count-1), 0) animated:NO];
        }
    } else {
        UITableView *tableView = [[UITableView alloc] init];
        tableView.tag = 0 + TAG_START;
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.frame = CGRectMake(0, 0, kCFScreenWidth, _scrollView.frame.size.height);
        [_scrollView addSubview:tableView];
        UIView *footerView = [[UIView alloc] init];
        footerView.frame = CGRectMake(0, 0, kCFScreenWidth, kCFBottomOffset);
        tableView.tableFooterView = footerView;
        _scrollView.contentSize = CGSizeMake(kCFScreenWidth, _scrollView.frame.size.height);
        [self layoutHeader];
        [self changeLine:0+TAG_START];
    }
}

- (void)showWithBlock:(CFAddressPickerViewBlock)block {
    _block = block;
    [self show];
}

- (void)show {
    UIView *window = [UIApplication sharedApplication].keyWindow;
    if (!_bg) {
        UIControl *bg = [[UIControl alloc] init];
        bg.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        bg.frame = window.bounds;
        _bg = bg;
        [_bg addTarget:self action:@selector(hidden) forControlEvents:UIControlEventTouchUpInside];
    }
    [window addSubview:_bg];
    _bg.alpha = 0;
    [window addSubview:self];
    
    CGRect frame = self.frame;
    frame.origin.y = kCFScreenHeight-frame.size.height;
    [UIView animateWithDuration:0.35 animations:^{
        self->_bg.alpha = 1;
        self.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
    [self getData];
    [self setData];
}

- (void)hidden {
    CGRect frame = self.frame;
    frame.origin.y = kCFScreenHeight;
    [UIView animateWithDuration:0.35 animations:^{
        self.frame = frame;
        self->_bg.alpha = 0;
    } completion:^(BOOL finished) {
        [self->_bg removeFromSuperview];
        [self removeFromSuperview];
    }];
}

- (void)setTitle:(NSString *)title {
    _titleLabel.text = title;
}

#pragma mark tableView delegate&dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (tableView.tag == 0 + TAG_START) {
        return self.dataSource.count;
    }
    CFCityModel *selectModel = [_selectModels objectAtIndex:tableView.tag-TAG_START-1];
    return selectModel.list.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 41;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"tableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    NSArray *list;
    if (tableView.tag == 0 + TAG_START) {
        list = self.dataSource;
    } else {
        CFCityModel *selectModel = [_selectModels objectAtIndex:tableView.tag-TAG_START-1];
        list = selectModel.list;
    }
    CFCityModel *model = [list objectAtIndex:indexPath.row];
    cell.textLabel.textColor = kCFRGBHex(0x666666);
    
    if ([_selectModels containsObject:model]) {
        cell.textLabel.textColor = kCFRGBHex(0xF95714);
    }
    cell.textLabel.text = model.name;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    for (UITableView *_tb in _scrollView.subviews) {
        if (_tb.tag>tableView.tag) {
            [_tb removeFromSuperview];
        }
    }
    if (tableView.tag == 0 + TAG_START) {
        CFCityModel *model = [self.dataSource objectAtIndex:indexPath.row];
        
        UITableView *_tb = [self createTableView:tableView];
        
        if (![_selectModels containsObject:model]) {
            _selectModels = [NSMutableArray new];
            [_selectModels addObject:model];
        }
        [tableView reloadData];
        [_tb reloadData];
        [self layoutHeader];
        [_scrollView setContentOffset:CGPointMake(kCFScreenWidth*(tableView.tag-TAG_START+1), 0) animated:YES];
    } else {
        CFCityModel *selectModel = [_selectModels objectAtIndex:tableView.tag-TAG_START-1];
        //当前点击的数据
        CFCityModel *_currModel = [selectModel.list objectAtIndex:indexPath.row];

        if (![_selectModels containsObject:_currModel]) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(tableView.tag-TAG_START, _selectModels.count-(tableView.tag-TAG_START))];
            [_selectModels removeObjectsAtIndexes:indexSet];
            [_selectModels addObject:_currModel];
        }
        [tableView reloadData];
        if (!_currModel.list.count) {
            //没有下辖城市，取出选择的城市名称并回调
            NSMutableArray *_arr = [NSMutableArray new];
            for (CFCityModel *model in _selectModels) {
                [_arr addObject:model.name];
            }
            if (self.block) {
                self.block(_arr);
            }
            [self hidden];
        } else {
            UITableView *_tb = [self createTableView:tableView];
            [_tb reloadData];
            [self layoutHeader];
            [_scrollView setContentOffset:CGPointMake(kCFScreenWidth*(tableView.tag-TAG_START+1), 0) animated:YES];
        }
    }
    
}

- (void)layoutHeader {
    
    for (UIView * view in _headerView.subviews) {
        [view removeFromSuperview];
    }
    UIView *tempView;
    NSInteger count = 0;
    if (_selectModels.count && ![[[_selectModels lastObject] list] count]) {
        count = _selectModels.count - 1;
    } else {
        count = _selectModels.count;
    }
    CGFloat btnWidth = kCFScreenWidth/3.0;
    for (NSInteger i = 0; i <= count; i ++) {
        UIButton *button = [[UIButton alloc] init];
        button.tag = TAG_START + i;
        [_headerView addSubview:button];
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        if (i < _selectModels.count) {
            CFCityModel *model = [_selectModels objectAtIndex:i];
            [button setTitle:model.name forState:UIControlStateNormal];
            [button setTitleColor:kCFRGBHex(0x303030) forState:UIControlStateNormal];
        } else {
            [button setTitle:@"请选择" forState:UIControlStateNormal];
            [button setTitleColor:kCFRGBHex(0xF95714) forState:UIControlStateNormal];
        }
        [button addTarget:self action:@selector(headerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [button sizeToFit];
        btnWidth = button.frame.size.width>100?100:button.frame.size.width;
        if (!tempView) {
            button.frame = CGRectMake(leftPadding, 0, btnWidth, _headerView.frame.size.height);
        } else {
            button.frame = CGRectMake(CGRectGetMaxX(tempView.frame)+leftPadding, 0, btnWidth, _headerView.frame.size.height);
        }
        tempView = button;
    }
}

- (void)changeLine:(NSInteger)tag {
    UIButton *button = [_headerView viewWithTag:tag];
    button.hidden = NO;
    CGRect frame = button.frame;
    frame.origin.x = button.frame.origin.x;
    frame.origin.y = -2;
    frame.size.height = 2;
    frame.size.width = button.frame.size.width;
    [UIView animateWithDuration:0.35 animations:^{
        self->_selectline.frame = frame;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isKindOfClass:[UITableView class]]) {
        return;
    }
    NSInteger index = (CGFloat)scrollView.contentOffset.x/kCFScreenWidth;
    [self changeLine:index+TAG_START];
}

- (void)headerButtonClick:(UIButton *)sender {
    [_scrollView setContentOffset:CGPointMake(kCFScreenWidth*(sender.tag-TAG_START), 0) animated:YES];
}

- (UITableView *)createTableView:(UITableView *)tableView {
    UITableView *_tb = [[UITableView alloc] init];
    _tb.tag = tableView.tag + 1;
    _tb.delegate = self;
    _tb.dataSource = self;
    _tb.frame = CGRectMake(CGRectGetMaxX(tableView.frame), 0, kCFScreenWidth, _scrollView.frame.size.height);
    [_scrollView addSubview:_tb];
    UIView *footerView = [[UIView alloc] init];
    footerView.frame = CGRectMake(0, 0, kCFScreenWidth, kCFBottomOffset);
    _tb.tableFooterView = footerView;
    return _tb;
}

@end


@implementation CFCityModel

@end
