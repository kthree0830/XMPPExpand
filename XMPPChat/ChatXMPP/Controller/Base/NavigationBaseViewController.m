//
//  NavigationBaseViewController.m
//  ChatXMPP
//
//  Created by mac on 2016/11/1.
//  Copyright © 2016年 KT. All rights reserved.
//

#import "NavigationBaseViewController.h"
#import "CUIBaseDef.h"
@interface NavigationBaseViewController ()

@end

@implementation NavigationBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBar.barTintColor = BaseColor;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//控制栏颜色
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
