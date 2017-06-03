//
//  Tools.m
//  iFace
//
//  Created by APPLE on 14-9-10.
//  Copyright © 2014年 weicontrol. All rights reserved.
//

#import "Tools.h"

//定义指针常量
NSString *const A0 = @"A0";//开关关
NSString *const A1 = @"A1";//开关开
NSString *const A3 = @"A3";//开锁
NSString *const A4 = @"A4";//读取开关(插座)状态
NSString *const A5 = @"A5";//开启智能匹配模式
NSString *const A6 = @"A6";//读取主机ID
NSString *const A7 = @"A7";//关闭远程UDP连接通道
NSString *const A8 = @"A8";//开启红外学习模式
NSString *const A9 = @"A9";//发送红外学习指令
NSString *const AA = @"AA";//主机心跳包
NSString *const AC = @"AC";//读取主机温度
NSString *const C8 = @"C8";//取消学习
NSString *const DF = @"DF";//发送红外码库指令

NSString *const codeEncryptKey = kEncryptKey;//加密密钥

@implementation Tools

+ (NSString *)getPlistFileName
{
    NSString *DBFile = @".plist";
#ifdef Extranet
    DBFile = @".plist";//外网
#elif beta
    DBFile = @"(测试外网).plist";//测试外网
#else
    DBFile = @"(内网).plist";//内网
#endif
    DBFile = [AppIdentifier stringByAppendingString:DBFile];
    return DBFile;
}

+ (NSString *)getCacheDataPath
{
    NSString *path = [@"~/Library" stringByExpandingTildeInPath];
    path = [path stringByAppendingPathComponent:@"CacheData"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"目录创建失败,%@",error.localizedDescription);
        }else{
            [@{} writeToFile:path atomically:YES];
        }
    }
    
    if ([fileManager fileExistsAtPath:path]) {
        NSString *name = [Tools getPlistFileName];
        path = [path stringByAppendingPathComponent:name];
        return path;
    }
    
    return nil;
}

+ (void)setUserData:(id)obj key:(NSString *)key
{
    if (!key) return;
    NSString *path = [Tools getCacheDataPath];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithValidContentsOfFile:path];
    if (obj) {
        [dic setObject:obj forKey:key];//键值对不同则写入
    }else{
        [dic removeObjectForKey:key];//删除对应的键值
#ifdef Extranet
        removeObjectForKey(key);
#endif
    }
    [dic writeToFile:path atomically:YES];
}

+ (void)setDifferentUserData:(id)obj key:(NSString *)key
{
    //减少不必要的写入
    if (!key) return;
    
    NSString *path = [Tools getCacheDataPath];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithValidContentsOfFile:path];
    
    if (obj && ![obj isEqual:[Tools getUserData:key]]) {
        [dic setObject:obj forKey:key];//键值对不同则写入
    }
    else if (!obj && [Tools getUserData:key]) {
        [dic removeObjectForKey:key];//删除对应的键值
    }else{
        return;
    }
    
    [dic writeToFile:path atomically:YES];
}

+ (void)removeObjectForKey:(NSString *)key
{
    if (!key) return;
    NSString *path = [Tools getCacheDataPath];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithValidContentsOfFile:path];
    [dic removeObjectForKey:key];
    [dic writeToFile:path atomically:YES];
#ifdef Extranet
    removeObjectForKey(key);
#endif
}

+ (id)getUserData:(NSString *)key
{
    if (!key) return nil;
    NSString *path = [Tools getCacheDataPath];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithValidContentsOfFile:path];
    id obj = [dic objectForKey:key];
    if (!obj) {
#ifdef Extranet
        obj = getUserData(key);//兼容旧版本
        if (obj) {
            [Tools setUserData:obj key:key];
            removeObjectForKey(key);
        }
#endif
    }
    return obj;
}

+ (BOOL)validForKey:(NSString *)key
{
    if (!key) return NO;
    NSString *path = [Tools getCacheDataPath];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithValidContentsOfFile:path];
    id obj = [dic objectForKey:key];
    if (!obj) {
#ifdef Extranet
        obj = getUserData(key);//兼容旧版本
        if (obj) {
            [Tools setUserData:obj key:key];
            removeObjectForKey(key);
            return YES;
        }
#endif
        return NO;
    }
    return YES;
}

#pragma mark - -------生成随机数----------------
+ (NSInteger)getRandomNumber:(NSInteger)from to:(NSInteger)to
{
    return (NSInteger)(from + (arc4random() % (to - from + 1)));
}

+ (NSString *)hexStringWithData:(NSData *)data
{
    NSString *dataStr = data.description;
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@"<" withString:@""];//去掉'<'
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@">" withString:@""];//去掉'>'
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@" " withString:@""];//去掉空格
    dataStr = [dataStr uppercaseString];//转为大写
    
    return dataStr;
}

#pragma mark - --------解密字符串
//+ (NSString *)decryptString:(NSString *)str
//{
//    return [StringEncryption decryptString:str];
//}
//
//+ (NSString *)decryptString:(NSString *)str encoding:(NSStringEncoding)encoding
//{
//    return [StringEncryption decryptString:str encoding:encoding];
//}
//
//+ (NSString *)decryptFrom:(NSString *)str
//{
//    NSString *Separate = @"/App/";
//    NSArray *list = [str componentsSeparatedByString:Separate];
//    if ([list count] == 2) {
//        NSString *str = [list objectAtIndex:1];
//        
//        str = [str stringByReplacingOccurrencesOfString:@"_" withString:@"+"];
//        str = [str stringByReplacingOccurrencesOfString:@"~" withString:@"+"];
//        str = [str stringByReplacingOccurrencesOfString:@"!" withString:@"/"];
//        str = [str stringByReplacingOccurrencesOfString:@"|" withString:@"/"];
//        NSString *content = [Tools decryptString:str];
//        if (content.length > 0) {
//            return content;
//        }
//    }
//    
//    return str;
//}

//加密字符串
//+ (NSString *)encryptString:(NSString *)str
//{
//    return [StringEncryption encryptString:str];
//}
//
//+ (NSString *)encryptFrom:(NSString *)str
//{
//    NSString *string = [Tools encryptString:str];
//    string = [NSString format:@"%@/App/%@",k_host,string];
//    
//    return string;
//}

#pragma mark 获取有效域名
+ (NSString *)getValidHostname:(NSString *)hostname
{
    NSString *domainLow = [hostname lowercaseString];
    if ([domainLow hasPrefix:@"http://"]) {
        domainLow = [hostname substringFromIndex:7];
    }
    else if ([domainLow hasPrefix:@"https://"]) {
        domainLow = [hostname substringFromIndex:8];
    }
    
    domainLow = [domainLow lowercaseString];
    return domainLow;
}

#pragma mark - -------获取主机ID（主机MAC地址去除冒号后的字符串）----------------
+ (NSString *)getHostMacID
{
    NSString *result = [Tools getUserData:@"host_mac"];
    result = result.length > 0 ? result : @"FFFFFFFFFFFF";
    return result;
}

