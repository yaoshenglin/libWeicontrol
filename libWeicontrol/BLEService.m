//
//  BLEService.m
//  BluetoothDemo
//
//  Created by varVery on 15/12/15.
//  Copyright © 2015年 David Sahakyan. All rights reserved.
//

#import "BLEService.h"

@interface BLEService ()<CBCentralManagerDelegate,CBPeripheralDelegate>//CBPeripheralManagerDelegate
{
    BOOL isDebugLog;//是否打开调试Log
    NSInteger SCAN_INTERVAL;//自动扫描频率间隔
    id callback;
    BOOL isFirst;
    BOOL isScanning;//是否在扫描中（不使用IOS9.0以上系统内置的判断方法BOOL isScanning NS_AVAILABLE(NA, 9_0)）；
}

@end

@implementation BLEService
@synthesize isConnected;

- (instancetype)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        isFirst = YES;
        [self initWithParm:delegate];
    }
    return self;
}

- (void)initWithParm:(id)delegate
{
    callback = delegate;
    //self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue options:@{CBCentralManagerOptionShowPowerAlertKey:@YES}];
    isConnected = NO;
    SCAN_INTERVAL = 3;
    isDebugLog = NO;
}

- (BOOL)isReady
{
    return (self.centralManager.state == CBCentralManagerStatePoweredOn);
}

//扫描周围的蓝牙（连上了后不在扫描连接）
- (void)scan:(NSNumber *)enable
{
    if (isConnected) {
        enable = @NO;
    }
    BOOL isready = self.isReady;
    if (isready) {
        if (isFirst) {
            SCAN_INTERVAL = 0.1;
            isFirst = NO;
        }else{
            SCAN_INTERVAL = 3;
        }
    }
    else
        SCAN_INTERVAL = 0.1;
    
    if (enable.boolValue) {
        [self performSelector:@selector(scan:) withObject:@YES afterDelay:SCAN_INTERVAL];
        if (!isready)
            return;//蓝牙设备未准备好
        if (!isConnected) {
            if (isScanning) {//self.centralManager.isScanning
                [self.centralManager stopScan];
                isScanning = NO;
            }
            [self performSelector:@selector(startScan) withObject:nil afterDelay:SCAN_INTERVAL + 0.3];
        }
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];//取消延时调用，防止内存泄露
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scan:) object:nil];
        [self.centralManager stopScan];
        isScanning = NO;
    }
}

//开始扫描外设
- (void)startScan
{
    if (!self.isReady || isScanning || isConnected) {
        //self.centralManager.isScanning
        return;
    }
    if (isDebugLog) {
        NSLog(@"Ready! 正在扫描外设...");
    }
    
    isScanning = YES;
    NSDictionary *dic = @{CBCentralManagerScanOptionAllowDuplicatesKey:@NO};
    [self.centralManager scanForPeripheralsWithServices:nil options:dic];
}

#pragma mark - --------CentralManager(与设备交互部分)
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    /*
     typedef NS_ENUM(NSInteger, CBCentralManagerState) {
     CBCentralManagerStateUnknown = 0,
     CBCentralManagerStateResetting,
     CBCentralManagerStateUnsupported,
     CBCentralManagerStateUnauthorized,
     CBCentralManagerStatePoweredOff,
     CBCentralManagerStatePoweredOn,
     };
     */
    if (central.state == CBCentralManagerStatePoweredOn) {
        isFirst = YES;
        [self scan:@YES];
        NSLog(@"BLE Device ON");
    }else {
        [self scan:@NO];
        isConnected = NO;
    }
    if (central.state == CBCentralManagerStatePoweredOff) {
        NSLog(@"BLE Device OFF");
        if ([callback respondsToSelector:@selector(onDisconnect:error:)]) {
            [callback onDisconnect:self.currentPeripheral error:nil];
        }
    }
    if (isDebugLog) {
        NSLog(@"centralManagerDidUpdateState => state:%ld",(long)central.state);
    }
}

