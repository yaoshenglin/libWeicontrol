//
//  BLEAutoConnect.m
//  BluetoothDemo
//
//  Created by varVery on 15/12/11.
//  Copyright © 2015年 David Sahakyan. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "BLEAutoConnect.h"
#import "Tools.h"

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

+ (NSString *)stringForFormatWithDic:(NSDictionary *)dic
{
    NSString *description = dic.description;
    NSString *tempStr1 = [description stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *tempStr3 = [[@"\"" stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    NSString *str = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:&error];
    if (error) {
        NSLog(@"format : %@",error.localizedDescription);
    }
    
    return str;
}

@end

@interface BLEAutoConnect ()<BLECallback>
{
    BOOL isDebugLog;//配置是否调试显示打印日志信息
    BOOL isUpdateing;//是否正在更新固件
    
    NSMutableArray *listDeviceName;
    NSMutableDictionary *serviceList;//扫描到的服务列表
    NSMutableDictionary *charactList;//扫描到的特征列表
    
    NSMutableData *dataBuffer;//数据缓冲区（存放大数据包的拆包传输数据）
    int defaultSplitByteLenth;//BLE蓝牙默认拆包大小为20字节
}
@end

@implementation BLEAutoConnect
{
    BLEService *ble;
    //固件更新使用--------------------------------start
    NSData *binFile;//待升级的固件
    NSTimer *timer;//计时器
    double currentInterval;//超时间隔（内部判断）
    double maxSecondTimeOut;//最大超时时间（秒）
    int maxRetryCount;//最大超时重试次数
    ushort splitCount;//分包大小//9;
    
    ushort totalCount;//总包数（长度/splitCount）
    short currentIndex;//当前包索引值（从1开始）
    NSData *currentByte;//当前包内容
    int repeatErrorCount;//错误重试次数（超出5次则认为更新失败）
    CBCharacteristic *upgradeCharact;//更新特性
    NSData *currentDeviceID;//设备ID
    NSData *firstFrame;//固件更新帧头
    NSData *replayFrame;//回复帧头
    //固件更新使用--------------------------------end
}

@synthesize callback,isDebugLog;

#pragma mark 初始化
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initWithParm];
    }
    return self;
}

- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        callback = delegate;
        [self initWithParm];
    }
    return self;
}

//初始化参数设置
- (void)initWithParm
{
    ble = [[BLEService alloc] initWithDelegate:self];
    isDebugLog = NO;//是否打印日志信息
    isUpdateing = NO;
    listDeviceName = [NSMutableArray array];
    serviceList = [NSMutableDictionary dictionary];
    charactList = [NSMutableDictionary dictionary];
    
    dataBuffer = [NSMutableData data];
    defaultSplitByteLenth = 20;
    
    //固件更新使用--------------------------------
    currentInterval = 0;//超时间隔（内部判断）
    maxSecondTimeOut = 0.3;//最大超时时间（秒）
    maxRetryCount = 20;//最大超时重试次数
    splitCount = 9;//分包大小//9;
    firstFrame = [[NSData alloc] initWithBytes:"\xD2" length:1];//帧头
    replayFrame = [[NSData alloc] initWithBytes:"\xD3" length:1];//帧头
}

#pragma mark 扫描并连接
- (void)ScanAndConnect:(NSData *)connectDeviceID
{
    currentDeviceID = connectDeviceID;
    [ble scan:@YES];//扫描
    [self performSelector:@selector(isReady) withObject:nil afterDelay:0.5];//确保蓝牙设备已准备好，以免正在打开状态弹出提示
}

#pragma mark 停止扫描并断开连接（一般供调试使用）
- (void)StopAndDisConnect
{
    currentDeviceID = nil;
    [self stop];//停止扫描
    if (ble.currentPeripheral) {
        [self disConnectDevice];//取消连接
    }
    
    [listDeviceName removeAllObjects];
}

#pragma mark 检测蓝牙设备是否开启（没有开启弹出提示，建议在UI层调用了ScanAndConnect后再调用此方法）
- (BOOL)isReady
{
    BOOL isReady = ble.isReady;
    NSLog(@"isReady :%@",@(isReady));
    return isReady;
}