#pragma mark 判断有没有配置主机
+ (BOOL)isConfiged
{
    NSString *result = [Tools getUserData:@"host_mac"];
    if (result.length > 0 && ![result isEqualToString:@"FFFFFFFFFFFF"]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - -------构造读取主机ID指令----------------
+ (NSData *)makeReadControlData
{
    NSString *host_mac = [self getHostMacID];
    
    NSData *data = [[NSString format:@"A6%@00000000",host_mac] dataByHexString];
    data = [self replaceCRCForSwitch:data];
    return data;
}

#pragma mark 构造广播主机ID指令
+ (NSData *)makeBroadcastData
{
    NSString *host_mac = @"A6FFFFFFFFFFFF00000000";
    NSData *data = [host_mac dataByHexString];
    data = [Tools replaceCRCForSwitch:data];
    
    return data;
}

#pragma mark - -------构造断开连接指令 A7主机从机----------------
+ (NSData *)makeOffOrder
{
    NSString *host_mac = [self getHostMacID];
    
    NSData *data = [[NSString format:@"A7%@00000000",host_mac] dataByHexString];
    data = [self replaceCRCForSwitch:data];
    return data;
}

#pragma mark - -------构造读取主机温度指令----------------
+ (NSData *)makeReadTempData
{
    NSString *host_mac = [self getHostMacID];
    
    NSData *data = [[NSString stringWithFormat:@"AC%@00000000",host_mac] dataByHexString];
    data = [self replaceCRCForSwitch:data];
    return data;
}

#pragma mark - -------构造从机读取状态指令----------------
+ (NSData *)makeSlaveReadData:(NSString*)host_mac slave_mac:(NSString*)slave_mac
{
    NSData *data = [self makeSlaveReadData:host_mac slave_mac:slave_mac relay:NO slave2:nil];
    
    return data;
}

+ (NSData *)makeSlaveReadData:(NSString*)host_mac slave_mac:(NSString*)slave_mac relay:(BOOL)isRelay slave2:(NSString *)slave2_mac
{
    if (!host_mac) {
        NSLog(@"主机ID为空！");
        host_mac = @"FFFFFFFFFFFF";
    }
    //"A4" + host_mac + bean.slave_mac + "1155"   读取
    NSString *relay = isRelay ? @"01" : @"00";
    slave2_mac = slave2_mac ?: @"00000000";
    NSString *joinStr = [NSString stringWithFormat:@"A4%@%@%@%@",host_mac,slave_mac,relay,slave2_mac];
    NSData *data = [joinStr dataByHexString];
    
    data = [self replaceCRCForSwitch:data];
    
    return data;
}

+ (NSData *)makeSlaveReadData:(NSString*)host_mac slave_mac:(NSString*)slave_mac relay:(BOOL)isRelay index:(int)index slave2:(NSString *)slave2_mac
{
    if (!host_mac) {
        NSLog(@"主机ID为空！");
        host_mac = @"FFFFFFFFFFFF";
    }
    //"A4" + host_mac + bean.slave_mac + "1155"   读取
    NSString *relay = isRelay ? @"01" : @"00";
    NSString *indexStr = [NSString format:@"%02X",index];
    slave2_mac = slave2_mac ?: @"00000000";
    NSString *joinStr = [NSString stringWithFormat:@"A4%@%@%@%@%@",host_mac,slave_mac,relay,indexStr,slave2_mac];
    NSData *data = [joinStr dataByHexString];
    
    data = [self replaceCRCForSwitch:data];
    
    return data;
}

#pragma mark - -------构造心跳包回复指令----------------
+ (NSData*)makeReplyHeartData:(NSString*)host_mac
{
    NSData *data = [[NSString stringWithFormat:@"EA%@",host_mac] dataByHexString];
    data = [self replaceCRCForSwitch:data];
    return data;
}

#pragma mark - -------构造从机开关指令----------------
+ (NSData*)makeSlaveActionData:(NSString*)host_mac slave:(NSString*)slave_mac onOpen:(BOOL)onOpen
{
    NSData *data = [self makeSlaveActionData:host_mac slave:slave_mac onOpen:onOpen relay:NO slave2:nil];
    
    return data;
}

+ (NSData*)makeSlaveActionData:(NSString*)host_mac slave:(NSString*)slave_mac onOpen:(BOOL)onOpen relay:(BOOL)isRelay slave2:(NSString *)slave2_mac
{
    //"A1" + host_mac + bean.slave_mac + "1155"   开
    //"A0" + host_mac + bean.slave_mac + "1155"   关
    NSString *head = onOpen ? A1 : A0;
    NSString *relay = isRelay ? @"01" : @"00";
    slave2_mac = slave2_mac ?: @"00000000";
    NSData *data = [[head AppendFormat:@"%@%@%@%@",host_mac,slave_mac,relay,slave2_mac] dataByHexString];
    data = [[head AppendFormat:@"%@%@%@%@",host_mac,slave_mac,relay,slave2_mac] dataByHexString];
    
    data = [self replaceCRCForSwitch:data];
    
    return data;
}

+ (NSData*)makeSlaveActionData:(NSString*)host_mac slave:(NSString*)slave_mac onOpen:(BOOL)onOpen relay:(BOOL)isRelay index:(int)index slave2:(NSString *)slave2_mac
{
    NSString *head = onOpen ? A1 : A0;
    NSString *relay = isRelay ? @"01" : @"00";
    NSString *indexStr = [NSString format:@"%02X",index];
    slave2_mac = slave2_mac ?: @"00000000";
    NSData *data = [[head AppendFormat:@"%@%@%@%@%@",host_mac,slave_mac,relay,indexStr,slave2_mac] dataByHexString];
    
    data = [self replaceCRCForSwitch:data];
    
    return data;
}

//开关和插座通用组合
+ (NSString *)makeSwitchOrder:(NSString *)slave_mac relay:(BOOL)isRelay index:(int)index slave2:(NSString *)slave2_mac
{
    NSString *relay = isRelay ? @"01" : @"00";
    NSString *indexStr = [NSString format:@"%02X",index];
    slave_mac = slave_mac ?: @"00000000";
    slave2_mac = slave2_mac ?: @"00000000";
    NSString *result = [NSString format:@"%@%@%@%@",slave_mac,relay,indexStr,slave2_mac];
    return result;
}

//LED
+ (NSString *)makeLEDOrder:(NSString *)slave_mac slave2:(NSString *)slave2_mac
{
    slave_mac = slave_mac ?: @"000000000000";
    slave2_mac = slave2_mac ?: @"00000000";
    if (slave_mac.length < 6*2){
        slave_mac = [NSString stringWithFormat:@"%@",slave_mac];
    }
    NSString *result = [NSString format:@"%@%@",slave_mac,slave2_mac];
    return result;
}

//电动窗帘组合
+ (NSString *)makeCurtainOrder:(NSString *)slave_mac relay:(BOOL)isRelay index:(int)index slave2:(NSString *)slave2_mac action:(NSString *)action per:(CGFloat)per
{
    NSString *relay = isRelay ? @"01" : @"00";
    NSString *indexStr = [NSString format:@"%02X",index];
    slave_mac = slave_mac ?: @"00000000";
    slave2_mac = slave2_mac ?: @"00000000";
    int value = per*100;
    NSString *perStr = [NSString format:@"%02X",value];
    NSString *result = [NSString format:@"%@%@%@%@",slave_mac,relay,indexStr,slave2_mac];
    result = [NSString format:@"%@00%@%@",result,action,perStr];
    return result;
}

#pragma mark - -------构造升级主机指令前缀（不带校验）----------------
+ (NSData*)makeUpdateHostDataWithFix:(NSString*)host_mac
{
    NSData *data = [[NSString stringWithFormat:@"D0%@",host_mac] dataByHexString];
    return data;
}


#pragma mark - -------构造主机上传配置信息----------------
+ (NSData*)makeUploadConfig:(NSString*)ssid password:(NSString*)password serverip:(NSString*)serverip serverport:(UInt16)serverport
{
    BOOL isAuto = AutoType;
    NSString *IP = @"192.168.11.226";
    NSString *CMD_UploadConfig = [NSString stringWithFormat:@"Cmd=WIFIConfig\\%@\\%@\\auto\\%d\\%@\\255.255.255.0\\192.168.11.1\\114.114.114.114\\%@\\%d\\",ssid,password,isAuto,IP,serverip,serverport];
    
    NSData *buffer = [CMD_UploadConfig dataUsingEncoding:NSASCIIStringEncoding];
    
    return buffer;
}

+ (NSData *)makeOrder:(NSString *)order hostMac:(NSString *)host_mac slaveMac:(NSString *)slave_mac
{
    if (!order || !host_mac) {
        return nil;
    }
    
    slave_mac = slave_mac ?: @"00000000";
    NSData *data = [[NSString stringWithFormat:@"%@%@%@",order,host_mac,slave_mac] dataByHexString];
    return data;
}

+ (NSData *)makeOrder:(NSString *)order hostMac:(NSString *)host_mac slaveMac:(NSString *)slave_mac verify:(Enum_VerifyType)verify
{
    host_mac = host_mac ?: [Tools getHostMacID];
    NSData *data = [self makeOrder:order hostMac:host_mac slaveMac:slave_mac];
    if (verify == VerifyType_Switch) {
        data = [self replaceCRCForSwitch:data];
    }
    else if (verify == VerifyType_Infrared) {
        data = [self replaceCRCForInfrared:data];
    }
    
    return data;
}

//创建LED指令
+ (NSData *)makeLEDOrder:(NSString *)order hostMac:(NSString *)host_mac slaveMac:(NSString *)slave_mac verify:(Enum_VerifyType)verify typeString:(NSString *)typeString placeString:(NSString *)placeString LEDMac:(NSString *)LEDMacString
{
    host_mac = host_mac ?: [Tools getHostMacID];
    if (!placeString || [placeString isEqualToString:@""]){
        NSMutableString *string = [NSMutableString string];
        for (int i = 0; i<11; ++i) {
            [string appendString:@"00"];
        }
        placeString = [string copy];
    }
    
    slave_mac = slave_mac ?: @"00000000";
    
    //拼接完整的指令
    NSString *wholeString;
    
    if (LEDMacString){
        wholeString = [NSString stringWithFormat:@"%@%@%@%@%@%@",order,host_mac,slave_mac,typeString,LEDMacString,placeString];
    }else{
        wholeString = [NSString stringWithFormat:@"%@%@%@%@%@",order,host_mac,slave_mac,typeString,placeString];
    }
    
    if (!order || !host_mac) {
        return nil;
    }
    NSData *data = [wholeString dataByHexString];
    
    if (verify == VerifyType_Switch) {
        data = [self replaceCRCForSwitch:data];
    }
    else if (verify == VerifyType_Infrared) {
        data = [self replaceCRCForInfrared:data];
    }
    
    return data;
}

/*
 * 主要用于定时任务
 */
+ (NSString *)makeLEDCommandString:(NSString *)order hostMac:(NSString *)host_mac slaveMac:(NSString *)slave_mac verify:(Enum_VerifyType)verify typeString:(NSString *)typeString commandString:(NSString *)commandString LEDMac:(NSString *)LEDMacString
{
    host_mac = host_mac ?: [Tools getHostMacID];
    if (!commandString || [commandString isEqualToString:@""]){
        NSMutableString *string = [NSMutableString string];
        for (int i = 0; i<5; ++i) {
            [string appendString:@"00"];
        }
        commandString = [string copy];
    }
    
    slave_mac = slave_mac ?: @"00000000";
    
    //拼接完整的指令
    NSString *wholeString;
    
    if (LEDMacString){
        wholeString = [NSString stringWithFormat:@"%@%@%@%@%@%@000000",order,host_mac,slave_mac,typeString,LEDMacString,commandString];
    }else{
        wholeString = [NSString stringWithFormat:@"%@%@%@000000%@%@000000",order,host_mac,slave_mac,typeString,commandString];
    }
    
    if (!order || !host_mac) {
        return nil;
    }
    
    return wholeString;
}


/**
 LED的群控指令的拼接

 @param order 指令的开头标识
 @param host_mac 主机地址
 @param slave_mac 从机地址
 @param verify 操作类型
 @param typeString 指令的中间位标识
 @param commandString 控制指令
 @param LEDMacs LEDMac的deviceID数组
 @return 返回正确的指令数据 ， 后续用于发送
 */
+ (NSData *)makeLEDGroupControlCommandOrder:(NSString *)order
                                    hostMac:(NSString *)host_mac
                                   slaveMac:(NSString *)slave_mac
                                     verify:(Enum_VerifyType)verify
                                 typeString:(NSString *)typeString
                              commandString:(NSString *)commandString
                                    LEDMacs:(NSArray <NSString *> *)LEDMacs
                                   position:(NSString *)positionString
{
    host_mac = host_mac ?: [Tools getHostMacID];
    if (!commandString || [commandString isEqualToString:@""]){
        NSMutableString *string = [NSMutableString string];
        for (int i = 0; i<5; ++i) {
            [string appendString:@"00"];
        }
        commandString = [string copy];
    }
    
    slave_mac = slave_mac ?: @"00000000";
    
    //拼接完整的指令
    NSString *wholeString;
    
    if (LEDMacs && LEDMacs.count){
        
        wholeString = [NSString stringWithFormat:@"%@%@%@%@000000",order,host_mac,slave_mac,typeString];
        //接ledMac
        
        //拼接操作指令和补位
        wholeString = [NSString stringWithFormat:@"%@%@",wholeString,commandString];
        wholeString = [NSString stringWithFormat:@"%@%@",wholeString,positionString];//FFFFFFFF
        
    }else{
        return nil;
    }
    
    if (!order || !host_mac) {
        return nil;
    }
    NSData *data = [wholeString dataByHexString];
    
    if (verify == VerifyType_Switch) {
        data = [self replaceCRCForSwitch:data];
    }
    else if (verify == VerifyType_Infrared) {
        data = [self replaceCRCForInfrared:data];
    }
    return data;
}

//创建LED指令
+ (NSData *)makeLEDCommandOrder:(NSString *)order
                        hostMac:(NSString *)host_mac
                       slaveMac:(NSString *)slave_mac
                         verify:(Enum_VerifyType)verify
                     typeString:(NSString *)typeString
                  commandString:(NSString *)commandString
                         LEDMac:(NSString *)LEDMacString
{
    host_mac = host_mac ?: [Tools getHostMacID];
    if (!commandString || [commandString isEqualToString:@""]){
        NSMutableString *string = [NSMutableString string];
        for (int i = 0; i<5; ++i) {
            [string appendString:@"00"];
        }
        commandString = [string copy];
    }
    
    slave_mac = slave_mac ?: @"00000000";
    
    //拼接完整的指令
    NSString *wholeString;
    
    if (LEDMacString){
        wholeString = [NSString stringWithFormat:@"%@%@%@%@%@%@000000",order,host_mac,slave_mac,typeString,LEDMacString,commandString];
    }else{
        wholeString = [NSString stringWithFormat:@"%@%@%@000000%@%@000000",order,host_mac,slave_mac,typeString,commandString];
    }
    
    if (!order || !host_mac) {
        return nil;
    }
    NSData *data = [wholeString dataByHexString];
    
    if (verify == VerifyType_Switch) {
        data = [self replaceCRCForSwitch:data];
    }
    else if (verify == VerifyType_Infrared) {
        data = [self replaceCRCForInfrared:data];
    }
    
    return data;
}

#pragma mark - -------构造添加红外下发学习指令----------------
+ (NSData*)makeInfraredStudyData:(NSString*)host_mac
{
    NSData *data = [@"00000000" dataByHexString];
    NSData *value = [self makeInfraredOrder:A8 host:host_mac keys:data];
    return value;
}

#pragma mark - -------构造智能匹配下发指令----------------
+ (NSData*)makeSmartMatchData:(NSString*)host_mac
{
    NSData *data = [@"00000000" dataByHexString];
    NSData *value = [self makeInfraredOrder:A5 host:host_mac keys:data];
    return value;
}

#pragma mark - -------构造红外指令----------------
+ (NSData*)makeInfraredActionData:(NSString*)host_mac
{
    NSData *data = [@"00000000" dataByHexString];
    NSData *value = [self makeInfraredOrder:A9 host:host_mac keys:data];
    return value;
}

+ (NSData *)makeInfraredActionData:(NSString*)host_mac data:(NSData *)data
{
    NSData *value = [self makeInfraredOrder:A9 host:host_mac keys:data];
    return value;
}

#pragma mark - -------构造发送遥控组合指令----------------
+ (NSData*)makeJoinInfraredActionData:(NSString*)host_mac keys:(NSData *)keys
{
    NSData *value = [self makeInfraredOrder:DF host:host_mac keys:keys];
    return value;
}

+ (NSData *)makeInfraredOrder:(NSString *)order hostMac:(NSString *)host_mac
{
    NSData *data = [self makeOrder:order hostMac:host_mac slaveMac:@""];
    data = [self replaceCRCForInfrared:data];
    
    return data;
}

+ (NSData *)makeInfraredOrder:(NSString *)order
                         host:(NSString *)host_mac
                       keyStr:(NSString *)keyStr
{
    keyStr = keyStr ?: @"";
    NSData *keys = [keyStr dataByHexString];
    return [self makeInfraredOrder:order host:host_mac keys:keys];
}

+ (NSData *)makeInfraredOrder:(NSString *)order
                         host:(NSString *)host_mac
                         keys:(NSData *)keys
{
    if (!order || !host_mac || !keys) return nil;
    //数据结构 [TYPE][H1][H2][H3][H4][H5][H6][...DATA...]
    NSString *value = [NSString format:@"%@%@",order,host_mac];
    NSData *fix = [value dataByHexString];
    NSMutableData *result = [fix mutableCopy];
    [result appendData:keys];
    
    result.data = [self replaceCRCForInfrared:result];
    return result;
}

#pragma mark 构造指纹蓝牙门锁配置指令(失败返回nil)
+ (NSData*)makeDoorLockInstruction:(NSString*)frameType
                            hostID:(NSString*)hostID
                          deviceID:(NSString*)deviceID
                          safeCode:(NSString*)safeCode
                        extHexData:(NSString*)extHexData
{
    //数据结构 [Type][id3][id2][id1][id0][DKey2][DKey1][DKey0][TargetType][...EXT DATA...]
    if (!frameType || !hostID || !deviceID) return nil;
    NSMutableString *formatBuf = [NSMutableString new];
    [formatBuf appendString:frameType];
    [formatBuf appendString:hostID];
    [formatBuf appendString:deviceID];
    if (safeCode) {
        [formatBuf appendString:safeCode];
    }
    if (extHexData) {
        [formatBuf appendString:extHexData];
    }
    
    NSData *dataBuf = [formatBuf dataByHexString];
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    if (dataBuf.length < 18) {
        NSMutableData *padBuf = [NSMutableData new];
        [padBuf appendData:dataBuf];
        for (int i=0; i<18-dataBuf.length; i++) {
            [padBuf appendBytes:"\x00" length:1];
        }
        dataBuf = padBuf;
    }
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    dataBuf = [Tools replaceCRCForInfrared:dataBuf];
    
    return dataBuf;
}

#pragma mark 构造指纹蓝牙门锁配置指令(失败返回nil)
+ (NSData*)makeDoorLockConfigParm:(NSString*)frameType
                         deviceID:(NSString*)deviceID
                         safeCode:(NSString*)safeCode
                          hexType:(NSString*)hexType
                       extHexData:(NSString *)extHexData
{
    //数据结构 [Type][id3][id2][id1][id0][DKey2][DKey1][DKey0][TargetType][...EXT DATA...]
    if (!frameType || !safeCode || !deviceID) return nil;
    if (!hexType) {
        hexType = @"0";
    }
    NSMutableString *formatBuf = [NSMutableString new];
    [formatBuf appendString:frameType];
    [formatBuf appendString:deviceID];
    [formatBuf appendString:safeCode];
    [formatBuf appendString:hexType];
    if (extHexData) {
        [formatBuf appendString:extHexData];
    }
    
    NSData *dataBuf = [formatBuf dataByHexString];
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    if (dataBuf.length < 18) {
        NSMutableData *padBuf = [NSMutableData new];
        [padBuf appendData:dataBuf];
        for (int i=0; i<18-dataBuf.length; i++) {
            [padBuf appendBytes:"\x00" length:1];
        }
        dataBuf = padBuf;
    }
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    dataBuf = [Tools replaceCRCForInfrared:dataBuf];
    
    return dataBuf;
}

+ (NSData*)makeDoorLockConfigParm:(NSString*)frameType
                         deviceID:(NSString*)deviceID
                         safeCode:(NSString*)safeCode
                          hexType:(NSString*)hexType
                        userIndex:(NSInteger)userIndex
{
    //数据结构 [Type][id3][id2][id1][id0][DKey2][DKey1][DKey0][TargetType][...EXT DATA...]
    if (!frameType || !safeCode || !deviceID) return nil;
    if (!hexType) {
        hexType = @"0";
    }
    NSMutableString *formatBuf = [NSMutableString new];
    [formatBuf appendString:frameType];
    [formatBuf appendString:deviceID];
    [formatBuf appendString:safeCode];
    [formatBuf appendString:hexType];
    [formatBuf appendString:[NSString stringWithFormat:@"%02zd",userIndex]];
//    if (userIndex != -1){
//        [formatBuf appendString:[NSString stringWithFormat:@"%02zd",userIndex]];
//    }
    
    NSData *dataBuf = [formatBuf dataByHexString];
    
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    if (dataBuf.length < 20) {
        NSMutableData *padBuf = [NSMutableData new];
        [padBuf appendData:dataBuf];
        for (int i=0; i<18-dataBuf.length; i++) {
            [padBuf appendBytes:"\x00" length:1];
        }
        dataBuf = padBuf;
    }
    
//    if (userIndex != -1){
//        //不足18位右补0（加上校验码每包数据总共20字节）--------------------
//        if (dataBuf.length < 20) {
//            NSMutableData *padBuf = [NSMutableData new];
//            [padBuf appendData:dataBuf];
//            for (int i=0; i<18-dataBuf.length; i++) {
//                [padBuf appendBytes:"\x00" length:1];
//            }
//            dataBuf = padBuf;
//        }
//    }
    
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    dataBuf = [Tools replaceCRCForInfrared:dataBuf];
    
    return dataBuf;
}

+ (NSData *)makeDoorLockConfigParm:(NSString *)doorLockCP
                          deviceID:(NSString *)deviceID
                          passWord:(NSString *)passWord
                           hexType:(NSString *)type
                         userIndex:(NSString *)userIndex
                            userID:(NSString *)userID
                            action:(NSInteger)action
                               way:(NSInteger)way {
    
    if (!doorLockCP || !deviceID) return nil;
    if (!type) {
        type = @"00";
    }
    NSMutableString *formatBuf = [NSMutableString new];
    [formatBuf appendString:doorLockCP];
    [formatBuf appendString:deviceID];
    [formatBuf appendString:passWord];
    [formatBuf appendString:type];
    [formatBuf appendString:userIndex];
    [formatBuf appendString:userID];
    
//    if (!action || !way){
//        return nil;
//    }
    
    [formatBuf appendString:[NSString stringWithFormat:@"%02zd",action]];
    [formatBuf appendString:[NSString stringWithFormat:@"%02zd",way]];
    
    NSData *dataBuf = [formatBuf dataByHexString];
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    if (dataBuf.length < 18) {
        NSMutableData *padBuf = [NSMutableData new];
        [padBuf appendData:dataBuf];
        for (int i=0; i<18-dataBuf.length; i++) {
            [padBuf appendBytes:"\x00" length:1];
        }
        dataBuf = padBuf;
    }
    // AE 03 00 00 01  61 A5 20 06 00 0000005C 01 01 3C12
    // AE 23002020 1A50BB 06 00 0000005C 01 03 0000 9C24
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    dataBuf = [Tools replaceCRCForInfrared:dataBuf];
    
    return dataBuf;
}

//声音和常开
+ (NSData *)makeDoorLockConfigParm:(NSString *)doorLockCP
                          deviceID:(NSString *)deviceID
                          passWord:(NSString *)passWord
                           hexType:(NSString *)type
                         userIndex:(NSInteger)userIndex
                              flag:(NSInteger)flag {
    
    if (!doorLockCP || !deviceID) return nil;
    if (!type) {
        type = @"00";
    }
    NSMutableString *formatBuf = [NSMutableString new];
    [formatBuf appendString:doorLockCP];
    [formatBuf appendString:deviceID];
    [formatBuf appendString:passWord];
    [formatBuf appendString:type];
    [formatBuf appendString:[NSString stringWithFormat:@"%02zd",userIndex]];
    [formatBuf appendString:[NSString stringWithFormat:@"%02zd",flag]];
    
    NSData *dataBuf = [formatBuf dataByHexString];
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    if (dataBuf.length < 18) {
        NSMutableData *padBuf = [NSMutableData new];
        [padBuf appendData:dataBuf];
        for (int i=0; i<18-dataBuf.length; i++) {
            [padBuf appendBytes:"\x00" length:1];
        }
        dataBuf = padBuf;
    }
    // AE 03 00 00 01  61 A5 20 06 00 0000005C 01 01 3C12
    //不足18位右补0（加上校验码每包数据总共20字节）--------------------
    dataBuf = [Tools replaceCRCForInfrared:dataBuf];
    
    return dataBuf;
}

#pragma mark - -------获取当前WIFI SSID信息----------------
+ (NSString*)getCurrentWifiSSID
{
    NSString *ssid = [self.class getCurrentWifiInfo][(NSString *)kCNNetworkInfoKeySSID];
    return ssid;
}

+ (NSDictionary *)getCurrentWifiInfo
{
    NSDictionary *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();//获取支持的端口(比如笔记本电脑包含有线和无线2种接口的网络)
    //NSLog(@"Supported interfaces: %@", ifs);
    for (NSString *ifnam in ifs) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        //NSLog(@"dici：%@",[info  allKeys]);
        NSDictionary *info = myDict ? (NSDictionary *)CFBridgingRelease(myDict) : nil;
        if (info[(NSString *)kCNNetworkInfoKeySSID]) {
            //BSSID是WiFi的mac地址
            ssid = info;
            break;
        }
    }
    return ssid;
}

#pragma mark - -------获取门禁crc校验码----------------
+ (NSData*)getCRC:(NSMutableData*)dataBytes
{
    Byte sum = 0x00;
    Byte *bytes = (Byte *)[dataBytes bytes];
    NSUInteger length = dataBytes.length;
    for (int i = 0; i < length; i++) {
        //NSLog(@"sum = %hhu  bytes[i]  =  %hhu",sum , bytes[i]);
        sum += bytes[i];
    }
    
    Byte byte[] = {sum};
    return [NSData dataWithBytes:byte length:1];
}

+ (NSData *)getCRCWith:(NSArray *)listData
{
    NSMutableData *result = [NSMutableData data];
    for (NSData *data in listData) {
        [result appendData:data];
    }
    
    if (result.length > 0) {
        NSData *data = [self getCRC:result];
        return data;
    }
    
    return nil;
}

#pragma mark - -------组合门禁控制命令----------------
+ (NSString *)makeControl:(NSString *)control value:(NSString *)value
{
    NSString *result = [self makeControl:control dataLen:4 value:value];
    
    return result;
}

+ (NSString *)makeControl:(NSString *)control dataLen:(int)len value:(NSString *)value
{
    if (len != value.length/2) {
        [CTB showMsg:LocalizedSingle(@"InstructionError")];//创建指令有误
        return nil;
    }
    
    //长度值4个字节(8个字符长度)
    NSString *result = [control stringByAppendingFormat:@"%08x%@",len,value];
    if (len == 0) {
        result = [control stringByAppendingFormat:@"%08x",len];
    }
    
    return result;
}

#pragma mark - -------构造开门动作----------------
+ (NSData*)makeOpenDoorActionWithSN:(NSString*)SN parmsDoor:(NSString*)parmsDoor
{
    NSData *dataSign = [@"\x7e" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *dataSN = [SN dataUsingEncoding:NSASCIIStringEncoding];
    NSData *dataContent = [parmsDoor dataByHexString];
    
    // 检验码：除标志码和检验码，命令中所有字节都相加然后取尾子节。
    NSData *dataCRC = [Tools getCRCWith:@[dataSN,dataContent]];//检验码
    
    //输出拼接格式 SIGN, content, CRC, SIGN
    NSMutableData *result =[[NSMutableData alloc] init];
    [result appendData:dataSign];   //标志码
    [result appendData:dataSN];     //门序列号
    [result appendData:dataContent];//控制命令
    [result appendData:dataCRC];    //检验码
    [result appendData:dataSign];   //标志码
    
    return result;
}

+ (NSData *)makeDoorCommandWith:(NSString *)SN pwd:(NSString *)pwd msg:(NSString *)msg control:(NSString *)control
{
    NSData *dataSign = [@"\x7e" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *dataSN = [SN dataUsingEncoding:NSASCIIStringEncoding];
    
    if (SN.length <= 0) {
        SN = @"FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF";
        dataSN = [SN dataUsingEncoding:NSASCIIStringEncoding];
    }
    
    if (pwd.length < 8) {
        pwd = @"FFFFFFFF";
    }
    
    if (msg.length < 8) {
        msg = @"00000000";
    }
    
    if (control.length <= 0) {
        return nil;
    }
    
    NSString *parmsDoor = [NSString stringWithFormat:@"%@%@%@",pwd,msg,control];
    NSData *dataContent = [parmsDoor dataByHexString];
    
    // 检验码：除标志码和检验码，命令中所有字节都相加然后取尾子节。
    NSData *dataCRC = [Tools getCRCWith:@[dataSN,dataContent]];//检验码
    
    NSMutableData *data = [NSMutableData data];
    [data appendData:dataSN];       //门序列号
    [data appendData:dataContent];  //控制命令
    [data appendData:dataCRC];      //检验码
    data.data = [self.class translationData:data];//转译
    
    //输出拼接格式 SIGN, content, CRC, SIGN
    NSMutableData *result =[NSMutableData data];
    [result appendData:dataSign];   //标志码
    [result appendData:data];       //数据区
    [result appendData:dataSign];   //标志码
    
    return result;
}

//门禁发送数据中7E、7F部分进行转译
+ (NSData *)translationData:(NSData *)data1
{
    NSMutableData *data = [NSMutableData data];
    data.data = data1;
    NSData *rangeData = [NSData dataWithBytes:"\x7f" length:1];
    for (int i=0; i<data.length; i++) {
        NSData *tempData = [data subdataWithRange:NSMakeRange(i, 1)];
        NSString *nextDataStr = nil;
        if (i != data.length-1) {
            NSData *nextData = [data subdataWithRange:NSMakeRange(i+1, 1)];
            nextDataStr = [nextData hexString];
        }
        if ([tempData isEqualToData:rangeData] && ![nextDataStr isEqualToString:@"02"]) {
            NSString *tempStr = [data hexString];
            tempStr = [tempStr stringByReplacingCharactersInRange:NSMakeRange(i*2, 2) withString:@"7F02"];
            data.data = [tempStr dataByHexString];
            i++;
        }
    }
    
    rangeData = [NSData dataWithBytes:"\x7e" length:1];
    NSRange range = [data rangeOfData:rangeData options:NSDataSearchBackwards range:NSMakeRange(0, data.length)];
    while (range.location != NSNotFound) {
        NSString *dataStr = [data hexString];
        NSRange replaceRange = NSMakeRange(range.location*2, 2);
        dataStr = [dataStr stringByReplacingCharactersInRange:replaceRange withString:@"7F01"];
        data.data = [dataStr dataByHexString];
        
        range = [data rangeOfData:rangeData options:NSDataSearchBackwards range:NSMakeRange(0, data.length)];
    }
    
    return data;
}

//改IP和网关(门禁用)
+ (NSString *)makeControlWithIP:(NSString *)IP gateway:(NSString *)gateway
{
    IP = [IP getHex];
    gateway = [gateway getHex];
    if (!IP || !gateway) return nil;
    
    NSString *value = [NSString format:@"001806100004%@ffffff00%@0000000000000000021f401fa5233201020304007777772e313233343536373839302e636e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",IP,gateway];
    NSString *control = [Tools makeControl:@"010601" dataLen:137 value:value];
    return control;
}

#pragma mark 固件校验(失败返回nil)
+ (void)ValidCRCWithFirmware:(NSData *)data complete:(FirmwareBlock)block
{
    if (![data isKindOfClass:[NSData class]] || data.length < 10){
        block(nil, 0, 0, 0);
        return;
    }
    
    NSInteger length = data.length;
    Byte *Buf = (Byte *)[data bytes];
    //固件升级包开头结尾标志(FEEF...FEEF)
    if (Buf[0] != 0xFE || Buf[1] != 0xEF || Buf[length-2] != 0xFE || Buf[length-1] != 0xEF) {
        //如果任何一个对应错误，则返回空
        NSLog(@"固件开头结尾标志错误");
        block(nil, 0, 0, 0);
        return;
    }
    
    data = [data subdataWithRanges:NSMakeRange(2, length-4)];//信息数据区
    
    NSData *infoArea = [data subdataWithRanges:NSMakeRange(0, 4)];//信息区
    long type = [infoArea parseIntWithRange:NSMakeRange(0, 1)];
    long fileVer = [infoArea parseIntWithRange:NSMakeRange(1, 1)];
    float viewVer = [infoArea parseIntWithRange:NSMakeRange(2, 2)]/100.0f;
    CTBNSLog(@"固件类型:%ld,固件型号:[%ld],固件版本号:%.2f",type,fileVer,viewVer);
    
    BOOL result = [Tools ValidCRCWithHost:data];
    if (!result) {
        block(nil, 0, 0, 0);
        return;
    }
    data = [data subdataWithRanges:NSMakeRange(4, length-6)];//数据区(去掉信息区和校验)
    if (block) {
        block(data, (int)type, (int)fileVer, viewVer);
    }
}

#pragma mark - -------播放声音（系统级播放，不能超过30秒，适合播放声音素材）----------------
+ (void)createPlaySound:(NSString *)pathName ofType:(NSString *)type
{
    static SystemSoundID shake_sound_male_id = 0;
    NSString *path = [[NSBundle mainBundle] pathForResource:pathName ofType:type];
    if (path) {
        //注册声音到系统
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path],&shake_sound_male_id);
        AudioServicesPlaySystemSound(shake_sound_male_id);
    }
}

+ (void)createPlaySound:(NSString *)name ofType:(NSString *)type soundID:(SystemSoundID *)inSystemSoundID
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    if (path) {
        //注册声音到系统
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path],inSystemSoundID);
    }
}

