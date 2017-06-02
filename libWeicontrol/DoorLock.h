//
//  DoorLock.h
//  WeiControlDemo
//
//  Created by xy on 2017/4/8.
//  Copyright © 2017年 xy. All rights reserved.
//

#import <Foundation/Foundation.h>

//删除用户信息AF
typedef NS_ENUM(Byte, Enum_HeadType) {
    HeadType_OpenFail       = 0xD3,     //开锁失败
    HeadType_Query          = 0xE2,     //查询
    HeadType_Open           = 0xE3,     //开锁
    HeadType_Read           = 0xE4,     //读取门锁信息
    HeadType_ParmSet        = 0xEB,     //参数设置
    HeadType_Add            = 0xED,     //添加信息
    HeadType_Modify         = 0xEE,     //修改信息
    HeadType_Delete         = 0xEF,     //修改信息
    HeadType_Err            = 0xFE      //错误信息
};

typedef NS_ENUM(Byte, Enum_QueryType) {
    QueryType_User          = 0x01,     //查询用户信息
    QueryType_GuestPW       = 0x02,     //访客密码
    QueryType_UserList      = 0x03,     //获取用户列表
    QueryType_Parm          = 0x04,     //获取设备配置参数
    QueryType_Admin         = 0x0F,     //获取管理员权限
};

typedef NS_ENUM(Byte, Enum_AddType) {
    AddType_User            = 0x01,     //添加新用户索引
    AddType_Finger          = 0x02,     //添加用户指纹
    AddType_ICCard          = 0x03,     //添加用户卡
    AddType_UserPW          = 0x04      //添加用户密码
};

typedef NS_ENUM(Byte, Enum_ModifyType) {
    ModifyType_UserPW       = 0x01,     //修改用户密码
    ModifyType_ExitMenu     = 0x02,     //退出设置菜单
    ModifyType_BindID       = 0x03,     //绑定用户ID
    ModifyType_Alarm        = 0x06,     //胁迫报警
    ModifyType_Voice        = 0x07,     //开门声音
    ModifyType_Open         = 0x08,     //门锁常开
    ModifyType_AdminPW      = 0x0F      //更改管理员密码成功
};

typedef NS_ENUM(Byte, Enum_DeleteType) {
    DeleteType_Finger       = 0x01,     //删除用户指纹
    DeleteType_ICCard       = 0x02,     //删除用户卡
    DeleteType_UserPW       = 0x03,     //删除用户密码
    DeleteType_All          = 0x0F      //删除整个用户
};

#pragma mark 错误
typedef NS_ENUM(Byte, Enum_ErrType) {
    ErrType_ParmSet         = 0xAB,     //参数设置
    ErrType_Add             = 0xAD,     //添加信息
    ErrType_Modify          = 0xAE,     //修改信息
    ErrType_Delete          = 0xAF      //删除信息
};

typedef NS_ENUM(Byte, Enum_ErrParmSetType) {
    ErrParmSetType         = 0x00,     //配置设置正常
};

typedef NS_ENUM(Byte, Enum_ErrAdminType) {
    ErrAdminType            = 0x01,     //操作失败
};

typedef NS_ENUM(Byte, Enum_ErrAddType) {
    ErrAddType_User         = 0x01,     //添加用户失败
    ErrAddType_Finger       = 0x02,     //添加指纹失败
    ErrAddType_ICCard       = 0x03,     //添加用户卡失败
    ErrAddType_PassWord     = 0x04      //添加用户密码失败
};

typedef NS_ENUM(Byte, Enum_ErrModifyType) {
    ErrModifyType_UserPW    = 0x01,     //修改用户密码失败
    ErrModifyType_ExitSet   = 0x02,     //退出设置失败
    ErrModifyType_UserID    = 0x03,     //修改用户卡失败
    ErrModifyType_AdminPW   = 0x0F      //修改管理员密码失败
};

typedef NS_ENUM(Byte, Enum_ErrDeleteType) {
    ErrDeleteType_Finger    = 0x01,     //删除指纹失败
    ErrDeleteType_ICCard    = 0x02,     //删除IC卡失败
    ErrDeleteType_UserPW    = 0x03,     //删除用户密码失败
    ErrDeleteType_User      = 0x0F      //删除用户失败
};

@interface DoorLock : NSObject