- (BOOL)isConnected
{
    return ble.isConnected;
}

#pragma mark - Peripheral
#pragma mark 发现并连接设备
- (void)onDiscoverPeripheral:(CBPeripheral *)peripheral adData:(NSDictionary<NSString *,id> *)adData RSSI:(NSNumber *)RSSI
{
    if (isDebugLog) {
        //NSLog(@"扫描到设备 => UUID:%@ adData:%@ RSSI:%@",peripheral.identifier.UUIDString, adData, RSSI);
    }
    
    NSString *deviceName = [adData objectForKey:CBAdvertisementDataLocalNameKey] ?: peripheral.name;
    if (!deviceName)
        return;//过滤不合法的蓝牙设备
    
    if (isDebugLog) {
        if (deviceName && ![listDeviceName containsObject:deviceName]) {
            NSString *log = [NSString stringWithFormat:@"扫描到设备 => 名称:%@  RSSI:%@ adData:%@",deviceName,RSSI,[BLEService stringForFormatWithDic:adData]];
            NSLog(@"%@",log);
            [listDeviceName addObject:deviceName];
        }
    }
    
    if ([deviceName isEqualToString:Device_Name]) {
        //扫描结果匹配（连接指定蓝牙设备）
        NSData *deviceID = [adData objectForKey:CBAdvertisementDataManufacturerDataKey];//解析广播设备ID

        NSString *deviceIDStr = [Tools hexStringWithData:deviceID];
        if (deviceIDStr) {
            NSLog(@"ad deviceID:%@" , deviceIDStr);
            //ad deviceID:
        }
        
        BOOL canConnect = deviceID == nil || (currentDeviceID != nil && ([[Tools hexStringWithData:currentDeviceID] isEqualToString:deviceIDStr] || [deviceIDStr isEqualToString:@"00000000"]));
        if (canConnect) {
            //[self ConnectDevice:peripheral];
            if (isDebugLog)
                NSLog(@"准备连接蓝牙设备 -> deviceID:%@" , deviceIDStr);
            
            if (peripheral.state == CBPeripheralStateDisconnected) {
                [self ConnectDevice:peripheral];//连接设备
            }
        }
        
    }
}

#pragma mark 连接设备
- (void) ConnectDevice:(CBPeripheral *) peripheral
{
    if (ble.isConnected) {
        return;
    }
    
    if (isDebugLog) {
        NSLog(@"正在连接外设...");
    }
    
    [ble connectPeripheral:peripheral];
}

- (void)disConnectDevice
{
    [ble disConnectPeripheral:ble.currentPeripheral];//取消连接
}

- (void)reConnectToDevice
{
    [ble connectPeripheral:ble.currentPeripheral];//重新连接
}

#pragma mark 已连接设备
- (void)onConnect:(CBPeripheral *)peripheral
{
    if (isDebugLog) {
        NSLog(@"连接成功！正在发现外围服务...");
    }
    if ([callback respondsToSelector:@selector(onConnectState:)]) {
        [callback onConnectState:YES];
    }
}

#pragma mark 设备已断开连接
- (void)onDisconnect:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"%@已断开连接 err=%@",[peripheral.identifier UUIDString], error);
    }
    if ([callback respondsToSelector:@selector(onConnectState:)]) {
        [callback onConnectState:NO];
    }
    if (peripheral && currentDeviceID) {
        [ble.centralManager connectPeripheral:peripheral options:nil];//断开重连
    }
}

#pragma mark 连接失败
- (void)onFailToConnect:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"%@连接失败！ err=%@",[peripheral.identifier UUIDString], error);
    }
    if ([callback respondsToSelector:@selector(onConnectState:)]) {
        [callback onConnectState:NO];
    }
    //[self stop];//停止扫描
}