+ (void)playSystemSound:(SystemSoundID)inSystemSoundID
{
    AudioServicesPlaySystemSound(inSystemSoundID);
}

//手机震动（系统默认，时间较长）
+ (void)VibrateDefault
{
    [Tools playSystemSound:kSystemSoundID_Vibrate];
    NSLog(@"--默认震动--");
}

//手机震动（微震带有声音）
+ (void)VibrateShort
{
    [Tools playSystemSound:1003];//SMSReceived
    NSLog(@"--微震--");
}

//手机震动（短震两下）
+ (void)VibrateDoubleShort
{
    [Tools playSystemSound:1011];//SMSReceived_Vibrate
    NSLog(@"--短震***");
}

//触模按键声
+ (void)KeyPressed
{
    [Tools playSystemSound:1103];//KeyPressed
    NSLog(@"--触模按键声--");
}


#pragma mark - -------获取状态栏尺寸----------------
+ (CGRect)getStatusBar
{
    return [[UIApplication sharedApplication] statusBarFrame];
}

+ (void)getEnumArray
{
    NSString *enumStr = @"SlaveType_None          = 0,"        //未知设备
    "Switch_Switch           = 1,"        //开关
    "Switch_Outlet           = 2,"        //插座
    "Switch_Lamp             = 3,"        //灯
    "Switch_ElectricFan      = 4,"        //电风扇
    "Switch_WaterDispenser   = 5,"        //饮水机
    "Switch_Sound            = 6,"        //音响
    "Switch_RiceCooker       = 7,"        //电饭锅
    "Switch_FogGlass         = 8,"        //雾化窗玻
    
    //红外设备类型（红外的二级枚举类型 移位 11~）
    "IrDA_None               = 100,"      //未知设备
    "IrDA_TV                 = 101,"      //电视机
    "IrDA_AC                 = 102,"      //空调
    "IrDA_STB                = 103,"      //机顶盒
    "IrDA_Fan                = 104,"      //风扇
    "IrDA_DVD                = 105,"      //DVD
    "IrDA_ACL                = 106,"      //空气净化器
    
    "IrDA_IPTV               = 150,"      //IPTV
    "IrDA_MiBox              = 151,"      //小米盒子
    "IrDA_LeTV               = 152,"      //乐视盒子
    
    "Switch_DoorLock         = 200,"      //木门锁(普通)
    "Switch_GateLock         = 201,"      //铁门锁(蓝牙)
    
    "SlaveType_DoorControl   = 300,"      //门禁
    
    "IrDACus_AC              = 1007,"     //自定义学习空调
    "IrDACus_TV              = 1008,"     //自定义学习电视
    "IrDACus_STB             = 1009,"     //自定义学习机顶盒
    "IrDACus_Fan             = 1010,"     //自定义学习风扇
    "IrDACus_DVD             = 1011,"     //自定义学习DVD
    "IrDACus_ACL             = 1012,"     //自定义学习空气净化器
    "IrDACus_IPTV            = 1013,";     //自定义学习网络电视";
    
    NSArray *list = [enumStr componentSeparatedByString:@","];
    NSMutableArray *listAll = [NSMutableArray array];
    for (NSString *value in list) {
        NSString *str = [value substringToIndex:value.length-8];
        str = [str replaceString:@" " withString:@""];
        [listAll addObject:str];
    }
    
    NSLog(@"%@",[listAll componentsJoinedByString:@"),@("]);
}

