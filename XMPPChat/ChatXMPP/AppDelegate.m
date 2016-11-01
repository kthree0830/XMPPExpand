//
//  AppDelegate.m
//  ChatXMPP
//
//  Created by 周洪静 on 16/2/27.
//  Copyright © 2016年 KT. All rights reserved.
//

#import "AppDelegate.h"
#import "BaseController.h"
#import "NavigationBaseViewController.h"
#import "CUIBaseDef.h"
@interface AppDelegate ()

@end

@implementation AppDelegate
{
    UITabBarController * _tabBarController;
}

/**
 准备tabBarController
 */
-(NSString *)prepareTabBarItemTitleWithTag:(NSInteger)tag{
    return @[@"蓝信",@"通讯录",@"发现",@"我"][tag];
}
-(void)prepareTabBarContrller{
    _tabBarController = [[UITabBarController alloc]init];
    
    for (int i = 0; i<4; i++) {
        NavigationBaseViewController * navigationVC = [[NavigationBaseViewController alloc]initWithRootViewController:[[BaseController alloc]init]];
        navigationVC.tabBarItem.title = [self prepareTabBarItemTitleWithTag:i];
        _tabBarController.tabBar.selectedImageTintColor = BaseColor;
        [_tabBarController addChildViewController:navigationVC];
    }
   
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self prepareTabBarContrller];
    self.window  = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = _tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
