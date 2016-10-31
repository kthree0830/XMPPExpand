//
//  NearChatManager.m
//  ChatXMPP
//
//  Created by mac on 16/6/30.
//  Copyright © 2016年 KT. All rights reserved.
//

/*
    传入一个BOOL值
    对于FMDB返回结果的限制，如果为NO，则程序停止，停在此处
 */
#define FMDBQuickCheck(SomeBool) { if (!(SomeBool)) { NSLog(@"Failure on line %d", __LINE__); abort(); } }

#import "NearChatManager.h"
//FMDB
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"
//

static NearChatManager * STC_Manager = nil;
static NSString * STC_Jid = nil;
@implementation NearChatManager
{
    /**数据库实例*/
    FMDatabase * _fmdb;
}
#pragma mark - 
#pragma mark - Public
+ (instancetype)defaultManagerWithJid:(NSString *)Jid {
    //此处不实用dispatch_once，因为客户端是可以切换用户的，每个用户所对应的表是不一样的（本人如此设计，思考不全，大家根据需求而定）
    
    if (Jid.length) {
        STC_Jid = Jid;
        STC_Manager = [[NearChatManager alloc]init];
    }else
    {
        //传入空字符串或长度为0的字符串时，认为当前没有正在通信的联系人
        NSLog(@"Jid不能为空 或 当前没有正在通信的联系人");
        return nil;
    }
    return STC_Manager;
}
+ (void)revokeDefaultManager {
    if (STC_Manager) {
        STC_Manager = nil;
        STC_Jid     = nil;
    }
}
+ (instancetype)defaultManager
{
    if (STC_Jid.length && STC_Manager) {
        return STC_Manager;
    }
    return nil;
}
- (void)saveNearChatModleWithModel:(NearChatModel *)nearChatModel {
    //查询是否有记录
    NearChatModel * model = [self p_FindNearChatModelWithJid:nearChatModel.chatPartnerJid];
    if (!model) {
        [self p_SaveNearChatModelWithModel:nearChatModel];
    }else{
        [self p_UpdateNearChatModelWithModel:model];
    }}
- (NSInteger)findAllSign {
    [self p_OpenSqlite];
    NSString * findAllSignString = [NSString stringWithFormat:@"select *from '%@'",STC_Jid];
    FMResultSet * resultSet = [_fmdb executeQuery:findAllSignString];
    NSInteger num = 0;
    while ([resultSet next]) {
        num += [resultSet intForColumn:@"chatSign"];
    }
    [self p_CloseSqlite];
    return num;
}
- (void)updateSignToZeroWithJid:(NSString *)Jid {
    [self p_UpdateSignToZeroWithJid:Jid];
}

- (NSArray *)findAllNearChatModel {
    [self p_OpenSqlite];
    //按时间降序排列
	NSString * findAllString = [NSString stringWithFormat:@"select *from '%@' order by chatHappenDate desc",STC_Jid];
    NSMutableArray * allArray = [NSMutableArray arrayWithCapacity:0];
    FMResultSet * resultSet = [_fmdb executeQuery:findAllString];
    while ([resultSet next]) {
        NearChatModel * model     = [[NearChatModel alloc]init];
        model.chatPartnerJid      = [resultSet stringForColumn:@"chatPartnerJid"];
        model.chatContents        = [resultSet stringForColumn:@"chatContents"];
        model.chatHappenDate      = [resultSet dateForColumn:@"chatHappenDate"];
        model.chatMessageType     = [resultSet intForColumn:@"chatMessageType"];
        model.chatMessageReadType = [resultSet intForColumn:@"chatMessageReadType"];
        model.chatSign            = [resultSet intForColumn:@"chatSign"];
        [allArray addObject:model];
    }
    [self p_CloseSqlite];
    return [allArray copy];
}

- (void)deleteNearChatWithJid:(NSString *)Jid {
    [self p_OpenSqlite];
    NSString * deleteString = [NSString stringWithFormat:@"delete from '%@' where chatPartnerJid= ?",STC_Jid];
    [_fmdb executeUpdate:deleteString,Jid];
    
    [self p_CloseSqlite];
}




#pragma mark - Pritave
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_PrepareSqlite];
    }
    return self;
}
- (NSString *)currentJid
{
    return STC_Jid;
}
/**
 *  sqlite准备
 */
- (void)p_PrepareSqlite
{
    FMDatabase * fmdb = [FMDatabase databaseWithPath:[self p_SqlitePath]];
    _fmdb = fmdb;
    [self p_OpenSqlite];
    //建立表(人员信息需要从网络或本地人员数据库中获取)
    NSString *createTableStr = [NSString stringWithFormat:@"create table '%@' (chatPartnerJid DEFAULT NULL,chatContents DEFAULT NULL,chatHappenDate DEFAULT NULL,chatMessageType DEFAULT NULL,chatMessageReadType DEFAULT NULL,chatSign DEFAULT NULL)",STC_Jid];
    /*
     人员信息随消息一同发来
     NSString *createTableStr = [NSString stringWithFormat:@"create table '%@' (chatPartnerJid DEFAULT NULL,chatContents DEFAULT NULL,chatHappenDate DEFAULT NULL,chatMessageType DEFAULT NULL,chatMessageReadType DEFAULT NULL,chatSign DEFAULT NULL,chatPartnerHeadURL DEFAULT NULL,chatPartnerName DEFAULT NULL)",STC_Jid];
     */
    
    //建表
    [_fmdb executeUpdate:createTableStr];
}
/**
 *  sqlite路径
 */