#pragma mark - -------是否为空字符----------------
+ (BOOL)isNullOrEmpty:(NSString *)str
{
    if (str == nil || str == NULL) {
        return YES;
    }
    if ([str isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

#pragma - ***********************************************************************************************
#pragma mark 拿取文件路径
+ (NSString *)getFilePath:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    if ([fileName hasSuffix:@".txt"]) {
        documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"documents"];
    }
    if ([fileName hasSuffix:@".png"]||[fileName hasSuffix:@".jpg"]||[fileName hasSuffix:@".gif"]) {
        documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"images"];
    }
    if ([fileName hasSuffix:@".amr"]||[fileName hasSuffix:@".wav"]) {
        documentsDirectory = [documentsDirectory stringByAppendingPathComponent:@"audio"];
    }
    [Tools PathExistsAtPath:documentsDirectory];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    return filePath;
}

+ (NSString *)getFilePath:(NSString *)fileName type:(NSString *)type
{
    if (![fileName hasSuffix:type]) {
        fileName = [fileName stringByAppendingFormat:@".%@",type];
    }
    
    return [Tools getFilePath:fileName];
}

+ (UIImage *)getImgWithName:(NSString *)imgName
{
    NSString *filePath = [Tools getFilePath:imgName];
    return [[UIImage alloc] initWithContentsOfFile:filePath];
}

