//
//  IPDNSMessage.h
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//

#import <Foundation/Foundation.h>
@class IPDNSHeader;
@class IPDNSQuery;
@class IPDNSAnswer;

NS_ASSUME_NONNULL_BEGIN

@interface IPDNSMessage : NSObject

/**
 The dns query/reply header
 */
@property (nonatomic, strong, readonly) IPDNSHeader *dnsHeader;

/**
 The dns query requestion
 */
@property (nonatomic, strong, readonly) IPDNSQuery *dnsQuery;

/**
 The dns answers which carraied by replay message.If the message type is query, the answers is nil.
 */
@property (nonatomic, strong, readonly, nullable) NSArray<IPDNSAnswer *> *dnsAnswers;

- (instancetype)initWithRawData:(NSData *)rawData;

/**
 Update DNS message, you can construct the dns message

 @param header dnsHeader
 */
- (void)updateHeader:(IPDNSHeader *)header;
- (void)updateQuery:(IPDNSQuery *)dnsQuery;
- (void)addAnswer:(IPDNSAnswer *)answer;


/**
 Get raw data which include header,query and answers

 @return rawData
 */
//- (NSData *)toRawData;


#pragma mark - Test
- (NSData *)compressName:(NSString *)domainName;


@end

NS_ASSUME_NONNULL_END