#pragma mark 发现服务通知
- (void)onDiscoverServices:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"发现了%ld个服务",(unsigned long)peripheral.services.count);
    }
    
    for (CBService *service in peripheral.services) {
        [serviceList setObject:service forKey:service.UUID.UUIDString];
        if (isDebugLog) {
            NSLog(@"service UUID:%@",service.UUID.UUIDString);
        }
        
        [ble discoverCharacteristics:service UUIDs:nil];
    }
        
    //以下注释代码仅在业务调整时调试使用
    //CBService *service = [self getServiceWithUUID:peripheral.services uuid:RxTx_Send_Server];//获取可写服务（对应内部获取）
    //CBService *service = [serviceList objectForKey:RxTx_Send_Server];//获取可写服务
    //[ble discoverCharacteristics:service UUIDs:nil];//发现特征
}

#pragma mark 发现特征通知
- (void)onDiscoverCharacteristics:(CBPeripheral *)peripheral service:(CBService *)service error:(NSError *)error
{
    if (isDebugLog) {
        NSLog(@"发现了%lu个特征",(unsigned long)service.characteristics.count);
    }
    
    for (CBCharacteristic *charact in service.characteristics) {
        [charactList setObject:charact forKey:charact.UUID.UUIDString];
        if (isDebugLog) {
            NSLog(@"characteristic UUID:%@  service UUID:%@",charact.UUID.UUIDString, service.UUID.UUIDString);
            [self logPropertie:charact];//打印特征属性
        }
        //设置通知（没有此业务功能请注释此段代码 --------------------------start
        NSString *UUIDString = charact.UUID.UUIDString;
        if ([UUIDString isEqualToString:RxTx_Notity]){
            [ble setNotify:charact isNotify:YES];
        }
        
        if ([UUIDString isEqualToString:RxTx_Send]) {
            //蓝牙可写特性
            if ([callback respondsToSelector:@selector(onDiscoverWriteCharact)]) {
                [callback onDiscoverWriteCharact];
            }
        }
        //设置通知（没有此业务功能请注释此段代码 --------------------------end
    }

}

//打印特征属性
- (void)logPropertie:(CBCharacteristic *)charact
{
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     */
    NSInteger propertie;
    NSLog(@"characteristic properties %ld UUID:%@",(long)charact.properties, charact.UUID.UUIDString);
    
    propertie = charact.properties & CBCharacteristicPropertyBroadcast;
    NSLog(@"Broadcast %@",@(propertie == CBCharacteristicPropertyBroadcast));
    propertie = charact.properties & CBCharacteristicPropertyRead;
    NSLog(@"Read %@",@(propertie == CBCharacteristicPropertyRead));
    propertie = charact.properties & CBCharacteristicPropertyWriteWithoutResponse;
    NSLog(@"WriteWithoutResponse %@",@(propertie == CBCharacteristicPropertyWriteWithoutResponse));
    propertie = charact.properties & CBCharacteristicPropertyWrite;
    NSLog(@"Write %@",@(propertie == CBCharacteristicPropertyWrite));
    propertie = charact.properties & CBCharacteristicPropertyNotify;
    NSLog(@"Notify %@",@(propertie == CBCharacteristicPropertyNotify));
    propertie = charact.properties & CBCharacteristicPropertyIndicate;
    NSLog(@"Indicate %@",@(propertie == CBCharacteristicPropertyIndicate));
    propertie = charact.properties & CBCharacteristicPropertyAuthenticatedSignedWrites;
    NSLog(@"AuthenticatedSignedWrites %@",@(propertie == CBCharacteristicPropertyAuthenticatedSignedWrites));
}

#pragma mark 发现特征描述
- (void)onDiscoverDescriptors:(CBPeripheral *)peripheral charact:(CBCharacteristic *)charact error:(NSError *)error
{
    for (CBDescriptor *desc in charact.descriptors) {
        if (isDebugLog) {
            NSLog(@"descriptor UUID:%@  characteristic UUID:%@",desc.UUID.UUIDString, charact.UUID.UUIDString);
        }
        
    }
}