#pragma mark - -------判断文件是否存在----------------
+ (BOOL)fileExist:(NSString *)fileName {
    
    if(!fileName || fileName == nil || [fileName length]<=0)
        return NO;
    
    NSString *filePath = [Tools getFilePath:fileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:filePath];
}

+ (BOOL)pathExist:(NSString *)path
{
    if(!path || [path length]<=0)
        return NO;
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path];
}

+ (void)PathExistsAtPath:(NSString *)Path
{
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:Path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:Path withIntermediateDirectories:YES attributes:Nil error:&error];
        if (error) {
            NSLog(@"路径创建失败:%@",error.localizedDescription);
        }
    }
}

+ (NSString *)getFileName:(NSString *)path
{
    return [path lastPathComponent];
}

+ (NSString *)getNameWithUrl:(NSString *)url
{
    if (url.length<=0) {
        return NULL;
    }
    NSString *name = [url lastPathComponent];
    return name;
}

#pragma mark - -------加载图片－本地文件----------------
+ (UIImage *)imageFromDocumentFileName:(NSString *)fileName
{
    
    if (!fileName) {
        return nil;
    }
    
    if (![Tools fileExist:fileName]) {
        return nil;
    }
    
    NSString *filePath = [Tools getFilePath:fileName];
    return [UIImage imageWithContentsOfFile:filePath];
}

