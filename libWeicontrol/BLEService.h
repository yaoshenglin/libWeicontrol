//
//  BLEService.h
//  BluetoothDemo
//
//  Created by varVery on 15/12/15.
//  Copyright © 2015年 David Sahakyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEAutoConnect.h"

@protocol BLECallback <NSObject>

//以下是回调协议
- (void)onConnect:(CBPeripheral *)peripheral;//已连接
- (void)onDisconnect:(CBPeripheral *)peripheral error:(NSError *)error;//已断开连接
@optional
- (void)onDiscoverPeripheral:(CBPeripheral *)peripheral adData:(NSDictionary<NSString *,id> *)adData RSSI:(NSNumber *)RSSI;//发现外围设备
- (void)onDiscoverServices:(CBPeripheral *)peripheral error:(NSError *)error;//发现外围服务
- (void)onDiscoverCharacteristics:(CBPeripheral *)peripheral service:(CBService *)service error:(NSError *)error;//发现特征服务
- (void)onDiscoverDescriptors:(CBPeripheral *)peripheral charact:(CBCharacteristic *)charact error:(NSError *)error;//发现特征描述
- (void)onFailToConnect:(CBPeripheral *)peripheral error:(NSError *)error;//连接失败
- (void)onUpdateValue:(CBCharacteristic *)charact error:(NSError *)error;//特征值变化更新
- (void)onReadRSSI:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error;//读取RSSI

@end

@interface BLEService : NSObject

@property (nonatomic) BOOL isConnected;//是否已连接
@property (nonatomic, retain) CBCentralManager *centralManager;//中心管理器
@property (nonatomic, retain) CBPeripheral *currentPeripheral;//当前外设设备
@property (nonatomic, retain) NSString *UUIDString;//当前连接设备的UUID

- (instancetype)initWithDelegate:(id)delegate;
- (BOOL)isReady;//判断蓝牙设备状态是否准备
- (void)scan:(NSNumber *)enable;//扫描外设
- (void)connectPeripheral:(CBPeripheral *)peripheral;//连接外设
- (void)disConnectPeripheral:(CBPeripheral *)peripheral;
- (void)discoverServices:(NSArray *)serviceUUIDs;//发现外围服务
- (void)discoverCharacteristics:(CBService *)service UUIDs:(NSArray *)UUIDs;//发现特征服务
- (void)discoverDescriptors:(CBCharacteristic *)charact;//发现描述服务
//- (void)discoverWrite:(CBCharacteristic *)charact;//发现描述服务

- (void)readRSSI;//读取RSSI
- (void)readValue:(CBCharacteristic *)charact;//读数据（特征）
- (void)readValueWithDesc:(CBDescriptor *)desc;//读数据（描述）
- (void)writeValue:(CBCharacteristic *)charact data:(NSData *)data;//写数据（特征）
- (void)writeValueWithDesc:(CBDescriptor *)desc data:(NSData *)data;//写数据（描述）
- (void)setNotify:(CBCharacteristic *)charact isNotify:(BOOL)isNotify;//设置通知



@end