#pragma mark 特征值变化通知
- (void)onUpdateValue:(CBCharacteristic *)charact error:(NSError *)error
{
    if (error)
        return;
    
    NSString *serviceUUID = charact.service.UUID.UUIDString;
    NSString *charactUUID = charact.UUID.UUIDString;
    if (isDebugLog) {
        NSLog(@"收到来自服务UUID:%@,特征UUID:%@ 的数据：%@",serviceUUID, charactUUID, [Tools hexStringWithData:charact.value]);
    }
    //固件更新判断处理---------------------------------start
    if (isUpdateing) {
        NSData *buffer = charact.value;
        if (!buffer || buffer.length < 1) {//无效数据
            if (isDebugLog) {
                NSLog(@"无效数据：%d",currentIndex + 1);
            }
            return;
        }
        BOOL flag = [Tools ValidCRCWithHost:buffer];
        if (!flag) {//校验失败
            if (isDebugLog) {
                NSLog(@"收到数据回复校验错误！当前帧为：%d",currentIndex + 1);
            }
            return;
        }
        
        if (![[buffer subdataWithRange:NSMakeRange(0, 1)] isEqualToData:replayFrame]) {//回复帧头失败
            if (isDebugLog) {
                NSLog(@"收到数据回复的帧头不正确！%d", currentIndex + 1);
            }
            return;
        }
        
        ushort replayIndex = currentIndex;//回复帧
        NSData *replayInexByte = [buffer subdataWithRange:NSMakeRange(7, 2)];

        replayIndex = [replayInexByte parseIntWithRange:NSMakeRange(0, replayInexByte.length)];
        if (replayIndex > 0) {
            replayIndex -= 1;
        
            ushort replayTotalCount = (ushort)[[buffer subdataWithRange:NSMakeRange(5, 2)] parseIntWithRange:NSMakeRange(0, buffer.length)];
            if (replayTotalCount == totalCount && abs(replayIndex - currentIndex) < 3)//防止旧锁回复帧数错乱容错处理
                currentIndex = replayIndex;//重新赋值当前帧
        }
        
        currentInterval = 0;//复位超时间隔
        repeatErrorCount = 0;//复位错误重度次数
        currentIndex += 1;//当前帧+1
        
        if (totalCount == currentIndex) {
            if ([timer isValid]) {
                [timer invalidate];//停止计时器
            }
            [self Completed];//更新完成
            if (isDebugLog) {
                NSLog(@"固件更新成功！更新完成。");
            }
            return;
        }
        
        currentByte = [binFile subdataWithRanges:NSMakeRange(currentIndex * splitCount, splitCount)];//从bin文件中取出当前需要发送的数据
        //最后一包不足splitCount(9)长度则补0xFF
        if (currentIndex == totalCount - 1)//最后一包
        {
            if (currentByte.length < splitCount)//需要补位
            {
                NSMutableData *contactByte = [NSMutableData data];
                NSMutableData *padData = [NSMutableData data];
                NSInteger length = splitCount - currentByte.length;
                for (int i = 0; i < length; i++)
                {
                    //补位0xFF
                    [padData appendBytes:"\xFF" length:1];
                }
                [contactByte appendData:currentByte];
                [contactByte appendData:padData];
                currentByte = contactByte;//补位后的Byte赋值给当前需要发送的Byte
            }
        }
        
        NSData *contactByte = [self makeContactByte];//构造组合数据
        currentByte = [Tools replaceCRCForSwitch:contactByte];//校验后的byte[]赋值给当前需要发送的byte[]
        if (isDebugLog) {
            NSLog(@"当前帧：%d/%d 发送数据：%@", currentIndex + 1, totalCount, [currentByte toHexString]);
        }
        [ble writeValue:upgradeCharact data:currentByte];//发送数据
        
        float progress = (float)(currentIndex + 1) / (float)totalCount;
        if ([callback respondsToSelector:@selector(onUpgradeProgress:)]) {
            [callback onUpgradeProgress:progress];//更新进度
        }
        
        return;
    }
    //固件更新判断处理---------------------------------end
    
    //正常数据回调-----------------------------------start
    if ([callback respondsToSelector:@selector(onUpdateValue:formatData:error:)]) {
        NSData *mData = charact.value;//原始数据
        BOOL enablePackData = NO;//是否启用拆包数据
        BOOL isPackStartData = NO;//是否拆包启始数据
        BOOL isPackEndData = NO;//是否拆包结尾数据
        
        //特殊业务数据解析----------------------------start
        NSString *formatData = @"";
        if ([serviceUUID isEqualToString:Device_Info_Server]) {
            //设备信息服务
            formatData = [[NSString alloc] initWithData:mData encoding:NSASCIIStringEncoding];
            [callback onUpdateValue:mData formatData:formatData error:error];
            return;
        }else if([serviceUUID isEqualToString:Device_Battery_Server]){//电池电量信息
            long value = strtol([[mData toHexString] UTF8String],nil,16);
            formatData = [NSString stringWithFormat:@"电量:%ld%%",value];
            [callback onUpdateValue:mData formatData:formatData error:error];
            return;
        }else{
            if (mData.length < 3)
                return;//过滤不是有效的数据（协议帧头为2个字节，数据长度1个字节）
            
        }
        //特殊业务数据解析----------------------------end
        
        if (enablePackData) {
            
            //分析拆包数据-------------------------------start
            //511B为协议帧头 11为数据长度（十六进制）11 => 17（十进制）
            if (mData.length == defaultSplitByteLenth) {
                //总帧长度为：17 + 2 + 1 = 20（20为BLE蓝牙默认传输最大字节）
                NSData *mPackChar = [@"511B11" dataWithHexString];//此处根据业务协议修改此规则即可
                NSData *packChar = [mData subdataWithRange:NSMakeRange(0, 3)];//此处根据业务协议修改此规则即可
                
                isPackStartData =  [packChar isEqualToData:mPackChar];
                if (isPackStartData) {
                    NSLog(@"发现数据是拆包数据，需要等待组合返回！");
                }
                
            }else{
                isPackEndData = dataBuffer.length > 0;
                if (isPackEndData) {
                    NSLog(@"发现拆包数据接收完成！");
                }
                
            }
            
            if (isPackStartData) {
                //拆包数据并且还没接收完成数据，等待数据接收完整
                NSData *data = [mData subdataWithRange:NSMakeRange(3, mData.length-3)];
                [dataBuffer appendData:data];//此处根据业务协议修改此规则即可
                return;
            }else{
                NSData *data = [mData subdataWithRange:NSMakeRange(3, mData.length-3)];
                if (isPackEndData) {
                    //拆包数据结尾，需要组合返回
                    [dataBuffer appendData:data];//此处根据业务协议修改此规则即可
                    
                    mData = dataBuffer;
                    dataBuffer = [NSMutableData data];//清空缓冲区
                }else{//不是拆包数据直接返回
                    //清除协议帧头
                    if (mData.length > 3) {
                        //2个协议头+1个数据长度
                        mData = data;
                    }
                }
                
                
            }
            //分析拆包数据-------------------------------end
        }
        
        formatData = [[NSString alloc] initWithData:mData encoding:NSASCIIStringEncoding];
        [callback onUpdateValue:mData formatData:formatData error:error];
        
    }
    //正常数据回调-----------------------------------end
}