#pragma mark - -------保存文件到本地----------------
+ (void)saveDataToFile:(NSData *)data fileName:(NSString *)fileName
{
    
    if(fileName == nil || [fileName length]<=0)
        return;
    
    NSString *filePath = [Tools getFilePath:fileName];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:filePath contents:data attributes:nil];
    
    [Tools addSkipBackupAttributeToItemAtFilePath:filePath];
}

#pragma mark - -------设置备份模式----------------
+ (BOOL)addSkipBackupAttributeToItemAtFilePath:(NSString *)filePath
{
    const char* charFilePath = [filePath fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(charFilePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

+ (void)addIndexDirectory:(NSString *)filePath
{
    //将路径写入指定目录文件
    NSString *Path = [CTB getUsersPath];
    Path = [Path stringByAppendingPathComponent:@"Documents/Caches/DBFile.txt"];
    if (![NSFileManager fileExistsAtPath:Path]) {
        [NSFileManager createFileAtPath:Path contents:nil attributes:nil];
    }
    
    if (![NSFileManager fileExistsAtPath:Path]) {
        return;
    }
    
    BOOL isDirectory = NO;
    [NSFileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!isDirectory) {
        filePath = [filePath stringByDeletingLastPathComponent];
    }
    
    NSString *content = [NSString readFile:Path encoding:NSUTF8StringEncoding];
    NSDictionary *dic = [content convertToDic];
    NSMutableDictionary *dicData = [dic mutableCopy];
    [dicData setObject:filePath forKey:@"iFace"];
    content = [dicData convertToString];
    [content writeToFile:Path encoding:NSUTF8StringEncoding];
}

#pragma mark - -------字符转日期----------------
+ (NSDate *)dateFromString:(NSString *)str withDateFormater:(NSString *)formater
{
    if (!formater) {
        formater = @"yyyy-MM-dd HH:mm:ss";
    }
    NSString *strDate = [str stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:(formater ? formater : @"yyyy-MM-dd HH:mm:ss")];
    return [dateFormatter dateFromString:strDate];
}

#pragma mark 日期转字符
+ (NSString *)dateToString:(NSDate *)date withDateFormater:(NSString *)formater
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:(formater ? formater : @"yyyy-MM-dd HH:mm:ss")];
    return [dateFormatter stringFromDate:date];
}

#pragma mark 日期计算
+ (NSDate *)AddYearsToDate:(NSDate *)date years:(int)years
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    
    [offsetComponents setYear:years];
    
    return [gregorian dateByAddingComponents:offsetComponents toDate:date options:0];
}

