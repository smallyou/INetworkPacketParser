//
//  IPTCPSegment.m
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//

#ifndef __IPTCPSegment_Header_
#define __IPTCPSegment_Header_

#define kTCPHeaderSize 20

#include <netinet/tcp.h>

#import "IPTCPSegment.h"
#import "IPConstant.h"

#endif

@interface IPTCPSegment ()

@property (nonatomic, strong) NSData *rawData;
@property (nonatomic, strong) IPTCPHeader *header;
@property (nonatomic, strong) NSData *payload;

@end

@implementation IPTCPSegment

- (instancetype)initWithRawData:(NSData *)rawData {
    if (self = [super init]) {
        self.rawData = rawData;
        
        NSError *error = nil;
        BOOL flag = [self parse:&error];
        if (!flag) {
            NSLog(@"parse tcp segment error %@", error);
        }
    }
    return self;
}

- (BOOL)parse:(NSError **)error {
    NSData *data = self.rawData;
    const Byte *bytes = (Byte *)data.bytes;
    if (data == nil || bytes == '\0') {
        NSError *err = [NSError errorWithDomain:IPErrorDomainName code:IPErrorCodeFormatError userInfo:@{NSLocalizedDescriptionKey:@"UDP rawdata is not exist"}];
        *error = err;
        return NO;
    }
    
    if (data.length < kTCPHeaderSize) {
        NSError *err = [NSError errorWithDomain:IPErrorDomainName code:IPErrorCodeFormatError userInfo:@{NSLocalizedDescriptionKey:@"UDP rawdata length is less than 20 bytes"}];
        *error = err;
        return NO;
    }
    
    struct tcphdr header;
    memcpy(&header, bytes, kTCPHeaderSize);
    NSInteger sourcePort = ntohs(header.th_sport);
    NSInteger destPort = ntohs(header.th_dport);
    
    IPTCPHeader *tcpHeadr = [[IPTCPHeader alloc] init];
    tcpHeadr.sourcePort = sourcePort;
    tcpHeadr.destPort   = destPort;
    tcpHeadr.seqNumber  = NTOHL(header.th_seq);
    tcpHeadr.ackNumber  = NTOHL(header.th_ack);
    tcpHeadr.dataOffset = ntohs(header.th_off);
    tcpHeadr.CWR        = header.th_flags & TH_CWR;
    tcpHeadr.FIN        = header.th_flags & TH_FIN;
    tcpHeadr.SYN        = header.th_flags & TH_SYN;
    tcpHeadr.RST        = header.th_flags & TH_RST;
    tcpHeadr.PSH        = header.th_flags & TH_PUSH;
    tcpHeadr.ACK        = header.th_flags & TH_ACK;
    tcpHeadr.URG        = header.th_flags & TH_URG;
    tcpHeadr.ECE        = header.th_flags & TH_ECE;
    
    // payload
    UInt8 offset = kTCPHeaderSize;
    bytes+=offset;
    NSInteger length = tcpHeadr.dataOffset - offset;
    NSData *payload = [NSData dataWithBytes:bytes length:length];
    
    self.header = tcpHeadr;
    self.payload = payload;
    
    return YES;
}

// todo
- (NSData *)toRawData {
    return nil;
}

@end

@implementation IPTCPHeader

@end
