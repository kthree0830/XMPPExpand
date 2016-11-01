//
//  KTXMPPManager.m
//  ChatXMPP
//
//  Created by 周洪静 on 16/2/27.
//  Copyright © 2016年 KT. All rights reserved.
//

#import "KTXMPPManager.h"
//宏
#import "ChatXMPP_Header.h"
//xmpp
#import "XMPPFramework.h"//这个头文件里边的东西很重要，IM能用到的协议里边基本都包含了
#import "XMPP.h"//Basis
#import "XMPPReconnect.h"//连接相关
#import "XMPPCapabilities.h"
#import "GCDAsyncSocket.h"
#import "XMPPMessage.h"//消息相关
//聊天记录
#import "NearChatManager.h"
//工具
#import "Photo.h"

static const NSString * defaultChatPerson = @"noChatPerson";
@interface KTXMPPManager ()
/**当前联系人*/
@property (nonatomic,copy)NSString * nowChatPerson;
@end
@implementation KTXMPPManager
{
    NSUserDefaults * _userDefaults;
    NSString * _myPassword;//用户密码
    BOOL isRegister;//是否为注册
    
    XMPPStream * _xmppStream;//xmpp主要流
    XMPPReconnect * _xmppReconnect;
    XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingCoreDataStorage;//信息列表
    XMPPMessageArchiving *xmppMessageArchivingModule;//与上合用，消息归档

    BOOL allowSelfSignedCertificates;
    BOOL allowSSLHostNameMismatch;
    
}
static KTXMPPManager * basisManager = nil;
+(KTXMPPManager *)defaultManager
{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        basisManager = [[KTXMPPManager alloc]init];
    });
    return basisManager;
}
-(instancetype)init
{
    if (self = [super init]) {
        [self setupStream];    }
    return self;
}
#pragma mark - 
#pragma mark - public
-(NSManagedObjectContext *)messageManageObjectContext
{
    return [xmppMessageArchivingCoreDataStorage  mainThreadManagedObjectContext];
}

//设置当前联系人
- (void)setNowChatPerson:(NSString *)nowChatPerson
{
    if (!nowChatPerson || !nowChatPerson.length) {
        _nowChatPerson = [defaultChatPerson copy];
    }else{
        _nowChatPerson = nowChatPerson;
        [NearChatManager defaultManagerWithJid:nowChatPerson];
    }
    
}

//连接
- (BOOL)connect
{
    if (![_xmppStream isDisconnected])//如果xmpp未断开链接
    {
        return YES;
    }
    //1.从userdefaults中提取账户和密码，所以在登录APP的时候需要记录用户的账户和密码
    //xmpp中Jid为我们俗称的账号ID
    NSString * myJid = [_userDefaults objectForKey:KT_XMPPJid];
    //密码
    NSString * myPassword = [_userDefaults objectForKey:KT_XMPPPassword];
    if (0 == myJid.length || 0 == myPassword.length) {
        UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"警告" message:@"请检查是否输入了用户名或密码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alertView show];
        return NO;
    }
    //设置xmpp流的帐号，domain为主机名(非iP地址)，resource资源名：用于区分用户
    [_xmppStream setMyJID:[XMPPJID jidWithUser:myJid domain:KT_XMPPDomain resource:KT_XMPPResources]];
    _myPassword = myPassword;
    NSError *error = nil;
    //进行连接
    /*
     连接过程
     1.连接服务器 connectWithTimeout
     2.验证密码 authenticateWithPassword(成功或失败)
     */
    if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        NSLog(@"连接错误");
        
        UIAlertView*al=[[UIAlertView alloc]initWithTitle:@"服务器连接失败" message:nil delegate:self cancelButtonTitle:@"ok" otherButtonTitles: nil];
        [al show];
        
        return NO;
    }
    return YES;
}
//登录
- (void)loginXMPP
{
    isRegister = NO;
    //先 连接服务器 再 认证用户米密码
    [self connect];
}
//注册
-(void)registerXMPP
{
/*
    注册和登录的相同之处:两者都需要连接服务器
            的不同之处:登录在连接成功后验证密码，而注册为注册用户
 */
    isRegister = YES;
    //先 连接服务器 再 注册用户密码
    [self connect];
}
//设置代理和当前通信联系人
- (void)setKTXMPPDelegate:(id<KTXMPPManagerDelegate>)delegate nowChatPerson:(NSString *)nowChatPerson {
    self.delegate = delegate;
    self.nowChatPerson = nowChatPerson;
}