+ (NSDate *)AddMonthToDate:(NSDate *)date months:(int)months
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    
    [offsetComponents setMonth:months];
    
    return [gregorian dateByAddingComponents:offsetComponents toDate:date options:0];
}

+ (NSDate *)AddDayToDate:(NSDate *)date days:(int)days
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    
    [offsetComponents setDay:days];
    
    return [gregorian dateByAddingComponents:offsetComponents toDate:date options:0];
}

#pragma mark - -------日期比较----------------
+ (int)compareDate:(NSDate *)aDate and:(NSDate *)bDate
{
    NSDate * now = [NSDate date];
    NSTimeInterval aBetween = [aDate timeIntervalSinceDate:now];
    NSTimeInterval bBetween = [bDate timeIntervalSinceDate:now];
    
    if (aBetween > bBetween) {
        //大于(晚于)
        return 1;
    }
    else if (aBetween < bBetween) {
        //小于(早于)
        return -1;
    }else{
        //相等
        return 0;
    }
}

#pragma mark 获取星期几
+ (NSString *)getWeekDay:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:(NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal)
                                          fromDate:date];
    NSInteger weekday = [comps weekday]; // 星期几（注意，周日是“1”，周一是“2”。。。。）
    
    switch (weekday) {
        case 1:
            return LocalizedSingle(@"Sunday");//星期日
        case 2:
            return LocalizedSingle(@"Monday");//星期一
        case 3:
            return LocalizedSingle(@"Tuesday");//星期二
        case 4:
            return LocalizedSingle(@"Wednesday");//星期三
        case 5:
            return LocalizedSingle(@"Thursday");//星期四
        case 6:
            return LocalizedSingle(@"Friday");//星期五
        case 7:
            return LocalizedSingle(@"Saturday");//星期六
            
        default:
            return @"";
    }
}

