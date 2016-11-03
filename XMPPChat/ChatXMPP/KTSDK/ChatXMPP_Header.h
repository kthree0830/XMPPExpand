//
//  ChatXMPP_Header.h
//  ChatXMPP
//
//  Created by 周洪静 on 16/2/27.
//  Copyright © 2016年 KT. All rights reserved.
//

#ifndef ChatXMPP_Header_h
#define ChatXMPP_Header_h
/*
    XMPP相关头文件 服务器配置 XMPP个人信息等
 */
//XMPP相关头文件
#import "KTXMPPManager.h"
#import "NearChatManager.h"
//用户信息
#define KT_XMPPJid @"KT_XMPPJid"
#define KT_XMPPPassword @"KT_XMPPPassword"

#define KT_XMPPResources @"Resources"//资源名
//服务器相关
#define KT_XMPPDomain @""//主机名
#define KT_XMPPIP @"000.000.0.0"//主机IP
#define KT_XMPPPort 5222 //主机端口
//群聊主机名格式 KT_XMPPGroupDomain @"broadcast.主机名"
#define KT_XMPPGroupDomain @""


#define KT_Message_Error_BeNil @"消息为空或不合法"

/*
    枚举
 */
//xmpp连接服务器时所处状态
typedef NS_ENUM(NSInteger) {
    XMPPConnectStyleDefualt = 0 ,       //未连接
    XMPPConnectStyleBeforeRegister,     //完成注册后
    XMPPConnectStyleBeforeLogin         //完成登录后
}XMPPConnectStyle;
#endif /* ChatXMPP_Header_h */