- (NSString *)p_SqlitePath
{
    return [NSHomeDirectory() stringByAppendingString:@"/Documents/XMPP_Chat.db"];
}
/**
 *  打开数据库
 */
- (void)p_OpenSqlite
{
    if (![_fmdb open]) {
        FMDBQuickCheck(NO);
    }
}
/**
 *  关闭数据库
 */
- (void)p_CloseSqlite
{
    [_fmdb close];
}
/**
 *  查询指定Jid的数据
 */
- (NearChatModel *)p_FindNearChatModelWithJid:(NSString *)Jid
{
    [self p_OpenSqlite];
    NSString *queryString   = [NSString stringWithFormat:@"select * from '%@' where chatPartnerJid = ? ",STC_Jid];
    FMResultSet * resultSet = [_fmdb executeQuery:queryString,Jid];
    NearChatModel * model   = [[NearChatModel alloc]init];
    BOOL isHave = NO;
    while ([resultSet next]) {
        model.chatPartnerJid      = [resultSet stringForColumn:@"chatPartnerJid"];
        model.chatContents        = [resultSet stringForColumn:@"chatContents"];
        model.chatHappenDate      = [resultSet dateForColumn:@"chatHappenDate"];
        model.chatMessageType     = [resultSet intForColumn:@"chatMessageType"];
        model.chatMessageReadType = [resultSet intForColumn:@"chatMessageReadType"];
        model.chatSign            = [resultSet intForColumn:@"chatSign"];
        isHave = YES;
    }
    [self p_CloseSqlite];
    return isHave?model:nil;
}
/**
 *  存储新数据
 */
-(void)p_SaveNearChatModelWithModel:(NearChatModel *)nearChatModel
{
    //如果没传值
    if (!nearChatModel.chatSign) {
        nearChatModel.chatSign = 0;
    }
    //数据库文件的路径
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self p_SqlitePath]];
    //将一组操作添加到非事务中
    [queue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"数据库打开失败");
        };
        [db beginTransaction];//该句是将操作放入事务中 添加入事务操作.在不加本句时.该操作只是,该队列是串行队列,在运行时效率较慢.
        BOOL isError = NO;

            //根据需求存入数据，要与创建表的顺序相同
            NSString * insertString = [NSString stringWithFormat:@"insert into '%@' values (?,?,?,?,?,?)",STC_Jid];
            isError = [db executeUpdate:insertString,nearChatModel.chatPartnerJid,nearChatModel.chatContents,nearChatModel.chatHappenDate,nearChatModel.chatMessageType,nearChatModel.chatMessageReadType,nearChatModel.chatSign];
            
            if (isError) {
                NSLog(@"所有插入动作成功");
            }else{
                NSLog(@"插入操作动作失败");
                FMDBQuickCheck(isError);
            }

        //提交事务
        [db commit];//注意:在将操作添加到事务操作中后,一定要提交事务.
        [db close];
    }];

}
/**
 *  更新已有数据
 */
- (void)p_UpdateNearChatModelWithModel:(NearChatModel *)nearChatModel
{
    //数据库文件的路径
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self p_SqlitePath]];
    //将一组操作添加到非事务中
    [queue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"数据库打开失败");
        };
        [db beginTransaction];//该句是将操作放入事务中 添加入事务操作.在不加本句时.该操作只是,该队列是串行队列,在运行时效率较慢.
        BOOL isError = NO;
        //根据需求存入数据
        NSString *updateStr = [NSString stringWithFormat:@"update '%@' set chatContents=?, chatHappenDate=?, chatMessageType=?, chatMessageReadType=?, chatSign=? where chatPartnerJid=?",STC_Jid];
        
        nearChatModel.chatSign += 1;
        
        isError = [db executeUpdate:updateStr,nearChatModel.chatContents,nearChatModel.chatHappenDate,nearChatModel.chatMessageType,nearChatModel.chatMessageReadType,nearChatModel.chatSign,nearChatModel.chatPartnerJid];
        
        if (isError) {
            NSLog(@"所有插入动作成功");
        }else{
            NSLog(@"插入操作动作失败");
            FMDBQuickCheck(isError);
        }
        
        //提交事务
        [db commit];//注意:在将操作添加到事务操作中后,一定要提交事务.
        [db close];
    }];

}
/**
 *  指定对象未读消息为0条
 */
- (void)p_UpdateSignToZeroWithJid:(NSString *)Jid
{
    
    //数据库文件的路径
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self p_SqlitePath]];
    //将一组操作添加到非事务中
    [queue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"数据库打开失败");
        };
        [db beginTransaction];//该句是将操作放入事务中 添加入事务操作.在不加本句时.该操作只是,该队列是串行队列,在运行时效率较慢.
        BOOL isError = NO;
        //根据需求存入数据
        NSString * updateSignToZeroSting = [NSString stringWithFormat:@"update '%@' set chatSign = ? where chatPartnerJid = ?",STC_Jid];
        
        
        isError = [db executeUpdate:updateSignToZeroSting,@(0),Jid];
        
        if (isError) {
            NSLog(@"所有插入动作成功");
        }else{
            NSLog(@"插入操作动作失败");
            FMDBQuickCheck(isError);
        }
        
        //提交事务
        [db commit];//注意:在将操作添加到事务操作中后,一定要提交事务.
        [db close];
    }];

}
@end

#pragma mark -
#pragma mark -
#pragma mark -
@implementation NearChatModel
@synthesize xmppBody = _xmppBody;


- (void)setXmppBody:(NSString *)xmppBody
{
	_xmppBody = xmppBody;
    /*
     可以在此中依次给NearChatModel中其他属性赋值，也可不使用此属性直接给NearChatModel其他属性赋值
     */
    
}



@end