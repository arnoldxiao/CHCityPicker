//
//  CHCityPickerViewController.m
//  CHCityPicker
//
//  Created by APP on 16/1/7.
//  Copyright © 2016年 Personal. All rights reserved.
//

#import "CHCityPickerViewController.h"
#import "CHCityListCell.h"
#import "NSString+Enhance.h"

@interface CHCityPickerViewController () <UITableViewDataSource, UITableViewDelegate>
{
    /**
     *  内部是字典，key分别有id,city,pinyin
     */
    NSArray *citys;
    
    /**
     *  内部字典，key分别从A-Z，value是数组对象，分别存放着对应的citys内部的字典
     */
    NSMutableArray *cityGroupArray;
    
    /**
     *  Cell类型
     */
    CHCityListCellType listCellType;
    
    /**
     *  历史访问城市列表
     */
    NSMutableArray *historyCitys;
    
    /**
     *  热门城市列表
     */
    NSMutableArray *hotCitys;
}
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL didConstraint;
@end

@implementation CHCityPickerViewController

- (instancetype)init {
    if (self = [super init]) {
        [self initCityData];
    }
    return self;
}

//  初始化城市数据
- (void)initCityData {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        citys = [self analysisJSONDataWithString:[NSString stringWithFileName:@"cityList" type:@"json"]];
        
        cityGroupArray = [NSMutableArray arrayWithCapacity:citys.count];
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithCapacity:26];

        for (int i = 65; i <= 90; i++) {
            NSString *tmpKey = [NSString stringwithInt:i needUpper:YES];
            NSMutableArray *tmpValue = [NSMutableArray array];
            for (int j = 0; j < citys.count; j++) {
                NSString *capital = [citys[j][@"pinyin"] capitalNeedUpper:YES];
                if (capital == tmpKey) {
                    [tmpValue addObject:citys[j]];
                }
            }
            [tmpDict setObject:tmpValue forKey:tmpKey];
        }
        [cityGroupArray addObject:tmpDict];
    });
}

- (NSArray *)historyCitys {
    if (!historyCitys) {
        [historyCitys addObject:@"深圳"];
        [historyCitys addObject:@"广州"];
        [historyCitys addObject:@"上海"];
    }
    return historyCitys;
}

- (NSArray *)hotCitys {
    if (!hotCitys) {
        NSArray *tmpArray = [NSArray arrayWithObjects:@"上海", @"北京", @"广州", @"深圳", @"天津", @"杭州", @"南京", @"武汉", @"成都", @"沈阳", @"西安", nil];
        [hotCitys addObjectsFromArray:tmpArray];
    }
    return hotCitys;
}

/**
 *  根据JSON文件内容，解析JSON
 *
 *  @param jsonString JSON文件内容
 *
 *  @return 字典内部的数组，解析失败则返回nil
 */
- (NSArray *)analysisJSONDataWithString:(NSString *)jsonString {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)object objectForKey:@"citys"];
    } else {
        NSLog(@"JSON解析失败！！");
        return nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = kColorF0F0F0;
    self.navigationItem.title = @"请选择城市";
    [self setupLayout];
}

- (void)setupLayout {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.closeButton];
    [self.view addSubview:self.tableView];
    
    [self.view setNeedsUpdateConstraints];
}

- (void)updateViewConstraints {
    if (!self.didConstraint) {
        //  tableView - AutoLayout
        [self.tableView autoPinEdgesToSuperviewEdges];
        
        self.didConstraint = YES;
    }
    [super updateViewConstraints];
}

#pragma mark  - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3 + cityGroupArray.count;            //  定位城市 + 最近访问城市 + 热门城市 +
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 3) {
        return 1;
    }
//    NSDictionary *tmpDict = [cityGroupArray objectAtIndex:section - 3];
//    NSString *capital = [NSString stringwithInt:(int)section + 62 needUpper:YES];
//    NSArray *tmpArray = [tmpDict objectForKey:capital];
//    return tmpArray.count;
    return [self getArrayWithArray:cityGroupArray section:section].count;
}

- (NSArray *)getArrayWithArray:(NSArray *)array section:(NSInteger)section {
    id tmpobj1 = [cityGroupArray objectAtIndex:section - 3];
    if ([tmpobj1 isKindOfClass:[NSDictionary class]]) {
        NSString *capital = [NSString stringwithInt:(int)section + 62 needUpper:YES];
        id tmpobj2 = [tmpobj1 objectForKey:capital];
        if ([tmpobj2 isKindOfClass:[NSArray class]]) {
            return tmpobj2;
        } else {
            NSLog(@"【2】获取JSON内部数据失败");
            return nil;
        }
    } else {
        NSLog(@"【1】获取JSON内部数据失败");
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CHCityListCell *cell = nil;
    if (indexPath.section >= 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierSystem];
        if (!cell) {
            cell = [[CHCityListCell alloc] initWithCityListCellType:CHCityListCellTypeSystem array:nil identifier:cellIdentifierSystem];
        }
        NSArray *tmpArray = [self getArrayWithArray:cityGroupArray section:indexPath.section];
        NSString *title = [tmpArray[indexPath.row] objectForKey:@"city"];
        [cell setCellTitle:title array:nil type:CHCityListCellTypeSystem];
    } else if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierButton];
        if (!cell) {
            cell = [[CHCityListCell alloc] initWithCityListCellType:CHCityListCellTypeButton array:nil identifier:cellIdentifierButton];
        }
        //  TODO：定位
    }
    else {
        NSArray *array = (indexPath.section == 1) ? historyCitys : hotCitys;        //  indexPath.section == 2  -->  hot
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifierButton];
        if (!cell) {
            cell = [[CHCityListCell alloc] initWithCityListCellType:CHCityListCellTypeButton array:array identifier:cellIdentifierButton];
        }
        [cell setCellTitle:nil array:array type:CHCityListCellTypeButton];
    }
    
    
    return cell;
}

#pragma mark - Close - Event
- (void)closeButtonPressed:(UIButton *)btn {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 懒加载
- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        [_closeButton setImage:[UIImage imageNamed:@"btn_close"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton sizeToFit];
    }
    return _closeButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = kColor(orangeColor);
    }
    return _tableView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
