//
//  DoorLock.m
//  WeiControlDemo
//
//  Created by xy on 2017/4/8.
//  Copyright © 2017年 xy. All rights reserved.
//

#import "DoorLock.h"
#import "CTB.h"

@implementation DoorLock

+ (DoorLock *)getTypeWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    DoorLock *doorLock = [[DoorLock alloc] init];
    
    Byte *bytes = (Byte *)[data bytes];
    doorLock.headType = bytes[0];//拿取指令帧头
    doorLock.type = bytes[8];//拿取二级指令类型
    
    doorLock.errFrameType = bytes[9];//帧头（可以判断是什么指令发生了错误）
    doorLock.adminFlag = bytes[10];//管理员权限标识
    
    return doorLock;
}

+ (NSString *)safeCodeWithData:(NSData *)data
{
    NSString *safeCode = [[data subdataWithRange:NSMakeRange(15, 3)] hexString];
    return safeCode;
}

@end

@implementation UserList

+ (UserList *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    UserList *doorLock = [[UserList alloc] init];
    
    Byte *bytes = (Byte *)[data bytes];
    doorLock.currentIndex = bytes[9];//拿取指令帧头
    doorLock.userCount = bytes[10];//拿取二级指令类型
    
    doorLock.userIndex = bytes[11];//帧头（可以判断是什么指令发生了错误）
    doorLock.userID = (int)[[data subdataWithRange:NSMakeRange(12, 4)] parseInt:16];//管理员权限标识
    
    return doorLock;
}

@end

@implementation ConfigParm

+ (ConfigParm *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    ConfigParm *doorLock = [[ConfigParm alloc] init];
    
    Byte *bytes = (Byte *)[data bytes];
    doorLock.openType = bytes[9];//拿取指令帧头
    doorLock.funcType = bytes[10];//拿取二级指令类型
    
    doorLock.eleMode = bytes[11];//帧头（可以判断是什么指令发生了错误）
    doorLock.GuestPWStatus = bytes[12];//管理员权限标识
    doorLock.maxNum = bytes[13];
    
    long paSetFlag = [[data subdataWithRanges:NSMakeRange(14, 1)] parseInt:16];
    doorLock.isVoice = paSetFlag & 0x0001;//门锁支持的声音常开模式
    doorLock.isOpen = paSetFlag & 0x0010;//门锁支持的开关常开模式
    doorLock.isAlarm = paSetFlag & 0x0100;;//胁迫
    
    return doorLock;
}

@end

@implementation QueryUser

+ (QueryUser *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    QueryUser *queryUser = [[QueryUser alloc] init];
    queryUser.userIndex = (int)[data bytesWithLocation:9];//用户索引号
    queryUser.fingerMaxNum = (int)[data bytesWithLocation:10];//当前用户指纹最大容量
    queryUser.fingerNum = (int)[data bytesWithLocation:11];//当前用户已录指纹数量
    queryUser.cardMaxNum = (int)[data bytesWithLocation:12];//当前用户卡最大容量
    queryUser.cardNum = (int)[data bytesWithLocation:13];//当前用户已录卡数量
    queryUser.passwordMaxNum = (int)[data bytesWithLocation:14];//当前用户密码最大容量
    queryUser.passwordNum = (int)[data bytesWithLocation:15];//当前用户已录密码数量
    //E2 id3 id2 id1 id0 PW2 PW1 PW0 type UserIndex AllNum1 Num1 AllNum2 Num2 AllNum3 Num3 Way crc1 crc2
    
    queryUser.AlarmType = (int)[data bytesWithLocation:16];//胁迫报警方式
    
    return queryUser;
}

@end

@implementation AddUser

+ (AddUser *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    AddUser *doorLock = [[AddUser alloc] init];
    
    Byte *bytes = (Byte *)[data bytes];
    
    doorLock.userIndex = bytes[9];//用户索引
    doorLock.userID = (int)[[data subdataWithRange:NSMakeRange(12, 4)] parseInt:16];//用户ID
    
    return doorLock;
}

@end

@implementation ModifyUser

+ (ModifyUser *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    ModifyUser *doorLock = [[ModifyUser alloc] init];
    
    Byte *bytes = (Byte *)[data bytes];
    
    doorLock.userIndex = bytes[9];//用户索引
    //doorLock.userID = (int)[[data subdataWithRange:NSMakeRange(12, 4)] parseInt:16];//用户ID
    
    return doorLock;
}

@end

@implementation DeleteUser

+ (DeleteUser *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    DeleteUser *doorLock = [[DeleteUser alloc] init];
    
    Byte *bytes = (Byte *)[data bytes];
    
    doorLock.userIndex = bytes[9];//用户索引
    //doorLock.userID = (int)[[data subdataWithRange:NSMakeRange(12, 4)] parseInt:16];//用户ID
    
    return doorLock;
}

@end

@implementation QueryGuestPW

+ (QueryGuestPW *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    QueryGuestPW *queryUser = [[QueryGuestPW alloc] init];
    queryUser.currentIndex = (int)[data bytesWithLocation:9];//用户索引号
    queryUser.pwd1 = (int)[data bytesWithLocation:10];//
    queryUser.pwd2 = (int)[data bytesWithLocation:11];//
    queryUser.pwd3 = (int)[data bytesWithLocation:12];//
    queryUser.pwd4 = (int)[data bytesWithLocation:13];//
    queryUser.pwd5 = (int)[data bytesWithLocation:14];//
    queryUser.pwd6 = (int)[data bytesWithLocation:15];//
    //E2 id3 id2 id1 id0 PW2 PW1 PW0 type UserIndex AllNum1 Num1 AllNum2 Num2 AllNum3 Num3 Way crc1 crc2
    
    queryUser.Status = (int)[data bytesWithLocation:16];//胁迫报警方式
    
    return queryUser;
}

@end

@implementation QueryParm

+ (QueryParm *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    QueryParm *queryUser = [[QueryParm alloc] init];
    
    queryUser.GuestStatus = [data bytesWithLocation:12];//访客密码有效状态
    
    return queryUser;
}

@end

@implementation QueryAdminPower

+ (QueryAdminPower *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    QueryAdminPower *queryUser = [[QueryAdminPower alloc] init];
    
    queryUser.AdminP = [data bytesWithLocation:9];//访客密码有效状态
    
    return queryUser;
}

@end

@implementation ModifyBindID

+ (ModifyBindID *)getObjWithData:(NSData *)data
{
    if (data.length < 9) {
        return nil;
    }
    
    ModifyBindID *modifyBindID = [[ModifyBindID alloc] init];
    
    modifyBindID.userIndex = [data bytesWithLocation:9];//访客密码有效状态
    
    return modifyBindID;
}

@end
