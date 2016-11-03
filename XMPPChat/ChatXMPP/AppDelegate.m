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
#import "ChatXMPP_Header.h"
@interface AppDelegate ()<KTXMPPManagerDelegate>

@end

@implementation AppDelegate
{
    UITabBarController * _tabBarController;
}

/**
 准备tabBarController
 */
- (UITabBarItem *)prepareTabBarItemWithDic:(NSDictionary *)itemDic {
    UITabBarItem * item = [[UITabBarItem alloc]init];
    item.title = itemDic[TabBarItemName];
    item.image = [UIImage imageNamed:itemDic[TabBarItemNormalImage]];
//    item.selectedImage = [[UIImage imageNamed:itemDic[TabBarItemSelectImage]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName:BaseColor} forState:UIControlStateSelected];
    return item;
}
- (NSString *)prepareClassNameWithTag:(NSInteger)tag {
    return @[@"ChatMainController"][tag];
}
- (void)prepareTabBarContrller {
    _tabBarController = [[UITabBarController alloc]init];
    //读取plist文件
    NSString * path = [[NSBundle mainBundle]pathForResource:@"TabBarItemList.plist" ofType:nil];
    NSArray * tabBarItemListArray = [NSArray arrayWithContentsOfFile:path];
    
    for (int i = 0; i<4; i++) {
        NavigationBaseViewController * navigationVC = [[NavigationBaseViewController alloc]initWithRootViewController:[[NSClassFromString([self prepareClassNameWithTag:0]) alloc]init]];
        navigationVC.tabBarItem = [self prepareTabBarItemWithDic:tabBarItemListArray[i]];
        if (i == 0) {
            [KTXMPPManager defaultManager].tabbarItem = navigationVC.tabBarItem;
        }
        _tabBarController.tabBar.selectedImageTintColor = BaseColor;
        [_tabBarController addChildViewController:navigationVC];
    }
   
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self prepareTabBarContrller];
    self.window  = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = _tabBarController;
    [self.window makeKeyAndVisible];
    
    /*
        根据项目需求做引导页
        根据项目需求做版本判断
        根据项目需求做推送注册
        根据项目需求做第三方登录，第三方分享等一系列的注册
        根据项目需求做登录前的判断（第一次可做登录和注册等，并存储用户名、密码等，注册时同时注册XMPP）
        根据项目需求做XMPP的登录
     */
    /*
        本例中，模仿已使用APP后的二次使用（即非第一次使用）
        设定：第一次登录和注册时 用户XMPP的 用户名，密码 使用NSUserDefault存储，分别对应KT_XMPPJid和KT_XMPPPassword
        注册方法:  [[KTXMPPManager defaultManager]registerXMPP];
     
     */
    //登录(登录和注册的方法应该放到相应的控制器中，而不是这里)
//    [KTXMPPManager defaultManager].delegate = self;
//    [[KTXMPPManager defaultManager]loginXMPP];
    UserDefaultSetObjectForKey(@"test", KT_XMPPJid);
    [NearChatManager defaultManagerWithJid:UserDefaultObjectForKey(KT_XMPPJid)];
    
    [KTXMPPManager defaultManager].tabbarItem.badgeValue = [[NearChatManager defaultManager] findAllSign];
    
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
#pragma mark -KTXMPPManagerDelegate
/**登陆xmpp的结果*/
- (void)loginXMPPRsult:(BOOL)ret{

}
/**注册xmpp的结果 成功并登录*/
- (void)registerXMPPRsult:(BOOL)ret {

}
/**单点登陆*/
- (void)aloneLoginXMPP:(BOOL)ret{

}

@end