#pragma mark - -------去掉校验----------------
+ (NSData *)deleteVerifyWith:(NSData *)data
{
    NSData *value = [data subdataWithRanges:NSMakeRange(0, data.length-2)];
    return value;
}

#pragma mark - -------开关的CRC校验----------------
//开关数据校验（iFace主从机通用）
+ (NSData *)replaceCRCForSwitch:(NSData *)buffer
{
    if (!buffer) {
        return nil;
    }
    NSMutableData *result = [[NSMutableData alloc] init];
    [result appendData:buffer];
    
    Byte crc1 = 0x00;
    Byte crc2 = 0x00;
    Byte *value = (Byte *)[buffer bytes];
    
    for (int i=0; i<buffer.length; i++) {
        crc1 += value[i] & 0xFF;
        crc2 ^= value[i] & 0xFF;
    }
    
    Byte crc[] = {crc1, crc2};
    [result appendBytes:crc length:sizeof(crc)];
    
    return result;
}

#pragma mark - -------摇控CRC校验----------------
//红外数据校验
+ (NSData*)replaceCRCForInfrared:(NSData *)buffer
{
    if (!buffer) {
        return nil;
    }
    NSMutableData *result = [[NSMutableData alloc] init];
    [result appendData:buffer];
    
    Byte crc1 = 0x00;
    Byte crc2 = 0x00;
    Byte *value = (Byte *)[buffer bytes];
    
    for (int i=0; i<buffer.length; i++) {
        crc1 += value[i] & 0xFF;
        crc2 ^= value[i] & 0xFF;
    }
    
    Byte crc[] = {crc1, crc2};
    [result appendBytes:crc length:sizeof(crc)];
    
    return result;
    
}

// 验证校验码是否正确
+ (BOOL)ValidCRCWithHost:(NSData *)data
{
    if (!data)
        return NO;
    
    Byte crc1 = 0x00;
    Byte crc2 = 0x00;
    Byte *Buf = (Byte *)[data bytes];
    NSInteger length = data.length;
    for (int i = 0; i < length - 2; i++)
    {
        crc1 += Buf[i] & 0xFF;
        crc2 ^= Buf[i] & 0xFF;
    }
    
    Byte mCrc1 = Buf[length - 2];
    Byte mCrc2 = Buf[length - 1];
    
    return (crc1 == mCrc1) && (crc2 == mCrc2);
}

@end

#pragma mark - --------NSString------------------------
@implementation NSString (Extend)

#pragma mark 十六进制字符转data
- (NSData *)dataWithHexString
{
    NSString *str = [self stringByReplacingOccurrencesOfString:@" " withString:@""];
    char const *myBuffer = str.UTF8String;
    NSInteger charCount = strlen(myBuffer);
    if (charCount %2 != 0) {
        return nil;
    }
    NSInteger byteCount = charCount/2;
    uint8_t *bytes = malloc(byteCount);
    for (int i=0; i<byteCount; i++) {
        unsigned int value;
        sscanf(myBuffer + i*2, "%2x",&value);
        bytes[i] = value;
    }
    NSData *data = [NSData dataWithBytes:bytes length:byteCount];
    return data;
}

@end

@implementation NSData (Extend)
#pragma mark NSData bytes转换成十六进制字符串
- (NSString *)toHexString
{
    NSString *dataStr = self.description;
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@"<" withString:@""];//去掉'<'
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@">" withString:@""];//去掉'>'
    dataStr = [dataStr stringByReplacingOccurrencesOfString:@" " withString:@""];//去掉空格
    dataStr = [dataStr uppercaseString];//转为大写
    
    return dataStr;
}

- (NSData *)subdataWithRanges:(NSRange)range
{
    if (range.length > UINT_MAX) {
        return nil;
    }
    else if (NSMaxRange(range) <= self.length) {
        return [self subdataWithRange:range];
    }
    else if (self.length < range.location) {
        return nil;
    }
    
    NSInteger length = self.length - range.location;
    range.length = length;
    return [self subdataWithRange:range];
}

//十六进制转化成十进制
- (long)parseIntWithRange:(NSRange)range
{
    long value = 0;
    NSData *data = [self subdataWithRanges:range];
    NSString *str = [data toHexString];
    value = strtol([str UTF8String],nil,16);
    //[self getBytes:&value range:NSMakeRange(0, data.length)];
    return value;
}

@end