#pragma mark 读取RSSI
- (void)onReadRSSI:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    if (error)
        return;
    
    if ([callback respondsToSelector:@selector(onReadRSSI:error:)]) {
        [callback onReadRSSI:RSSI error:error];
    }
    else if (isDebugLog) {
        NSLog(@"当前RSSI：%@",RSSI);
    }
    
}

////根据UUID拿取指定Service（仅供内部使用）
//- (CBService *)getServiceWithUUID:(NSArray *)services uuid:(NSString *)uuid
//{
//    CBService *service = nil;
//    for (int i = 0; i< services.count; i++) {
//        service = services[i];
//        NSString *serviceUUID = service.UUID.UUIDString;
//        if ([serviceUUID isEqualToString:uuid]) {
//            service = services[i];
//            break;
//        }
//    }
//    
//    return service;
//}

#pragma mark - UI交互操作
#pragma mark 读取RSSI（对应onReadRSSI）
- (void)readRSSI
{
    [ble readRSSI];
}

#pragma mark 读取设备信息（对应onUpdateValue）
- (void)readDeviceInfo
{
    CBService *service = [serviceList objectForKey:Device_Info_Server];
    for (CBCharacteristic *charact in service.characteristics) {
        [ble readValue:charact];
    }
}

#pragma mark 读取设备电量信息（对应onUpdateValue）
- (void)readBatteryInfo
{
    CBCharacteristic *charact = [charactList objectForKey:RxTx_Read_Battery];
    if (charact) {
        [ble readValue:charact];
    }
}

