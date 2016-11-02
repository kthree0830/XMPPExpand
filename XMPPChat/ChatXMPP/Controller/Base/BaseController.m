//
//  BaseController.m
//  ChatXMPP
//
//  Created by mac on 2016/11/1.
//  Copyright © 2016年 KT. All rights reserved.
//

#import "BaseController.h"

@interface BaseController ()

@end

@implementation BaseController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
    
}
- (void)setupUI {
    UITableView * tabelView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tabelView.delegate = self;
    tabelView.dataSource = self;
    tabelView.backgroundColor = [UIColor redColor];
    [self.view addSubview:tabelView];
    self.baseTabelView = tabelView;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark - tableViewDelegate && dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * baseTabelViewCell = @"baseTabelViewCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:baseTabelViewCell];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:baseTabelViewCell];
    }
    return cell;
}

@end
