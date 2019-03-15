//
//  IPViewController.m
//  INetworkPacketParser
//
//  Created by smallyou on 03/12/2019.
//  Copyright (c) 2019 smallyou. All rights reserved.
//

#import "IPViewController.h"
#import "IPPacket.h"
#import "IPUDPSegment.h"
#import "IPTCPSegment.h"
#import "IPDNSMessage.h"

@interface IPViewController ()

@end

@implementation IPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)parseIPPacket:(id)sender {
    
    NSData *rawData = [self testIPRawData];
    IPPacket *packet = [self packetWithRawData:rawData];
    NSLog(@"---> %@", packet);
}

- (IBAction)parseUDPSegment:(id)sender {
    
    NSData *ipRawData = [self testIPRawData];
    IPUDPSegment *segment = [self udpSegmentWithRawData:ipRawData];
    NSLog(@"---> %@", segment);
    
}

- (IBAction)parseTCPSegment:(id)sender {
    
    NSString *hex = @"4500004c0000400040060b9a0a0a0a0a11fa0905de9301bb588fe00800000000e002ffff14b4000002040550010303061e0c110316f1f1e8a9ba27c60101080a33ae6d8e0000000004020000";
    NSData *ipRawData = [self dataFromHexString:hex];
    IPTCPSegment *segment = [self tcpSegmentWithRawData:ipRawData];
    
    NSLog(@"");
    
}

- (IBAction)parseDNSMessage:(id)sender {
//    NSString *hex = @"4500003cb37e0000ff110f3a0a0a0a0a72727272d73c00350028115e942601000001000000000000037777770669636c6f756403636f6d0000010001";
    NSString *hex = @"0a4381800001000d000000000d75706c6f61642d696d61676573076a69616e73687502696f0000010001c00c000500010000000f0023063764396b683302763203636f6d027a3003676c620871696e6975646e7303636f6d00c036000500010000000f001b0474696e79056368696e610571696e69750771696e6763646ec054c0650005000100000124000b067a716e7765620176c076c08c000100010000000000040e114015c08c00010001000000000004790c6287c08c00010001000000000004790c628ac08c0001000100000000000471608b1ec08c000100010000000000040e11400dc08c000100010000000000040e114013c08c0001000100000000000471608b1cc08c0001000100000000000471608b21c08c00010001000000000004790c6285c08c000100010000000000040e11400f";
    
    NSData *dnsRawData = [self dataFromHexString:hex];;
    IPDNSMessage *message = [[IPDNSMessage alloc] initWithRawData:dnsRawData];
//    NSData *data = message.toRawData;
//    NSLog(@"");
    
//    [message compressName:@"abc.efg.22222.sd."];
    NSLog(@"");
    
}



- (NSData *)testIPRawData {
    NSString *hex = @"4500003c 734f0000 ff114f69 0a0a0a0a 72727272 cd240035 00284c24 63780100 00010000 00000000 03777777 0669636c 6f756403 636f6d00 00010001";
    hex = [hex stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSData *rawData = [self dataFromHexString:hex];
    
    return rawData;
}

- (IPPacket *)packetWithRawData:(NSData *)rawData {
    IPPacket *packet = [[IPPacket alloc] initWithRawData:rawData];
    return packet;
}

- (IPUDPSegment *)udpSegmentWithRawData:(NSData *)rawData {
    // 解析IP packet
    IPPacket *packet = [[IPPacket alloc] initWithRawData:rawData];
    
    // ip packet的payload作为UDP的rawData解析
    IPUDPSegment *segment = [[IPUDPSegment alloc] initWithRawData:packet.payload];

    return segment;
}

- (IPTCPSegment *)tcpSegmentWithRawData:(NSData *)rawData {
    // 解析IP packet
    IPPacket *packet = [[IPPacket alloc] initWithRawData:rawData];
    
    // ip packet的payload作为TCP的rawData解析
    IPTCPSegment *segment = [[IPTCPSegment alloc] initWithRawData:packet.payload];
    
    return segment;
}


- (NSData *)dataFromHexString:(NSString *)str {
    const char *chars = [str UTF8String];
    NSInteger i = 0, len = str.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}


@end