#pragma mark 发送数据给设备（对应onUpdateValue）
- (BOOL)sendData:(NSData *)data
{
    if (!ble.isConnected) {
        NSLog(@"蓝牙未连接，发送失败");
        NSString *errMsg = NSLocalizedString(@"BluetoothConnectedFailed", nil);//蓝牙未连接，发送失败
        NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"The bluetooth not connected." code:-1 userInfo:info];
        if ([callback respondsToSelector:@selector(onDidFailToSendDataWithError:)]) {
            [callback onDidFailToSendDataWithError:error];
        }
        return NO;
    }
    CBCharacteristic *charact = [charactList objectForKey:RxTx_Send];
    if (charact) {
        NSLog(@"发送到蓝牙设备数据:%@",[data toHexString]);
        [ble writeValue:charact data:data];
    }
    return YES;
}

#pragma mark 设置特性通知
- (void)setNotify:(BOOL)isNotify
{
    CBCharacteristic *charact = [charactList objectForKey:RxTx_Notity];
    if (charact) {
        [ble setNotify:charact isNotify:isNotify];
    }
}

#pragma mark - 结束释放对象
#pragma mark 停止连接（内部调用）
- (void)stop
{
    [ble scan:@NO];//停止自动扫描机制
    [ble.centralManager stopScan];//停止扫描
}

#pragma mark 关闭服务（外部调用）
- (void)Close
{
    [ble disConnectPeripheral:ble.currentPeripheral];
    [self stop];
    ble.isConnected = NO;
    ble.centralManager = nil;
    ble.currentPeripheral = nil;
    serviceList = nil;
    charactList = nil;
    if ([timer isValid]) {
        [timer invalidate];
    }
    if ([callback respondsToSelector:@selector(onConnectState:)]) {
        [callback onConnectState:NO];
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];//恢复可锁屏状态
}

#pragma mark - 固件更新
#pragma mark 初始化回调
- (void)UpgradeInit:(NSData *)deviceID binData:(NSData *)binData
{
    if (ble == nil || deviceID == nil || binData == nil) {
        [self UpgradeError:NSLocalizedString(@"Parameter error!",nil)];//参数有误
        return;
    }

    currentDeviceID = deviceID;
    if ([callback respondsToSelector:@selector(onUpgradeInit:fileVer:viewVer:)]) {
        //校验固件包
        [Tools ValidCRCWithFirmware:binData complete:^(NSData *data, int type, int fileVer, float viewVer) {
            binFile = data;
            [callback onUpgradeInit:type fileVer:fileVer viewVer:viewVer];
        }];
    }
}
#pragma mark 开始更新固件
- (void)UpgradeStart
{
    if (ble == nil || currentDeviceID == nil || binFile == nil) {
        [self UpgradeError:NSLocalizedString(@"Parameter_Error_Initialize",nil)];//参数有误！请先初始化后再操作
        return;
    }
    
    if (!ble.isConnected) {
        [self UpgradeError:NSLocalizedString(@"OperationAfterConnectBluetooth",nil)];
        return;
    }
    
    //开始更新
//    发送协议（大端模式，20个字节）：
//    0xD2 + 设备ID（4个字节）+ 总帧数（2个字节）+ 当前帧（2个字节）+ 9个数据 + CRC(和校验) + CRC（异或校验）
//    回复协议（20个字节）：
//    0xD3 + 设备ID（4个字节）+ 总帧数（2个字节）+ 当前帧（2个字节）+ 补0（9个字节） + CRC(和校验) + CRC（异或校验）
    
    CBCharacteristic *charact = [charactList objectForKey:RxTx_Send];
    if (!charact) {
        [self UpgradeError:NSLocalizedString(@"UpdateUnAvailable",nil)];//更新不可用，请在发现特性后调用
        return;
    }
    
    if ([callback respondsToSelector:@selector(onUpgradeStarted)]) {
        [callback onUpgradeStarted];
    }
    
    if (isUpdateing) {
        return;//上一次更新中断了，等待用户重新更新
    }
    
    upgradeCharact = charact;
    isUpdateing = YES;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];//升级过程不锁屏
    
    //更新逻辑开始
    totalCount = (ushort)ceil((float)binFile.length/(float)splitCount);
    currentIndex = 0;//复位当前包索引
    currentInterval = 0;//复位超时间隔
    repeatErrorCount = 0;//复位错误重试次数
    currentByte = [binFile subdataWithRange:NSMakeRange(currentIndex * splitCount, splitCount)];//从bin文件中取出当前需要发送的数据
    NSData *contactByte = [self makeContactByte];//构造组合数据
    currentByte = [Tools replaceCRCForSwitch:contactByte];//校验后的byte[]赋值给当前需要发送的byte[]
    if (isDebugLog) {
        NSLog(@"当前帧：%d/%d 发送数据：%@", currentIndex + 1, totalCount, [currentByte toHexString]);
    }
    [ble writeValue:upgradeCharact data:currentByte];//写入数据
    
    //定时器精度0.1秒
    timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

