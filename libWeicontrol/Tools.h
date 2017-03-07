//
//  Tools.h
//  iFace
//
//  Created by APPLE on 14-9-10.
//  Copyright © 2014年 weicontrol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CTB.h"
#include <sys/xattr.h>

typedef void (^FirmwareBlock)(NSData *data, int type, int fileVer, float viewVer);

//从机设备状态
typedef NS_ENUM(UInt32, Enum_MusicType) {
    MusicType_OpenDoor      = 0,            //开门
    MusicType_SearchHost    = 1             //搜索主机
};

//校验类型
typedef NS_ENUM(UInt32, Enum_VerifyType) {
    VerifyType_Switch      = 1,            //开关
    VerifyType_Infrared    = 2             //红外
};


FOUNDATION_EXPORT NSString *const A0;//开关关
FOUNDATION_EXPORT NSString *const A1;//开关开
FOUNDATION_EXPORT NSString *const A3;//开锁
FOUNDATION_EXPORT NSString *const A4;//读取开关(插座)状态
FOUNDATION_EXPORT NSString *const A5;//开启智能匹配模式
FOUNDATION_EXPORT NSString *const A6;//读取主机ID
FOUNDATION_EXPORT NSString *const A7;//关闭远程UDP连接通道
FOUNDATION_EXPORT NSString *const A8;//开启红外学习模式
FOUNDATION_EXPORT NSString *const A9;//发送红外学习指令
FOUNDATION_EXPORT NSString *const AA;//主机心跳包
FOUNDATION_EXPORT NSString *const AC;//读取主机温度
FOUNDATION_EXPORT NSString *const C8;//取消学习
FOUNDATION_EXPORT NSString *const DF;//发送红外码库指令

FOUNDATION_EXPORT NSString *const codeEncryptKey;//加密密钥

@interface Tools : NSObject

//#pragma mark 获取当前实例
//+ (Tools *)getCurrentInstance;

//#pragma mark 获取主机是否活着（活着->连接正常 否则 连接失败）
//+ (BOOL)isControlAlive;

#pragma mark 创建专用plist文件
+ (void)setUserData:(id)obj key:(NSString *)key;
+ (void)setDifferentUserData:(id)obj key:(NSString *)key;
+ (void)removeObjectForKey:(NSString *)key;
+ (id)getUserData:(NSString *)key;
+ (BOOL)validForKey:(NSString *)key;

#pragma mark 生成随机数
+ (NSInteger)getRandomNumber:(NSInteger)from to:(NSInteger)to;

#pragma mark - --------解密字符串----------------
//+ (NSString *)decryptString:(NSString *)str;
//+ (NSString *)decryptString:(NSString *)str encoding:(NSStringEncoding)encoding;
+ (NSString *)decryptFrom:(NSString *)str;
+ (NSString *)encryptString:(NSString *)str;
+ (NSString *)encryptFrom:(NSString *)str;

#pragma mark 获取有效域名
+ (NSString *)getValidHostname:(NSString *)hostname;

#pragma mark 获取主机ID（主机MAC地址去除冒号后的字符串）
+ (NSString*)getHostMacID;

#pragma mark 判断有没有配置主机
+ (BOOL)isConfiged;

#pragma mark 构造读取主机ID指令
+ (NSData*)makeReadControlData;
#pragma mark 构造广播主机ID指令
+ (NSData *)makeBroadcastData;

#pragma mark 构造断开连接指令
+ (NSData *)makeOffOrder;

#pragma mark 构造读取主机温度指令
+ (NSData *)makeReadTempData;

#pragma mark 构造从机读取状态指令
+ (NSData*)makeSlaveReadData:(NSString*)host_mac slave_mac:(NSString*)slave_mac;
+ (NSData *)makeSlaveReadData:(NSString*)host_mac slave_mac:(NSString*)slave_mac relay:(BOOL)isRelay slave2:(NSString *)slave2_mac;

#pragma mark 构造心跳包回复指令
+ (NSData*)makeReplyHeartData:(NSString*)host_mac;

#pragma mark 构造从机开关指令
+ (NSData*)makeSlaveActionData:(NSString*)host_mac slave:(NSString*)slave_mac onOpen:(BOOL)onOpen;
+ (NSData*)makeSlaveActionData:(NSString*)host_mac slave:(NSString*)slave_mac onOpen:(BOOL)onOpen relay:(BOOL)isRelay slave2:(NSString *)slave2_mac;

+ (NSString *)makeSwitchOrder:(NSString *)slave_mac relay:(BOOL)isRelay index:(int)index slave2:(NSString *)slave2_mac;
//电动窗帘组合
+ (NSString *)makeCurtainOrder:(NSString *)slave_mac relay:(BOOL)isRelay index:(int)index slave2:(NSString *)slave2_mac action:(NSString *)action per:(CGFloat)per;

