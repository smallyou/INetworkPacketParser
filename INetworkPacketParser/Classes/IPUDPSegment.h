//
//  IPUDPSegment.h
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPUDPHeader : NSObject

@property (nonatomic, assign) NSInteger sourcePort;
@property (nonatomic, assign) NSInteger destPort;
@property (nonatomic, assign) NSInteger length; // 总长度(header + data)
@property (nonatomic, assign) NSInteger checksum;

@end

@interface IPUDPSegment : NSObject

@property (nonatomic, strong, readonly) IPUDPHeader *header;
@property (nonatomic, strong, readonly) NSData *payload;

- (instancetype)initWithRawData:(NSData *)rawData;
- (NSData *)toRawData;

@end

NS_ASSUME_NONNULL_END