#pragma mark Timer超时/重试
- (void)updateTime
{
    if (repeatErrorCount >= maxRetryCount) {//最多连续重试maxRetryCount次
        if ([timer isValid]) {
            [timer invalidate];
        }
        [self UpgradeError:NSLocalizedString(@"UpdateFailed!The_end",nil)];//@"固件更新失败！更新已退出。"
        return;
    }
    
    if (currentInterval >= maxSecondTimeOut) {//0.2秒超时
        //发包超时
        //重新发送当前索引包
        if (currentByte != nil) {
            currentInterval = 0;//复位超时间隔
            repeatErrorCount += 1;//重试次数+1
            if (isDebugLog) {
                NSLog(@"重试:%d次,内容长度:%d, %d/%d 正在重发数据... %@", repeatErrorCount, (int)currentByte.length, currentIndex + 1, totalCount, [currentByte toHexString]);
            }
            [ble writeValue:upgradeCharact data:currentByte];//重发数据
        }
    } else{
        //发包延时
        currentInterval += 0.1;//时间增加100豪秒
        if (isDebugLog) {
            NSLog(@"发送命令超时 -> %d/%d 近世时间:%fs", currentIndex + 1, totalCount, currentInterval);
        }
    }

}

#pragma mark 更新进度变化
- (void)Progress:(float)progress
{
    if ([callback respondsToSelector:@selector(onUpgradeProgress:)]) {
        [callback onUpgradeProgress:progress];
    }
}

#pragma mark 更新出现了错误
- (void)UpgradeError:(NSString *)errMsg
{
    isUpdateing = NO;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];//恢复可锁屏状态
    if ([callback respondsToSelector:@selector(onUpgradeError:)]) {
        [callback onUpgradeError:errMsg];
    }
}

#pragma mark 更新完成
- (void)Completed
{
    isUpdateing = NO;
    currentByte = nil;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];//恢复可锁屏状态
    if ([timer isValid]) {
        [timer invalidate];
    }
    if ([callback respondsToSelector:@selector(onUpgradeCompleted)]) {
        [callback onUpgradeCompleted];
    }
}

#pragma mark 构造Byte结构数据
- (NSData *) makeContactByte
{
    Byte totalByteH = (Byte)((totalCount >> 8) & 0xFF);//取高位
    Byte totalByteL = (Byte)(totalCount & 0xFF);//取低位
    Byte totalByte[] = { totalByteH, totalByteL };//高位在左,低位在右
    
    Byte indexByteH = (Byte)(((currentIndex + 1) >> 8) & 0xFF);//取高位
    Byte indexByteL = (Byte)((currentIndex + 1) & 0xFF);//取低位
    Byte indexByte[] = { indexByteH, indexByteL };//高位在左,低位在右
    
    //帧头 + 设备ID + 总包数 + 当前索引包 + 当前分包数据
    NSMutableData *contactByte = [NSMutableData data];
    [contactByte appendData:firstFrame];
    [contactByte appendData:currentDeviceID];
    [contactByte appendBytes:totalByte length:sizeof(totalByte)];
    [contactByte appendBytes:indexByte length:sizeof(indexByte)];
    [contactByte appendData:currentByte];
    
    return contactByte;
}

@end