//已连接
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    isConnected = YES;
    if (isDebugLog) {
        NSLog(@"didConnectPeripheral => state:%ld",(long)peripheral.state);
    }
    peripheral.delegate = self;//此句关键，否则不会回调发现服务！
    self.currentPeripheral = peripheral;
    if ([callback respondsToSelector:@selector(onConnect:)]) {
        [callback onConnect:peripheral];
    }
    
    [peripheral discoverServices:nil];//发现服务
    //[peripheral performSelector:@selector(discoverServices:) withObject:nil afterDelay:0.5];
}

//已断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    isConnected = NO;
    if (isDebugLog) {
        NSLog(@"didDisconnectPeripheral => UUID:%@ state:%ld err:%@",peripheral.identifier.UUIDString, (long)peripheral.state, error.description);
    }
    if ([callback respondsToSelector:@selector(onDisconnect:error:)]) {
        [callback onDisconnect:peripheral error:error];
    }
}

//连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    isConnected = NO;
    if (isDebugLog) {
        NSLog(@"didFailToConnectPeripheral => state:%ld err:%@",(long)peripheral.state, error.description);
    }
    if ([callback respondsToSelector:@selector(onFailToConnect:error:)]) {
        [callback onFailToConnect:peripheral error:error];
    }
}

//已发现外围设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (isDebugLog) {
        NSString *deviceName = peripheral.name ?: [advertisementData objectForKey:@"kCBAdvDataLocalName"];
        NSLog(@"didDiscoverPeripheral => Device UUID:%@ name:%@ state:%ld data:%@ rssi:%@",peripheral.identifier.UUIDString, deviceName, (long)peripheral.state, advertisementData,RSSI);
    }
    if ([callback respondsToSelector:@selector(onDiscoverPeripheral:adData:RSSI:)]) {
        [callback onDiscoverPeripheral:peripheral adData:advertisementData RSSI:RSSI];
    }
}


#pragma mark - --------Peripheral(与设备交互部分)------------------------

#pragma mark 发现特征服务
- (void)discoverServices:(NSArray *)serviceUUIDs
{
    /*
     typedef NS_ENUM(NSInteger, CBPeripheralState) {
     CBPeripheralStateDisconnected = 0,
     CBPeripheralStateConnecting,
     CBPeripheralStateConnected,
     CBPeripheralStateDisconnecting NS_AVAILABLE(NA, 9_0),
     } NS_AVAILABLE(NA, 7_0);
     */
    if (isDebugLog) {
        NSLog(@"peripheral state:%ld",(long)self.currentPeripheral.state);
    }
    [self.currentPeripheral discoverServices:serviceUUIDs];
}

#pragma mark 连接外设
- (void)connectPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral) return;
    self.currentPeripheral = peripheral;
    //NSDictionary *option = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,CBConnectPeripheralOptionNotifyOnNotificationKey:@YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES};
    [self.centralManager connectPeripheral:peripheral options:nil];
    NSUUID *identifier = peripheral.identifier;
    _UUIDString = identifier.UUIDString;
    NSLog(@"name:%@, identifier:%@",peripheral.name,_UUIDString);
}

#pragma mark 取消连接
- (void)disConnectPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral) return;
    [self.centralManager cancelPeripheralConnection:peripheral];
    NSLog(@"取消连接");
}

#pragma mark peripheral
//发现外围设备服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didDiscoverServices => Device UUID:%@ err:%@",peripheral.identifier.UUIDString, error.description);
    }
    if ([callback respondsToSelector:@selector(onDiscoverServices:error:)]) {
        [callback onDiscoverServices:peripheral error:error];
    }
}

#pragma mark 发现特征
- (void)discoverCharacteristics:(CBService *)service UUIDs:(NSArray *)UUIDs
{
    [self.currentPeripheral discoverCharacteristics:UUIDs forService:service];
    
}

#pragma mark 发现特征服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didDiscoverCharacteristicsForService => UUID:%@ err:%@",[service.UUID UUIDString], error.description);
    }
    if ([callback respondsToSelector:@selector(onDiscoverCharacteristics:service:error:)]) {
        [callback onDiscoverCharacteristics:peripheral service:service error:error];
    }
}

