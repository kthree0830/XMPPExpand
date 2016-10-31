//
//  NearChatManager.h
//  ChatXMPP
//
//  Created by mac on 16/6/30.
//  Copyright © 2016年 KT. All rights reserved.
//


/*
 最近聊天记录的管理,本处使用sqlite3进行存储
 */
#import <Foundation/Foundation.h>
#import "KTXMPPManager.h"

typedef NS_ENUM(NSUInteger,KTTMessageReadType) {
    KTTMessageRead = 0,
    KTTMessageUnRead
};
@class NearChatModel;
@interface NearChatManager : NSObject
/**
 *  当前用户JID
 */
@property (nonatomic, copy, readonly) NSString * currentJid;
/**
 *  最近聊天记录管理单例
 *
 *  @param Jid 当前用户
 */
+ (instancetype)defaultManagerWithJid:(NSString *)Jid;
/**
 *  最近聊天记录管理单例
 *
 *  @return 当defaultManagerWithJid:(NSString *)Jid调用过后，此方法才会返回结果
 */
+ (instancetype)defaultManager;
/**
 *  最近聊天记录管理单例置为nil
 *  需要在更改用户的时候使用
 */
+ (void)revokeDefaultManager;
/**
 *  存储
 */
- (void)saveNearChatModleWithModel:(NearChatModel *)nearChatModel;
/**
 *  查询所有未读消息个数
 */
- (NSInteger)findAllSign;
/**
 *  指定对象的未读消息清零
 */
- (void)updateSignToZeroWithJid:(NSString *)Jid;
/**
 *  查询所有最近聊天记录
 */
- (NSArray *)findAllNearChatModel;
/**
 *  删除指定数据
 */
- (void)deleteNearChatWithJid:(NSString *)Jid;
@end




/**
 *  最近聊天记录数据模型
 */
@interface NearChatModel : NSObject
/**
 *  xmpp中的消息体，xml中body字段，默认里边为Json
 */
@property (nonatomic, copy) NSString * xmppBody;

/**聊天对象Jid*/
@property (nonatomic, copy  ) NSString           * chatPartnerJid;
/**聊天内容*/
@property (nonatomic, copy  ) NSString           * chatContents;
/**聊天发生时间*/
@property (nonatomic, retain) NSDate             * chatHappenDate;
/**聊天消息类型*/
@property (nonatomic, assign) KTTMessageType     chatMessageType;
/**聊天读取状态*/
@property (nonatomic, assign) KTTMessageReadType chatMessageReadType;
/**未读消息个数*/
@property (nonatomic, assign) NSInteger          chatSign;
/*
    下面为个人信息，有三种方式
    1.根据chatPartnerJid请求网络数据，返回必要的个人信息
    2.根据chatPartnerJid请求本地人员信息数据库，获得必要的个人信息
    3.所需要的人员信息一同与消息发送而来，解析而得
 */
/**聊天对象头像URL*/
@property (nonatomic, copy) NSString * chatPartnerHeadURL;
/**聊天对象名字*/
@property (nonatomic,copy ) NSString * chatPartnerName;
@end