//创建LED指令
+ (NSData *)makeLEDOrder:(NSString *)order
                 hostMac:(NSString *)host_mac
                slaveMac:(NSString *)slave_mac
                  verify:(Enum_VerifyType)verify
              typeString:(NSString *)typeString
             placeString:(NSString *)placeString
                  LEDMac:(NSString *)LEDMacString;

+ (NSData *)makeLEDCommandOrder:(NSString *)order
                        hostMac:(NSString *)host_mac
                       slaveMac:(NSString *)slave_mac
                         verify:(Enum_VerifyType)verify
                     typeString:(NSString *)typeString
                  commandString:(NSString *)commandString
                         LEDMac:(NSString *)LEDMacString;

+ (NSData *)makeLEDGroupControlCommandOrder:(NSString *)order
                                    hostMac:(NSString *)host_mac
                                   slaveMac:(NSString *)slave_mac
                                     verify:(Enum_VerifyType)verify
                                 typeString:(NSString *)typeString
                              commandString:(NSString *)commandString
                                    LEDMacs:(NSArray <NSString *> *)LEDMacs
                                   position:(NSString *)positionString;

+ (NSString *)makeLEDCommandString:(NSString *)order
                           hostMac:(NSString *)host_mac
                          slaveMac:(NSString *)slave_mac
                            verify:(Enum_VerifyType)verify
                        typeString:(NSString *)typeString
                     commandString:(NSString *)commandString
                            LEDMac:(NSString *)LEDMacString;


#pragma mark 构造升级主机指令前缀（不带校验）
+ (NSData*)makeUpdateHostDataWithFix:(NSString*)host_mac;

#pragma mark 构造主机上传配置信息
+ (NSData*)makeUploadConfig:(NSString*)ssid password:(NSString*)password serverip:(NSString*)serverip serverport:(UInt16)serverport;

#pragma mark 构造控制命令(未校验)
+ (NSData *)makeOrder:(NSString *)order hostMac:(NSString *)host_mac slaveMac:(NSString *)slave_mac;
#pragma mark 构造控制命令(根据校验类型进行校验)
+ (NSData *)makeOrder:(NSString *)order hostMac:(NSString *)host_mac slaveMac:(NSString *)slave_mac verify:(Enum_VerifyType)verify;

#pragma mark 构造添加红外下发学习指令
+ (NSData *)makeInfraredStudyData:(NSString*)host_mac;
+ (NSData *)makeInfraredOrder:(NSString *)order hostMac:(NSString *)host_mac;

#pragma mark - -------构造智能匹配下发指令----------------
+ (NSData*)makeSmartMatchData:(NSString*)host_mac;

#pragma mark 构造红外指令
+ (NSData *)makeInfraredActionData:(NSString*)host_mac;
#pragma mark 构造自定义红外指令
+ (NSData *)makeInfraredActionData:(NSString*)host_mac data:(NSData *)data;

#pragma mark 构造发送遥控组合指令
+ (NSData *)makeJoinInfraredActionData:(NSString*)host_mac keys:(NSData *)keys;
+ (NSData *)makeInfraredOrder:(NSString *)order host:(NSString *)host_mac keys:(NSData *)keys;

#pragma mark 构造指纹蓝牙门锁配置指令(失败返回nil)
+ (NSData*)makeDoorLockInstruction:(NSString*)frameType hostID:(NSString*)hostID deviceID:(NSString*)deviceID safeCode:(NSString*)safeCode extHexData:(NSString *)extHexData;
+ (NSData*)makeDoorLockConfigParm:(NSString*)frameType deviceID:(NSString*)deviceID safeCode:(NSString*)safeCode hexType:(NSString*)hexType extHexData:(NSString *)extHexData;

+ (NSData*)makeDoorLockConfigParm:(NSString*)frameType
                         deviceID:(NSString*)deviceID
                         safeCode:(NSString*)safeCode
                          hexType:(NSString*)hexType
                        userIndex:(NSInteger)userIndex;

+ (NSData *)makeDoorLockConfigParm:(NSString *)doorLockCP
                          deviceID:(NSString *)deviceID
                          passWord:(NSString *)passWord
                           hexType:(NSString *)type
                         userIndex:(NSString *)userIndex
                            userID:(NSString *)userID
                            action:(NSInteger)action
                               way:(NSInteger)way;