//获得消息
-(NSArray *)XMPPMessageRecordWithJid:(NSString *)Jid
{
    /*
     关于xmpp的消息存储，可由openfire服务器设置，可在openfire控制台上选择推送消息的数量，可选：全部推送或定量推送(自行设置个数)，默认为全部推送，即与某一个JID的所有聊天记录推送到客户端
     
     ＝＝＝＝＝友情提示＝＝＝＝
     虽然xmpp协议帮助我们坐了存储，但鉴于实际中可能会有个别信息会动态变化，且xmpp使用的是coredata存储方式，更改数据库操作需要更改xmpp协议源码，所以推荐大家自行创建数据库，进行存储
     ＝＝＝＝＝＝＝＝＝＝＝＝＝
     */
    //获得上下文
    NSManagedObjectContext *context = [xmppMessageArchivingCoreDataStorage  mainThreadManagedObjectContext];
    //获得实体Entity
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:context];
    
    //此刻需要使用的JID，要求是id＋@＋主机名
    if (![Jid hasSuffix:KT_XMPPDomain]) {
        Jid = [Jid stringByAppendingFormat:@"@%@",KT_XMPPDomain];
    }
    //自己的JID
    NSString * myJid = [_userDefaults objectForKey:KT_XMPPJid];
    
    //谓词搜索当前联系人的信息
    /*
     bareJidStr -> 对方
     streamBareJidStr -> 自己
     */
    NSPredicate*predicate=[NSPredicate predicateWithFormat:@"bareJidStr==%@&&streamBareJidStr==%@",Jid,myJid];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entityDescription];
    // 按照时间进行筛选(时间为一小时内的)
    NSDate *endDate = [NSDate date];
    NSTimeInterval timeInterval= [endDate timeIntervalSinceReferenceDate];
    timeInterval -=3600;
    NSDate *beginDate = [NSDate dateWithTimeIntervalSinceReferenceDate:timeInterval] ;
    NSPredicate *predicate_date =[NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", beginDate,endDate];
    [request setPredicate:predicate_date];//筛选时间
    
    [request setPredicate:predicate];//筛选条件
    /*
     此处还可做分页查询:(需要更改方法:增加一个参数为当前页的参数，再按照分页查询的代码
     [request setFetchLimit:10];
     [request setFetchOffset:currentPage*10];
     currentPage当前页数，每页10条
     
     按时间排序除上面举例的方法外，还可以用：根据key排序的方法:
     NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"timestamp" ascending:NO];
     NSArray * array = [NSArray arrayWithObjects:sortDescriptor, nil];
     [request setSortDescriptors:array];
     ascending:NO逆向排序，从大到小
     array的意义在于如果timestamp的大小一样，可以按照第二个key来排序，将第二个NSSortDescriptor加入到array中
     
     */
    NSError *error ;
    NSArray *messages = [context executeFetchRequest:request error:&error];
    /*
     此时返回的messages数组中的数据类型为：XMPPMessageArchiving_Message_CoreDataObject
     这是xmpp自带的coredata实体，可在导航栏中搜索查到，在这里简要介绍：
     1.XMPPMessage * message -> 所有消息在xmpp中存在的方式，xml格式，可以通过此属性获得，消息内容，消息来源JID，消息去向JID，消息类型，错误消息等信息
     message.fromStr;
     message.toStr;
     通过以上两个属性可以判断出消息的真实发送方和接收方(在聊天页面中使用)
     2.NSString * messageStr -> 此条消息的字符串形式
     3.XMPPJID * bareJid     -> 此条消息的来源JID
     4.NSString * bareJidStr -> 此条消息的来源JID，一直为对方(上面用此熟悉做谓词搜索)
     5.NSString * body       -> 此条消息body节点中的字符串
     6.NSString * thread     -> 此条消息的线程（目前不知道做何用）
     7.NSNumber * outgoing
     BOOL isOutgoing       -> 此条消息是否为发出YES为自己发出
     8.NSNumber * composing
     BOOL isComposing      -> 此条消息是否已读(消息回执)
     9.timestamp             -> 此条消息的发送时间
     10.streamBareJidStr     -> 此条消息的接收方，一直为自己(上面用此熟悉做谓词搜索)
     */
    
    
    return messages;

}
-(void)sendMessage:(id)message toJid:(NSString *)jid isGroupChat:(BOOL)isGroupChat messageType:(KTTMessageType)messageType
{
    /*
     XMPP的消息发送：组成xml格式进行发送
     */
    XMPPMessage * mes = nil;
    NSString * trueMessage = nil;
    if (!isGroupChat) {
        //单聊
        mes = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithUser:jid domain:KT_XMPPDomain resource:KT_XMPPResources]];
    }else{
        /*
            XMPP的群聊用广播的形式完成，即 多个用户订阅同一个广播 当有人向这个广播发送消息时，所有的订阅者都会接收到消息，
            以用来完成群聊的逻辑
            这种方法需要服务器安装broadcast插件
         */
        mes = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithUser:jid domain:KT_XMPPGroupDomain resource:KT_XMPPResources]];

    }
    trueMessage = [self messageElmentWith:message messageType:messageType];
    if (!trueMessage) {
        //如果是不合法的消息此处直接返回，不做发送
        if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:result:error:)]) {
            [self.delegate sendMessage:mes result:NO error:KT_Message_Error_BeNil];
            return;
        }
    }
    [mes addChild:[DDXMLNode elementWithName:@"body" stringValue:trueMessage]];
    [_xmppStream sendElement:mes];

}
#pragma mark -
#pragma mark - private

