//
//  IPTCPSegment.h
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPTCPHeader: NSObject

/**
 port number
 */
@property (nonatomic, assign) NSInteger sourcePort;
@property (nonatomic, assign) NSInteger destPort;

@property (nonatomic, assign) NSInteger seqNumber;
@property (nonatomic, assign) NSInteger ackNumber;


/**
 Specifies the size of the TCP header in byte
 */
@property (nonatomic, assign) NSInteger dataOffset;


/**
 unused
 */
@property (nonatomic, assign) NSInteger reserved;
@property (nonatomic, assign) BOOL NS;

/**
 flags
 */
@property (nonatomic, assign) BOOL CWR;
@property (nonatomic, assign) BOOL ECE;
@property (nonatomic, assign) BOOL URG;
@property (nonatomic, assign) BOOL ACK;
@property (nonatomic, assign) BOOL PSH;
@property (nonatomic, assign) BOOL RST;
@property (nonatomic, assign) BOOL SYN;
@property (nonatomic, assign) BOOL FIN;

@property (nonatomic, assign) NSInteger windowSize;
@property (nonatomic, assign) NSInteger checksum;
@property (nonatomic, assign) NSInteger urgentPointer;

@end

@interface IPTCPSegment : NSObject

@property (nonatomic, strong, readonly) IPTCPHeader *header;
@property (nonatomic, strong, readonly) NSData *payload;

- (instancetype)initWithRawData:(NSData *)rawData;
- (NSData *)toRawData;

@end

NS_ASSUME_NONNULL_END
