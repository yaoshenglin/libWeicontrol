//
//  BLEAutoConnect.h
//  BluetoothDemo
//
//  Created by varVery on 15/12/11.
//  Copyright © 2015年 David Sahakyan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Device_Name            @"iFace-Lock"//指定设备名称进行连接（QLove,iFace-Lock）
#define Device_Info_Server     @"180A"//设备信息通用UUID（无需配置）
#define Device_Battery_Server  @"180F"//电池电量信息通用UUID（无需配置）
#define RxTx_Send_Server       @"FFF6"//可写服务UUID，(FFF6,1000)
#define RxTx_Read_Server       @"1814"//只读服务UUID
#define RxTx_Send              @"FFF6"//可写特征UUID，(FFF6,1001)
#define RxTx_Read              @"1002"//只读特征UUID
#define RxTx_Read_Battery      @"2A19"//电池电量只读特征UUID
#define RxTx_Notity            @"FFF6"//通知或透传特征UUID

@protocol BLECallBack <NSObject>

/**
 * 初始化固件回调（升级时必须判断以下条件，通过后方可调用Start方法开始升级）
 * type:固件类型, fileVer:固件型号, viewVer:固件版本号
 * 详细规则请参见《iFace通讯协议》- [固件打包规则]
 **/
- (void)onUpgradeInit:(int)type fileVer:(int)fileVer viewVer:(float)viewVer;
- (void)onUpgradeStarted;//更新已启动
- (void)onUpgradeError:(NSString *)errMsg;//更新错误（更新已中断）
- (void)onUpgradeProgress:(float)progress;//进度更新（请勿以此判断更新完成！）
- (void)onUpgradeCompleted;//更新已完成

- (void)onUpdateValue:(NSData *)mData formatData:(NSString *)formatData error:(NSError *)error;//值发生变化更新
@optional
- (void)onDiscoverWriteCharact;//发现可写特征
- (void)onReadRSSI:(NSNumber *)RSSI error:(NSError *)error;//读取RSSI
- (void)onConnectState:(BOOL)isConnected;//连接变化更新
- (void)onDidFailToSendDataWithError:(NSError *)error;

@end

@interface BLEAutoConnect : NSObject

@property (nonatomic,weak) id callback;//回调代理

- (id)initWithDelegate:(id)delegate;

#pragma mark 扫描并连接设备
- (void)ScanAndConnect:(NSData *)connectDeviceID;
#pragma mark 停止扫描并断开连接（一般供调试使用）
- (void)StopAndDisConnect;
#pragma mark 判断蓝牙设备是否已经准备好
- (BOOL)isReady;
#pragma mark 判断蓝牙设备是否已经连接
- (BOOL)isConnected;
#pragma mark 读取RSSI（对应onReadRSSI）
- (void)readRSSI;
#pragma mark 读取设备信息（对应onUpdateValue）
- (void)readDeviceInfo;
#pragma mark 读取设备电量信息（对应onUpdateValue）
- (void)readBatteryInfo;
#pragma mark 发送数据给设备（对应onUpdateValue）
- (BOOL)sendData:(NSData *)data;
#pragma mark 设置特性通知
- (void)setNotify:(BOOL)isNotify;
#pragma mark 关闭释放
- (void)Close;
#pragma mark 更新固件初始化
-(void)UpgradeInit:(NSData *)deviceID binData:(NSData *)binData;
#pragma mark 开始更新固件
-(void)UpgradeStart;

- (void)disConnectDevice;//取消连接蓝牙设备
- (void)reConnectToDevice;//重新连接已经连接过和蓝牙设备

@end