/**
 组建消息体

 @param message 消息内容
 @param messageType 消息类型
 @return 调整后的消息内容
 */
- (NSString *)messageElmentWith:(id)message messageType:(KTTMessageType)messageType{
    /*
        可在此方法中将消息的内容转换为所需要的类型，如均为string类型，具体类型可按具体项目情况更改
     */
    UIImage * image = nil;//图片消息备用
    switch (messageType) {
        case KTTTextMessage:
            return (NSString *)message;
            break;
        case KTTImageMessage:
            image = (UIImage *)message;
            return [Photo image2String:image];
            break;
        case KTTVoiceeMessage:
            return nil;
            break;
        default:
            return nil;
            break;
    }
}
#pragma mark -
#pragma mark - 关于xmpp的初始化
//初始化设置xmppStream
-(void)setupStream
{
    NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _xmppStream = [[XMPPStream alloc]init];
#if !TARGET_IPHONE_SIMULATOR
    {
        //是否允许后台连接
        _xmppStream.enableBackgroundingOnSocket = YES;
    }
#endif
    //自动重连 并激活
    _xmppReconnect = [[XMPPReconnect alloc]init];
    [_xmppReconnect activate:_xmppStream];
    //设置代理
    /*
     xmpp本身为串行队列，如果加到主队列中必然会造成性能的下降
     */
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    
    [_xmppStream setHostName:KT_XMPPIP];//设置主机IP
    [_xmppStream setHostPort:KT_XMPPPort];//设置主机端口
    
    // You may need to alter these settings depending on the server you're connecting to
    //您可能需要改变这些设置取决于您连接到的服务器
    allowSelfSignedCertificates = NO;
    allowSSLHostNameMismatch = NO;
    
    //TODO：消息模块的激活
    xmppMessageArchivingCoreDataStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    xmppMessageArchivingModule = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:xmppMessageArchivingCoreDataStorage];
    [xmppMessageArchivingModule setClientSideMessageArchivingOnly:YES];
    [xmppMessageArchivingModule activate:_xmppStream];
    [xmppMessageArchivingModule addDelegate:self delegateQueue:dispatch_get_main_queue()];

}
#pragma mark -
#pragma mark - XMPPStreamDelegate
- (void)xmppStreamWillConnect:(XMPPStream *)sender
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
}
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    //验证密码
    NSError *error = nil;
    if (isRegister) {
        //注册
        if (![_xmppStream registerWithPassword:_myPassword error:&error]) {
            NSLog(@"Error register: %@",error);
        }
    }else{
        //登录
        if (![_xmppStream authenticateWithPassword:_myPassword error:&error])
        {
            NSLog(@"Error authenticating: %@", error);
        }

    }
}
//登录验证通过
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"完成认证，发送在线状态");
    //发送个人状态
    [self goOnline];
    
    if ([self.delegate respondsToSelector:@selector(loginXMPPRsult:)]) {
        [self.delegate loginXMPPRsult:YES];
    }
}
//登录验证错误
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@"认证错误");
    //断开连接
    [_xmppStream disconnect];
    if ([self.delegate respondsToSelector:@selector(loginXMPPRsult:)]) {
        [self.delegate loginXMPPRsult:NO];
    }
}
//注册成功
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    if ([self.delegate respondsToSelector:@selector(registerXMPPRsult:)]) {
        [self.delegate registerXMPPRsult:YES];
    }
}
//注册失败
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{
    NSLog(@"Error didNotRegister %@",error);
    if ([self.delegate respondsToSelector:@selector(registerXMPPRsult:)]) {
        [self.delegate registerXMPPRsult:NO];
    }
}
//发送消息成功
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    //消息发送成功并不代表消息发送到对方客户端，而是服务器成功接收
    NSString * toJid = message.to.user;
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:result:error:)] && [_nowChatPerson isEqualToString:toJid]) {
        [self.delegate sendMessage:message result:YES error:nil];
        //TODO:可优化，如果自己建立聊天记录本地数据库的话，可在此处完成聊天记录model模型的赋值
    }
    //做最近聊天数据存储
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NearChatModel * model = [[NearChatModel alloc]init];
        model.chatPartnerJid = toJid;
        model.xmppBody = message.body;
        model.chatSign = !_nowChatPerson?:0;
        if ([NearChatManager defaultManager]) {
            [[NearChatManager defaultManager]saveNearChatModleWithModel:model];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //TODO:做一些其他操作，如刷新聊天记录页面
        });
    });

    
    
}
//消息发送失败
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error
{
    /*
     消息发送失败的可能性分析：1.服务器关闭
                           2.在群聊时，发送者可能不在群组中的可能
                           3.与服务器断开连接
                           ......
     */
    NSString * toJid = message.to.user;
    if (self.delegate && [self.delegate respondsToSelector:@selector(sendMessage:result:error:)] && [toJid isEqualToString:_nowChatPerson]) {
        [self.delegate sendMessage:message result:NO error:error.description];
    }
    //TODO:可以做最近聊天记录的存储
}
//接收消息
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    
    NSString * fromJid = message.from.user;
    if (self.delegate && [self.delegate respondsToSelector:@selector(receiveMessage:)] && [fromJid isEqualToString:_nowChatPerson]) {
        [self.delegate receiveMessage:message];
        //TODO:可优化，如果自己建立聊天记录本地数据库的话，可在此处完成聊天记录model模型的赋值
    }
    //做最近聊天数据存储
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NearChatModel * model = [[NearChatModel alloc]init];
        model.chatPartnerJid = fromJid;
        model.xmppBody = message.body;
        model.chatSign = !_nowChatPerson?:0;
        if ([NearChatManager defaultManager]) {
            [[NearChatManager defaultManager]saveNearChatModleWithModel:model];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //TODO:做一些其他操作，如刷新聊天记录页面
        });
    });

}
#pragma mark -
#pragma mark - 单点登录
/*
    xmpp的原理为：登陆账号(JID)的资源名重复，当两个 相同资源名 的 相同账号 同时登陆时，调用此方法；
    如：A端： 帐号@openfire.com/ios  其中ios为资源名
        B端： 帐号@openfire.com/ios  其中ios为资源名
        此时会调用此方法，
        xmpp服务器会将新消息发送给后登陆服务器的客户端，如果同一帐号的资源名不相同，则不会掉用词方法，两个帐号会同时在线，发送消息时，指定接受消息的帐号的资源名，会根据资源名指定推送，如果不加人资源名，则随机发送
 */
- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
    NSLog(@"登陆冲突=====:%@",error);
    DDXMLNode *errorNode = (DDXMLNode *)error;
    //遍历错误节点
    for(DDXMLNode *node in [errorNode children]){
        //若错误节点有【冲突】
        if([[node name] isEqualToString:@"conflict"]){
            [self disconnect];
            //程序运行在后台，发送本地通知
            if ([[UIApplication sharedApplication] applicationState] !=UIApplicationStateActive) {
                UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                localNotification.alertAction = @"确定";
                localNotification.alertBody = [NSString stringWithFormat:@"你的账号已在其他地方登录，本地已经下线。"];//通知主体
                
                [localNotification setSoundName:UILocalNotificationDefaultSoundName]; //通知声音
                
                [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];//发送通知
                
            }
            //回调方法
            if ([self.delegate respondsToSelector:@selector(aloneLoginXMPP:)]) {
                [self.delegate aloneLoginXMPP:YES];
            }
        }
    }
}
//离线方法
- (void)disconnect
{
    //发送离线消息
    [self goOffline];
    [_xmppStream disconnect];
    //停止重连
    [_xmppReconnect setAutoReconnect:NO];
    //清空其它设置
    [NearChatManager revokeDefaultManager];
}
//发送离线状态
- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    
    [_xmppStream sendElement:presence];
}

#pragma mark -
#pragma mark - 服务器交互
-(void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence];
    [_xmppStream sendElement:presence];
    NSLog(@"发送在线状态");
}
#pragma mark - 
#pragma mark - 辅助方法
@end
