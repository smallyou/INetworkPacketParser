//
//  IPUDPSegment.m
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//

#ifndef __IPUDPSegment_Header_
#define __IPUDPSegment_Header_

#define kUDPHeaderSize 8

#include <netinet/udp.h>

#import "IPUDPSegment.h"
#import "IPConstant.h"

#endif

@interface IPUDPSegment ()

@property (nonatomic, strong) NSData *rawData;
@property (nonatomic, strong) IPUDPHeader *header;
@property (nonatomic, strong) NSData *payload;

@end

@implementation IPUDPSegment

- (instancetype)initWithRawData:(NSData *)rawData {
    if (self = [super init]) {
        self.rawData = rawData;
        
        // auto parse
        NSError *error = nil;
        BOOL flag = [self parse:&error];
        if (!flag) {
            NSLog(@"UDP segment parse error: %@", error);
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
    
    if (data.length < kUDPHeaderSize) {
        NSError *err = [NSError errorWithDomain:IPErrorDomainName code:IPErrorCodeFormatError userInfo:@{NSLocalizedDescriptionKey:@"UDP rawdata length is less than 8 bytes"}];
        *error = err;
        return NO;
    }
    
    // parse header
    struct udphdr header;
    memcpy(&header, bytes, kUDPHeaderSize);
    
    NSInteger sourcePort = ntohs(header.uh_sport);
    NSInteger destPort   = ntohs(header.uh_dport);
    
    IPUDPHeader *udpHeader = [[IPUDPHeader alloc] init];
    udpHeader.sourcePort = sourcePort;
    udpHeader.destPort   = destPort;
    udpHeader.length     = ntohs(header.uh_ulen);
    udpHeader.checksum   = ntohs(header.uh_sum);
    
    // parse payload
    UInt8 offset = kUDPHeaderSize;
    bytes+=offset;
    NSInteger length = udpHeader.length - offset;
    NSData *payload = [NSData dataWithBytes:bytes length:length];
    
    // assign
    self.header  = udpHeader;
    self.payload = payload;
    
    return YES;
}

// todo
- (NSData *)toRawData {
    return nil;
}

@end


@implementation IPUDPHeader


@end
