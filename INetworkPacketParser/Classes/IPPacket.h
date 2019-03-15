//
//  IPPacket.h
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, IPVersion) {
    iPv4 = 4,
    iPv6 = 6
};

typedef NS_ENUM(UInt8, TransportProtocol) {
    ICMP = 1,
    TCP  = 6,
    UDP  = 17
};

NS_ASSUME_NONNULL_BEGIN

@interface IPHeader : NSObject

@property (nonatomic,assign) IPVersion version;
@property (nonatomic,assign) UInt8 headerLength;    // 单位字节
@property (nonatomic,assign) UInt8 tos;
@property (nonatomic,assign) UInt16 totalLength;
@property (nonatomic,assign) UInt16 identification;
@property (nonatomic,assign) UInt16 offset;
@property (nonatomic,assign) UInt8 TTL;
@property (nonatomic,copy)   NSString *sourceAddress;
@property (nonatomic,copy)   NSString *destinationAddress;
@property (nonatomic,assign) TransportProtocol transportProtocol;

@end

@interface IPPacket : NSObject

@property (nonatomic, strong, readonly) IPHeader *header;
@property (nonatomic, strong, readonly) NSData   *payload;

- (instancetype)initWithRawData:(NSData *)rawData;
- (NSData *)toRawData;

@end

NS_ASSUME_NONNULL_END