#pragma mark 发现描述服务
- (void)discoverDescriptors:(CBCharacteristic *)charact
{
    [self.currentPeripheral discoverDescriptorsForCharacteristic:charact];
}

#pragma mark 读取RSSI
- (void)readRSSI
{
    [self.currentPeripheral readRSSI];
}

#pragma mark 读数据（特征）
- (void)readValue:(CBCharacteristic *)charact
{
    [self.currentPeripheral readValueForCharacteristic:charact];
}

#pragma mark 读数据（描述）
- (void)readValueWithDesc:(CBDescriptor *)desc
{
    [self.currentPeripheral readValueForDescriptor:desc];
}

#pragma mark 写数据（特征）
- (void)writeValue:(CBCharacteristic *)charact data:(NSData *)data
{
    CBCharacteristicWriteType type = (charact.properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse ? CBCharacteristicWriteWithoutResponse : CBCharacteristicWriteWithResponse;
    [self.currentPeripheral writeValue:data forCharacteristic:charact type:type];
}

#pragma mark 写数据（描述）
- (void)writeValueWithDesc:(CBDescriptor *)desc data:(NSData *)data
{
    [self.currentPeripheral writeValue:data forDescriptor:desc];
}

#pragma mark 设置特性通知
- (void)setNotify:(CBCharacteristic *)charact isNotify:(BOOL)isNotify
{
    [self.currentPeripheral setNotifyValue:isNotify forCharacteristic:charact];
}

#pragma mark 特征值变化回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didUpdateValueForCharacteristic => UUID:%@ data:%@ err:%@",characteristic.UUID.UUIDString, characteristic.value, error.description);
    }
    if ([callback respondsToSelector:@selector(onUpdateValue:error:)]) {
        [callback onUpdateValue:characteristic error:error];
    }
}

#pragma mark 特征值状态变化更新通知
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didUpdateNotificationStateForCharacteristic => UUID:%@ err:%@",characteristic.UUID.UUIDString, error.description);
    }
}

#pragma mark 描述值更新变化
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didUpdateValueForDescriptor => data:%@ err:%@",descriptor.value, error.description);
    }
}

#pragma mark 写入特征值完成
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didWriteValueForCharacteristic => UUID:%@ err:%@",characteristic.UUID.UUIDString, error.description);
    }
//忽略写入成功回调（是否成功用didUpdateValueForCharacteristic判断）
//    if ([callback respondsToSelector:@selector(onUpdateValue:error:)]) {
//        [callback onUpdateValue:characteristic error:error];
//    }
}

#pragma mark 发现特征描述完成
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didDiscoverDescriptorsForCharacteristic => data:%@ err:%@",characteristic.value, error.description);
    }
    if ([callback respondsToSelector:@selector(onDiscoverDescriptors:charact:error:)]) {
        [callback onDiscoverDescriptors:peripheral charact:characteristic error:error];
    }
}

#pragma mark 写入扫描值完成
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"didWriteValueForDescriptor => UUID:%@ err:%@",descriptor.UUID.UUIDString, error.description);
    }
}

#pragma mark 读取RSSI完成
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    if ([callback respondsToSelector:@selector(onReadRSSI:didReadRSSI:error:)]) {
        [callback onReadRSSI:peripheral didReadRSSI:RSSI error:error];
    }else{
        if (isDebugLog) {
            NSLog(@"didReadRSSI => UUID:%@ RSSI:%@",peripheral.identifier.UUIDString, RSSI);
        }
    }
    
    if (error) {
        NSLog(@"didReadRSSI => err:%@", error.description);
    }
}

//- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error
//{
//    if ([callback respondsToSelector:@selector(onReadRSSI:didReadRSSI:error:)]) {
//        [callback onReadRSSI:peripheral didReadRSSI:peripheral.RSSI error:error];
//    }
//}

@end