@property (nonatomic) Enum_HeadType headType;//拿取指令帧头
@property (nonatomic) Byte type;//拿取二级指令类型
@property (nonatomic) Byte errFrameType;//帧头（可以判断是什么指令发生了错误）
@property (nonatomic) Byte adminFlag;//管理员权限标识

+ (DoorLock *)getTypeWithData:(NSData *)data;
+ (NSString *)safeCodeWithData:(NSData *)data;

@end

#pragma mark 获取用户列表
@interface UserList : NSObject

@property (nonatomic) int currentIndex;//当前索引号
@property (nonatomic) int userCount;//当前硬件设备中的用户总数
@property (nonatomic) int userIndex;//用户索引序号(主要)
@property (nonatomic) int userID;//userID为0时代表未绑定过用户

+ (UserList *)getObjWithData:(NSData *)data;

@end

#pragma mark 获取设备配置参数
@interface ConfigParm : NSObject

@property (nonatomic) int openType;//开锁认证方式
@property (nonatomic) int funcType;//门锁功能开关
@property (nonatomic) int eleMode;//系统电量管理模式
@property (nonatomic) int GuestPWStatus;//访客密码有效状态
@property (nonatomic) int maxNum;//门锁支持的最大用户索引数量

@property (nonatomic) int isVoice;//门锁支持的最大用户索引数量
@property (nonatomic) int isOpen;//门锁支持的最大用户索引数量
@property (nonatomic) int isAlarm;//门锁支持的最大用户索引数量

+ (ConfigParm *)getObjWithData:(NSData *)data;

@end

#pragma mark 新增返回成功标记
@interface QueryUser : NSObject

@property (nonatomic) int userIndex;//开锁认证方式
@property (nonatomic) int fingerMaxNum;//当前用户指纹最大容量
@property (nonatomic) int fingerNum;//当前用户已录指纹数量
@property (nonatomic) int cardMaxNum;//当前用户卡最大容量
@property (nonatomic) int cardNum;//当前用户已录卡数量
@property (nonatomic) int passwordMaxNum;//当前用户密码最大容量
@property (nonatomic) int passwordNum;//当前用户已录密码数量
@property (nonatomic) int AlarmType;//胁迫报警方式

@property (nonatomic) int userID;

+ (QueryUser *)getObjWithData:(NSData *)data;

@end

#pragma mark 新增返回成功标记
@interface AddUser : NSObject

@property (nonatomic) int userIndex;//用户索引序号(主要)
@property (nonatomic) int userID;//userID为0时代表未绑定过用户

+ (AddUser *)getObjWithData:(NSData *)data;

@end

#pragma mark 新增返回成功标记
@interface ModifyUser : NSObject

@property (nonatomic) int userIndex;//用户索引序号(主要)
//@property (nonatomic) int userID;//userID为0时代表未绑定过用户

+ (ModifyUser *)getObjWithData:(NSData *)data;

@end

@interface DeleteUser : NSObject

@property (nonatomic) int userIndex;//用户索引序号(主要)
//@property (nonatomic) int userID;//userID为0时代表未绑定过用户

+ (DeleteUser *)getObjWithData:(NSData *)data;

@end

@interface QueryGuestPW : NSObject

@property (nonatomic) int currentIndex;//用户索引号
@property (nonatomic) int pwd1;//当前用户指纹最大容量
@property (nonatomic) int pwd2;//当前用户已录指纹数量
@property (nonatomic) int pwd3;//当前用户卡最大容量
@property (nonatomic) int pwd4;//当前用户已录卡数量
@property (nonatomic) int pwd5;//当前用户密码最大容量
@property (nonatomic) int pwd6;//当前用户已录密码数量
@property (nonatomic) int Status;//状态

@property (nonatomic) int userID;

+ (QueryGuestPW *)getObjWithData:(NSData *)data;

@end

@interface QueryParm : NSObject

@property (nonatomic) int GuestStatus;//状态

+ (QueryParm *)getObjWithData:(NSData *)data;

@end

@interface QueryAdminPower : NSObject

@property (nonatomic) int AdminP;//状态

+ (QueryAdminPower *)getObjWithData:(NSData *)data;

@end

@interface ModifyBindID : NSObject

@property (nonatomic) int userIndex;

+ (ModifyBindID *)getObjWithData:(NSData *)data;

@end