//声音和常开
+ (NSData *)makeDoorLockConfigParm:(NSString *)doorLockCP
                          deviceID:(NSString *)deviceID
                          passWord:(NSString *)passWord
                           hexType:(NSString *)type
                         userIndex:(NSInteger)userIndex
                              flag:(NSInteger)flag;

#pragma mark 获取当前WIFI SSID信息
+ (NSString *)getCurrentWifiSSID;
+ (NSDictionary *)getCurrentWifiInfo;

#pragma mark - --------华丽的分割线------------------------
#pragma mark 获取crc校验码
+ (NSData*)getCRC:(NSData*)dataBytes;
+ (NSData *)getCRCWith:(NSArray *)listData;

#pragma mark 组合控制命令
+ (NSString *)makeControl:(NSString *)control value:(NSString *)value;
+ (NSString *)makeControl:(NSString *)control dataLen:(int)len value:(NSString *)value;
#pragma mark 构造开门动作
+ (NSData*)makeOpenDoorActionWithSN:(NSString*)SN parmsDoor:(NSString*)parmsDoor;
+ (NSData *)makeDoorCommandWith:(NSString *)SN pwd:(NSString *)pwd msg:(NSString *)msg control:(NSString *)control;
//改IP和网关
+ (NSString *)makeControlWithIP:(NSString *)IP gateway:(NSString *)gateway;

#pragma mark 固件校验(失败返回nil)
/**
 * @method
 * @abstract 固件校验(失败返回nil，主机固件及从机固件在更新时必须调用此方法！)
 * @param data 固件数据
 * @param block 回调 type 固件类型：00为主机，01为从机；固件型号：fileVer；固件版本号： viewVer
 **/
+ (void)ValidCRCWithFirmware:(NSData *)data complete:(FirmwareBlock)block;

#pragma mark 播放声音（系统级播放，不能超过30秒，适合播放声音素材）
+ (void)createPlaySound:(NSString *)pathName ofType:(NSString *)type;
+ (void)createPlaySound:(NSString *)name ofType:(NSString *)type soundID:(SystemSoundID *)inSystemSoundID;
+ (void)playSystemSound:(SystemSoundID)inSystemSoundID;
+ (void)VibrateDefault;//手机震动（系统默认，时间较长）
+ (void)VibrateShort;//手机震动（微震带有声音）
+ (void)VibrateDoubleShort;//手机震动（短震两下）
+ (void)KeyPressed;//触模按键声

#pragma mark 获取状态栏尺寸
+ (CGRect)getStatusBar;

#pragma mark 是否为空字符
+ (BOOL)isNullOrEmpty:(NSString *)str;

#pragma mark 拿取文件路径
+ (NSString *)getFilePath:(NSString *)fileName;
+ (NSString *)getFilePath:(NSString *)fileName type:(NSString *)type;
+ (UIImage *)getImgWithName:(NSString *)imgName;

#pragma mark 判断文件是否存在
+ (BOOL)fileExist:(NSString *)fileName;
+ (BOOL)pathExist:(NSString *)path;

+ (void)PathExistsAtPath:(NSString *)Path;
+ (NSString *)getFileName:(NSString *)path;
+ (NSString *)getNameWithUrl:(NSString *)url;

#pragma mark 加载图片－本地文件
+ (UIImage *)imageFromDocumentFileName:(NSString *)fileName;

#pragma mark 保存文件到本地
+ (void)saveDataToFile:(NSData *)data fileName:(NSString *)fileName;

#pragma mark 设置备份模式
+ (BOOL)addSkipBackupAttributeToItemAtFilePath:(NSString *)filePath;
+ (void)addIndexDirectory:(NSString *)filePath;

+ (NSDate *)dateFromString:(NSString *)str withDateFormater:(NSString *)formater;
#pragma mark 日期转字符
+ (NSString *)dateToString:(NSDate *)date withDateFormater:(NSString *)formater;
#pragma mark 日期计算
+ (NSDate *)AddYearsToDate:(NSDate *)date years:(int)years;
+ (NSDate *)AddMonthToDate:(NSDate *)date months:(int)months;
+ (NSDate *)AddDayToDate:(NSDate *)date days:(int)days;
#pragma mark 日期比较
+ (int)compareDate:(NSDate *)aDate and:(NSDate *)bDate;
#pragma mark 获取星期几
+ (NSString *)getWeekDay:(NSDate *)date;

#pragma mark 去掉校验
+ (NSData *)deleteVerifyWith:(NSData *)data;

#pragma mark 开关的CRC校验
+ (NSData*)replaceCRCForSwitch:(NSData *)buffer;
#pragma mark 摇控CRC校验
+ (NSData*)replaceCRCForInfrared:(NSData *)buffer;
+ (BOOL)ValidCRCWithHost:(NSData *)data;

@end
