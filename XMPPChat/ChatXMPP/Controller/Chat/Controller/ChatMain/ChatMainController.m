//
//  ChatMainController.m
//  ChatXMPP
//
//  Created by mac on 2016/11/2.
//  Copyright © 2016年 KT. All rights reserved.
//

#import "ChatMainController.h"

@interface ChatMainController ()<KTXMPPManagerDelegate>
@property (nonatomic, strong)NSMutableArray * dataArray;
@end

@implementation ChatMainController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];

}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [KTXMPPManager defaultManager].delegate = self;
    [self needReload];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}
- (void)dealloc
{
    [KTXMPPManager defaultManager].delegate = nil;
}
#pragma mark - lazy
- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc]init];
    }
    return _dataArray;
}
#pragma mark - data
- (void)needReload {
    //1.准备数据(进入页面时，和新消息时调用)
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataArray = [[[NearChatManager defaultManager]findAllNearChatModel] mutableCopy];
        [self.baseTabelView reloadData];
    });
}
#pragma mark - tableViewDelegate && dataSoucre
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * baseTabelViewCell = @"baseTabelViewCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:baseTabelViewCell];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:baseTabelViewCell];
    }
    cell.textLabel.text = @"测试";
    return cell;
}
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self)weakSelf = self;
    UITableViewRowAction * delAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        // 此方法会刷新数据源方法
//        [weakSelf.baseTabelView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    delAction.backgroundColor = [UIColor redColor];
    UITableViewRowAction * readAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"标记已读" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
    }];
    readAction.backgroundColor = [UIColor grayColor];
    return @[delAction,readAction];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}
#pragma mark - KTXMPPManagerDelegate
- (void)receiveNewMessageOnChatMain {
    [self needReload];
}
@end
