# INetworkPacketParser

[![CI Status](https://img.shields.io/travis/smallyou/INetworkPacketParser.svg?style=flat)](https://travis-ci.org/smallyou/INetworkPacketParser)
[![Version](https://img.shields.io/cocoapods/v/INetworkPacketParser.svg?style=flat)](https://cocoapods.org/pods/INetworkPacketParser)
[![License](https://img.shields.io/cocoapods/l/INetworkPacketParser.svg?style=flat)](https://cocoapods.org/pods/INetworkPacketParser)
[![Platform](https://img.shields.io/cocoapods/p/INetworkPacketParser.svg?style=flat)](https://cocoapods.org/pods/INetworkPacketParser)

`INetworkPacketParser`是一个轻量级的面向对象的`TCP/IP`协议栈解析工具。

## 简介

`INetworkPacketParser`是一个轻量级的面向对象的`TCP/IP`协议栈解析工具。


#### 数据包解析（Wire data 解析成 OC对象）

> 支持从网络传输的二进制数据转换成OC对象`

* 网络层协议解析：支持`IP Packet` 数据包解析
* 传输层协议解析：支持`TCP/UDP/ICMP`数据段解析
* 应用层协议解析：`DNS`报文解析（包括请求和响应报文）

#### 数据包构造（OC对象 转换成 Wire Data）

> 支持将OC对象属性修改，并转换成可网络直接传输的二进制数据

* 网络层协议构造: 支持`IP Packet`报文构造及篡改
* 传输层协议构造: 支持`TCP/UDP`的数据段构造及篡改
* 应用层协议构造: 暂不支持

#### 更新计划
- [x] IP数据包解析及构造
- [x] TCP/UDP数据段解析
- [x] DNS报文解析
- [ ] TCP/UDP数据段构造
- [ ] DNS 请求报文构造
- [ ] DNS 响应报文构造
- [ ] 其他应用层报文支持


## 依赖

#### 系统版本

* iOS ~> 9.0
* MacOS ~> 10.0

#### 库依赖

* 系统库: `resolv.lib`（CocoaPods自动安装）

## 安装

支持cocoapods安装

```ruby
pod 'INetworkPacketParser'
```

## 示例

```
- (void)test {
	// 网络二进制报文
	NSString *hex = @"4500003c 734f0000 ff114f69 0a0a0a0a 72727272 cd240035 00284c24 63780100 00010000 00000000 03777777 0669636c 6f756403 636f6d00 00010001";
	NSData *rawData = [self dataFromHexString:hex];
	
	// IP数据包解析
	IPPacket *packet = [[IPPacket alloc] initWithRawData:rawData];
	if (packet.header.transportProtocol == UDP) {
        // UDP解析
        IPUDPSegment *udpSegment = [[IPUDPSegment alloc] initWithRawData:packet.payload];
        if (udpSegment.header.destPort == 53) {
            // DNS解析
            IPDNSMessage *dnsMessage = [[IPDNSMessage alloc] initWithRawData:udpSegment.payload];
            dnsMessage.dnsHeader;
            dnsMessage.dnsQuery;
            dnsMessage.dnsAnswers;
        }
    }else if (packet.header.transportProtocol == TCP) {
        // TCP解析
        IPTCPSegment *tcpSegment = [[IPTCPSegment alloc] initWithRawData:packet.payload];
    }
	
}
```
## Author

smallyou, smallyou@126.com

Github: <a href="https://github.com/smallyou/SBWatcher">smallyou</a>  |  简书: <a href="http://www.jianshu.com/u/ebb60643b57c">一月二十三</a>
