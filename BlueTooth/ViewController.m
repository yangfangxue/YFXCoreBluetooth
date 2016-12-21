//
//  ViewController.m
//  BlueTooth
//
//  Created by fangxue on 16/12/21.
//  Copyright (c) 2016年 fangxue. All rights reserved.
//

#import "ViewController.h"
//外设名称
#define MyDeviceName @"<X-CAM SIGHT2S>"

@interface ViewController ()

@property (nonatomic, strong) CBCentralManager *centralMgr;//蓝牙设备管理对象
@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;//外设
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;//周边设备服务特性
@property (weak, nonatomic) IBOutlet UITextField *editText;
@property (weak, nonatomic) IBOutlet UILabel *resultText;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    //初始化设备管理对象
    self.centralMgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}
#pragma mark ==========================蓝牙相关代理==================================
#pragma mark =====打开手机蓝牙、开始扫描周围的蓝牙外设=====
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn://打开蓝牙
            //第一个参数为CBUUID的数组，需要搜索特点服务的蓝牙设备，只要每搜索到一个符合条件的蓝牙设备都会调用didDiscoverPeripheral代理方法
            [self.centralMgr scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}
#pragma mark =====扫描到设备=====
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    /*
     待优化
     */
    //找到需要的蓝牙设备，停止搜素，保存数据
    if([peripheral.name isEqualToString:@"<X-CAM SIGHT2S>"]){
        _discoveredPeripheral = peripheral;
        //连接外设
        [_centralMgr connectPeripheral:peripheral options:nil];
    }
}
//连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接到名称为%@的设备-成功",peripheral.name);
    
    //设置设备代理
    [_discoveredPeripheral setDelegate:self];
    //开启搜索服务,回调didDiscoverServices
    [_discoveredPeripheral discoverServices:nil];
}
//连接失败，就会得到回调：
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //此时连接发生错误
    NSLog(@"外设连接断开连接 %@:%@\n", [peripheral name], [error localizedDescription]);
}
//获取服务后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    
    NSLog(@"扫描到设备所有的服务：%@",peripheral.services);
    
    if (error)
    {
        NSLog(@"didDiscoverServices: %@", [error localizedDescription]);
        return;
    }
    
    for (CBService *s in peripheral.services)
    {
        NSLog(@"Service found with UUID : %@", s.UUID);
        //发现所有的服务,回调didDiscoverCharacteristicsForService
        /*
         待优化
         */
        //监听蓝牙外设服务
        [s.peripheral discoverCharacteristics:nil forService:s];
    }
}
//获取特征后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"didDiscoverCharacteristicsForService error : %@", [error localizedDescription]);
        return;
    }
    for (CBCharacteristic *c in service.characteristics)
    {
        NSLog(@"c.properties:%lu",(unsigned long)c.properties);
        
        //监听特征值的变化
        [peripheral setNotifyValue:YES forCharacteristic:c];
        //阅读特征的值 回调didUpdateValueForCharacteristic
        [peripheral readValueForCharacteristic:c];
        //保存characteristic特征值对象
        _writeCharacteristic = c;
    }
    
}
//订阅的特征值有新的数据时回调
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@",
              [error localizedDescription]);
    }
    
    [peripheral readValueForCharacteristic:characteristic];

}
// 获取到特征的值时回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"didUpdateValueForCharacteristic error : %@", error.localizedDescription);
        return;
    }
    
    NSData *data = characteristic.value;
    
    _resultText.text = [[ NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@",_resultText.text);
}
#pragma mark 发送按钮点击事件
- (IBAction)sendClick:(id)sender {
    // 字符串转Data
    NSData *data =[_editText.text dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"%@",data);

    [self writeChar:data];
}
#pragma mark 写数据
-(void)writeChar:(NSData *)data
{   
    //回调didWriteValueForCharacteristic
    [_discoveredPeripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
}
#pragma mark 写数据后回调
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        
        NSLog(@"Error writing characteristic value: %@",
              [error localizedDescription]);
        return;
    }
    NSLog(@"写入%@成功",characteristic);
}



@end
