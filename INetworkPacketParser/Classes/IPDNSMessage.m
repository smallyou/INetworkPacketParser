//
//  IPDNSMessage.m
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//

#ifndef __IPDNSMessage_Header_
#define __IPDNSMessage_Header_
#include <dns.h>
#include <dns_util.h>
#include <nameser.h>
#include "IPDNSUtil.h"

#define DNSHeaderQR(val) (val & 0x8000) >> 15
#define DNSHeaderOP(val) (val & 0x7800) >> 11
#define DNSHeaderAA(val) (val & 0x0400) >> 10
#define DNSHeaderTC(val) (val & 0x0200) >> 9
#define DNSHeaderRD(val) (val & 0x0100) >> 8
#define DNSHeaderRA(val) (val & 0x0080) >> 7
#define DNSHeaderZ(val)  (val & 0x0040) >> 6
#define DNSHeaderAD(val) (val & 0x0020) >> 5
#define DNSHeaderCD(val) (val & 0x0010) >> 4
#define DNSHeaderRC(val) (val & 0x000F)

#endif

#import "IPDNSMessage.h"
#import "IPDNSProtocol.h"
#import "IPConstant.h"

typedef NS_ENUM(NSInteger, IPDNSSection) {
    IPDNSSectionHeader,
    IPDNSSectionQuery,
    IPDNSSectionAnswer
};

@interface IPDNSMessage ()

@property (nonatomic, strong) NSData *rawData;
@property (nonatomic, strong) IPDNSHeader *dnsHeader;
@property (nonatomic, strong) IPDNSQuery *dnsQuery;
@property (nonatomic, strong, nullable) NSArray<IPDNSAnswer *> *dnsAnswers;

@property (nonatomic, strong) NSDictionary *offsetOfDomainLabels;

@end

@implementation IPDNSMessage

- (instancetype)initWithRawData:(NSData *)rawData {
    if (self = [super init]) {
        self.rawData = rawData;
        
        NSError *error = nil;
        BOOL flag = [self parse:&error];
        if (!flag) {
            NSLog(@"DNS message parse error: %@", error);
        }
    }
    return self;
}

#pragma mark - API
- (void)updateHeader:(IPDNSHeader *)header {
    self.dnsHeader = header;
}

- (void)updateQuery:(IPDNSQuery *)dnsQuery {
    self.dnsQuery = dnsQuery;
}

- (void)addAnswer:(IPDNSAnswer *)answer {
    NSMutableArray *arrayM = [NSMutableArray arrayWithArray:self.dnsAnswers];
    [arrayM addObject:answer];
    self.dnsAnswers = [NSArray arrayWithArray:arrayM];
}

- (NSData *)toRawData {
    NSMutableData *dataM = [NSMutableData data];
    
    // append header raw data
    [self _appendRawData:&dataM withHeader:self.dnsHeader];
    
    // append query raw data
    [self _appendRawData:&dataM withQuery:self.dnsQuery];
    
    // append answers raw data
    [self _appendRawData:&dataM withAnswers:self.dnsAnswers];
    
    NSData *data = [NSData dataWithData:dataM];
    return data;
}

#pragma mark - Raw Data
- (void)_appendRawData:(NSMutableData **)rawData withHeader:(IPDNSHeader *)dnsHeader {
    
    if (dnsHeader == nil) {
        return ;
    }
    
    uint16_t xid = (uint16_t)htons(dnsHeader.xid);
    
    // flag
    uint16_t flag = 0x0000;
    flag = flag | (dnsHeader.qrType << 15);
    flag = flag | (dnsHeader.opType << 11);
    flag = flag | (dnsHeader.authoritativeAnswer << 10);
    flag = flag | (dnsHeader.truncation << 9);
    flag = flag | (dnsHeader.recursionDesired << 8);
    flag = flag | (dnsHeader.recursionAvailable << 7);
    flag = flag | (dnsHeader.reservedZone << 6);
    flag = flag | (dnsHeader.responseCodeType);
    flag = htons(flag);
    
    // others
    uint16_t qdcount = (uint16_t)htons(dnsHeader.questionCount);
    uint16_t ancount = (uint16_t)htons(dnsHeader.answerRecordCount);
    uint16_t nscount = (uint16_t)htons(dnsHeader.authorityRecordCount);
    uint16_t arcount = (uint16_t)htons(dnsHeader.additionalRecordCount);
    
    // construct
    dns_header_t *header = (dns_header_t *)malloc(sizeof(dns_header_t) + 1);
    memset(header, 0, sizeof(dns_header_t) + 1);
    header->xid = xid;
    header->flags = flag;
    header->qdcount = qdcount;
    header->ancount = ancount;
    header->nscount = nscount;
    header->arcount = arcount;
    
    NSData *data = [NSData dataWithBytes:header length:sizeof(dns_header_t)];
    
    if (data) {
        [*rawData appendData:data];
    }
}

- (void)_appendRawData:(NSMutableData **)rawData withQuery:(IPDNSQuery *)dnsQuery {
    
    if (dnsQuery == nil) {
        return ;
    }
    
    // check domain name format
    NSString *pattern = @"[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+.?";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    if (![predicate evaluateWithObject:dnsQuery.domainName]) {
        return ;
    }
    
    // domain: www.baidu.com => \x03www\x05baidu\x03com
    uint8_t *domain_label = NULL;
    uint8_t length = compress_domain([dnsQuery.domainName UTF8String], dnsQuery.domainName.length, &domain_label);
    
    // type
    uint16_t dnstype = htons(dnsQuery.dnsType);
    
    // class
    uint16_t dnsclass = htons(dnsQuery.dnsClass);
    
    // translate to raw data
    uint8_t *tmp = (uint8_t *)malloc(length + 4 + 1);
    uint8_t *ptr = tmp;
    memset(tmp, 0, length + 5);
    memcpy(ptr, domain_label, length);
    ptr+=length;
    memcpy(ptr, &dnstype, 2);
    ptr+=2;
    memcpy(ptr, &dnsclass, 2);
    
    NSData *data = [NSData dataWithBytes:tmp length:length + 4];
    if (data) {
        [*rawData appendData:data];
    }
    
    //config the offset of domainName
    [self configDomainLabelOffsetWithRawData:*rawData domainName:dnsQuery.domainName];
}

- (void)_appendRawData:(NSMutableData **)rawData withAnswers:(NSArray<IPDNSAnswer *> *)answers {
    if (answers == nil || answers.count == 0) {
        return ;
    }
    
    for (IPDNSAnswer *answer in answers) {
        // domain
        NSString *domainName = answer.domainName;
        uint8_t *name_compress = NULL;
        uint8_t size = [self compressByOffsetInRawData:*rawData domainName:domainName resultLabel:&name_compress];
        if (name_compress && size) {
            [*rawData appendData:[NSData dataWithBytes:name_compress length:size]];
        }
        [self configDomainLabelOffsetWithRawData:*rawData domainName:domainName];
        
        // dnsType
        uint16_t dnstype = htons(answer.dnsType);
        [*rawData appendBytes:&dnstype length:sizeof(dnstype)];
        
        // dnsClass
        uint16_t dnsclass = htons(answer.dnsClass);
        [*rawData appendBytes:&dnsclass length:sizeof(dnsclass)];
        
        // ttl
        uint32_t ttl = htonl(answer.ttl);
        [*rawData appendBytes:&ttl length:sizeof(ttl)];
        
        // data length
        uint16_t datalength = htons(answer.dataLength);
        [*rawData appendBytes:&datalength length:sizeof(datalength)];
        
        // data
        if (answer.dnsType == IPDNSTypeA) {
            struct in_addr addr;
            inet_aton([answer.data UTF8String], &addr);
            [*rawData appendBytes:&addr length:sizeof(struct in_addr)];
        }else if (answer.dnsType == IPDNSTypeCNAME) {
            NSString *domainName = answer.data;
            uint8_t *name_compress = NULL;
            uint8_t size = [self compressByOffsetInRawData:*rawData domainName:domainName resultLabel:&name_compress];
            if (name_compress && size) {
                [*rawData appendData:[NSData dataWithBytes:name_compress length:size]];
            }
            [self configDomainLabelOffsetWithRawData:*rawData domainName:domainName];
        }
    }
}

- (void)configDomainLabelOffsetWithRawData:(NSData *)rawData domainName:(NSString *)domainName {
    
    if (domainName.length <= 2) {
        return;
    }
    
    NSString *lastChar = [domainName substringFromIndex:domainName.length - 1];
    if ([lastChar isEqualToString:@"."]) {
        domainName = [domainName substringToIndex:domainName.length - 1];
    }
    
    // config full domain name
    uint8_t *domain_label = NULL;
    uint8_t length = [self compressByOffsetInRawData:rawData domainName:domainName resultLabel:&domain_label];
    
    NSMutableDictionary *offsetDictM = [NSMutableDictionary dictionaryWithDictionary:self.offsetOfDomainLabels];
    NSData *alldomain = [NSData dataWithBytes:domain_label length:length - 1];
    NSRange range = [rawData rangeOfData:alldomain options:NSDataSearchBackwards range:NSMakeRange(0, [rawData length])];
    if (range.length) {
        offsetDictM[domainName] = @(range.location + 1 - 2);
    }
    
    // config separtor domain label
    NSArray *domainLabels = [self separteLabels:domainName];
    for (NSString *domainLabel in domainLabels) {
        if ([offsetDictM.allKeys containsObject:domainLabel]) {
            continue;
        }
        NSData *data = [self partOffsetLabel:domainLabel];
        NSRange range = [rawData rangeOfData:data options:NSDataSearchBackwards range:NSMakeRange(0, rawData.length)];
        if (range.length) {
            offsetDictM[domainLabel] = @(range.location + 1 - 2);
        }
    }
    self.offsetOfDomainLabels = [NSDictionary dictionaryWithDictionary:offsetDictM];
}

- (NSData *)partOffsetLabel:(NSString *)labels {
    NSMutableData *dataM = [NSMutableData data];
    
    NSArray *components = [labels componentsSeparatedByString:@"."];
    NSString *label = components.firstObject;
    const uint8_t *name = (uint8_t *)[label UTF8String];
    uint8_t *ptr = (uint8_t *)malloc(label.length + 1);
    memset(ptr, 0, label.length + 1);
    memcpy(ptr, name, label.length);
    [dataM appendBytes:ptr length:label.length];
    
    if (components.count >= 2) {
        for (NSInteger i = 1; i < components.count; i++) {
            NSString *subLabel = components[i];
            uint8_t len = (uint8_t)subLabel.length;
            uint8_t *p = (uint8_t *)malloc(subLabel.length + 1 + 1);
            uint8_t *tmp = p;
            memset(p, 0, subLabel.length + 2);
            memcpy(p, &len, 1);
            tmp++;
            memcpy(tmp, [subLabel UTF8String], subLabel.length);
            [dataM appendBytes:p length:subLabel.length + 1];
        }
    }
    
    return [NSData dataWithData:dataM];
}

- (uint8_t )compressByOffsetInRawData:(NSData *)rawData domainName:(NSString *)domainName resultLabel:(uint8_t **)resultLabel {
    
    // check format
    NSString *pattern = @"[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+.?";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    if (![predicate evaluateWithObject:domainName]) {
        *resultLabel = NULL;
        return 0;
    }

    // compress nomal
    if (rawData == nil) {
        uint8_t *compresslabels = NULL;
        uint8_t size = compress_domain([domainName UTF8String], domainName.length, &compresslabels);
        *resultLabel = compresslabels;
        return size;
    }
    
    // compress offset: all
    NSArray *allStoreLabels = self.offsetOfDomainLabels.allKeys;
    if ([allStoreLabels containsObject:domainName]) {
        NSInteger value = [self.offsetOfDomainLabels[domainName] integerValue];
        uint16_t offset = value;
        uint16_t flag = 0xc000;
        flag =  flag | offset;
        flag = htons(flag);
        uint8_t *compresslabel = (uint8_t *)malloc(sizeof(flag) + 1);
        memset(compresslabel, 0, sizeof(flag) + 1);
        memcpy(compresslabel, &flag, sizeof(flag));
        *resultLabel = compresslabel;
        return 2;
    }
    
    // compress offset: part
    NSMutableData *dataM = [NSMutableData data];
    NSArray *domainLabels = [domainName componentsSeparatedByString:@"."];
    for (NSString *domainLabel in domainLabels) {
        if (domainLabel.length == 0) {
            continue;
        }
        const char *domain_label = [domainLabel UTF8String];
        uint8_t *compresslabel = NULL;
        uint8_t compresslabel_length = 0;
        if ([allStoreLabels containsObject:domainLabel]) {
            NSInteger value = [self.offsetOfDomainLabels[domainLabel] integerValue];
            uint16_t offset = value;
            uint16_t flag = 0xc000;
            flag =  flag | offset;
            flag = htons(flag);
            compresslabel = (uint8_t *)malloc(sizeof(flag) + 1);
            memset(compresslabel, 0, sizeof(flag) + 1);
            memcpy(compresslabel, &flag, sizeof(flag));
            compresslabel_length = 2;
        }else {
            compresslabel_length = compress_label(domain_label, domainLabel.length, &compresslabel);
        }
        [dataM appendBytes:compresslabel length:compresslabel_length];
    }
    // append .
    uint8_t flag = 0x00;
    [dataM appendBytes:&flag length:1];
    
    *resultLabel = (uint8_t *)dataM.bytes;
    return dataM.length;
}


#pragma mark - Parse
- (BOOL)parse:(NSError **)error {
    
    NSData *data = self.rawData;
    const Byte *bytes = (Byte *)data.bytes;
    if (data == nil || bytes == '\0') {
        NSError *err = [NSError errorWithDomain:IPErrorDomainName code:IPErrorCodeFormatError userInfo:@{NSLocalizedDescriptionKey:@"DNS message is not exist"}];
        *error = err;
        return NO;
    }
    dns_header_t header;
    memcpy(&header, bytes, sizeof(dns_header_t));
    [self parseHeader:header];
    
    // parse dns query section
    bytes+=sizeof(dns_header_t);
    dns_question_t *question = dns_parse_question((const char *)bytes, (uint32_t)data.length);
    [self parseQuerySecion:question];
    
    // parse dns answer section
    if (self.dnsHeader.qrType == DNSMessageTypeReply) {
        bytes+=sizeof(question->dnstype) + sizeof(question->dnsclass) + strlen(question->name) + 2;
        [self parseAnswerSection:bytes];
    }

    return YES;
}

- (void)parseHeader:(dns_header_t )header {
    
    IPDNSHeader *dnsHeader = [[IPDNSHeader alloc] init];
    // decode id
    dnsHeader.xid = NTOHS(header.xid);
    
    // decode flags
    uint16_t flags = ntohs(header.flags);
    dnsHeader.qrType                = (DNSMessageType) DNSHeaderQR(flags);
    dnsHeader.opType                = (DNSOperationCodeType) DNSHeaderOP(flags);
    dnsHeader.authoritativeAnswer   = DNSHeaderAA(flags);
    dnsHeader.truncation            = (DNSHeaderTC(flags) == 1?YES:NO);
    dnsHeader.recursionDesired      = (DNSHeaderRD(flags) == 1?YES:NO);
    dnsHeader.recursionAvailable    = (DNSHeaderRA(flags) == 1?YES:NO);
    dnsHeader.reservedZone          = DNSHeaderZ(flags);
    dnsHeader.responseCodeType      = (DNSResponseCodeType) DNSHeaderRC(flags);
    
    // decode other field
    dnsHeader.questionCount         = NTOHS(header.qdcount);
    dnsHeader.answerRecordCount     = NTOHS(header.ancount);
    dnsHeader.authorityRecordCount  = NTOHS(header.nscount);
    dnsHeader.additionalRecordCount = NTOHS(header.arcount);
    
    self.dnsHeader = dnsHeader;
}

- (void)parseQuerySecion:(dns_question_t *)question {
    IPDNSQuery *dnsQuery = [[IPDNSQuery alloc] init];
    
    NSString *domainName = [NSString stringWithUTF8String:question->name];
    domainName = [domainName stringByAppendingString:@"."];
    dnsQuery.domainName = domainName;
    
    dnsQuery.dnsType    = (IPDNSType)question->dnstype;
    dnsQuery.dnsClass   = (IPDNSClass)question->dnsclass;
    
    self.dnsQuery = dnsQuery;
}

- (void)parseAnswerSection:(const Byte *)message {
    
    if (self.dnsHeader.answerRecordCount <= 0) {
        return;
    }
    
    char *offset = (char *)message;
    NSMutableArray *arrayM = [NSMutableArray array];
    for (NSInteger index = 0; index < self.dnsHeader.answerRecordCount; index++) {
        IPDNSAnswer *answer = [[IPDNSAnswer alloc] init];
        
        // name_position
        uint8_t *name_position = (uint8_t *)offset;
        answer.domainName    = [self uncompressWithCompressData:name_position nameLength:2 rawData:self.rawData];
        offset+=2;
        
        // type
        uint16_t *type = (uint16_t *)offset;
        answer.dnsType = htons(*type);
        offset+=2;
        
        // class
        uint16_t *dnsclass = (uint16_t *)offset;
        answer.dnsClass = htons(*dnsclass);
        offset+=2;
        
        // ttl
        uint32_t *ttl = (uint32_t *)offset;
        answer.ttl = htonl(*ttl);
        offset+=4;
        
        // dataLength
        uint16_t *data_length = (uint16_t *)offset;
        answer.dataLength = htons(*data_length);
        offset+=2;
        
        // data
        NSString *data = nil;
        switch (answer.dnsType) {
            case IPDNSTypeA: {
                struct in_addr *addr = (struct in_addr *)offset;
                char *name = inet_ntoa(*addr);
                data = [NSString stringWithUTF8String:name];
                offset+=4;
            }
                break;
            case IPDNSTypeCNAME: {
                uint8_t *name_position = (uint8_t *)offset;
//                data = [self parseDomainName:name_position length:answer.dataLength];
                data = [self uncompressWithCompressData:name_position nameLength:answer.dataLength rawData:self.rawData];
                offset+=htons(*data_length);
            }
                break;
                
            default:
                break;
        }
        answer.data = data;
        
        [arrayM addObject:answer];
    }
    self.dnsAnswers = [NSArray arrayWithArray:arrayM];
    [arrayM removeAllObjects];
}


#pragma mark - Domain Name Compression

/**
 解压缩域名
 eg: 0xc00c   =>  www.baidu.com
 eg: 0x03www0x05baidu0xcom  => www.baidu.com
 eg: 0x03www0x01a0x06shifen0xc040 => www.a.shifen.com

 @param name_position 压缩密文的二进制起始位置
 @param nameLength 压缩密文对应的正常域名的长度
 @param rawData 原始数据
 @return 解压缩后的正常显示域名
 */
- (NSString *)uncompressWithCompressData:(uint8_t *)name_position nameLength:(NSInteger)nameLength rawData:(NSData *)rawData {
    
    u_char *begin = (u_char *) rawData.bytes;
    u_char *end = begin + rawData.length;
    u_char *src = name_position;
    char *dst = (char *)malloc(1024);
    memset(dst, 0, 1024);
    
    int num = ns_name_uncompress(begin, end, src, dst, 1024);
    NSString *t = @"";
    if (num != -1) {
        t = [NSString stringWithUTF8String:dst];
    }
    free(dst);
    dst = NULL;
    return t;
}


/**
 压缩域名
 eg: www.baidu.com => 0x03www0x05baidu0xc034
 */
- (NSData *)compressName:(NSString *)domainName {
    
    // 测试
    NSDictionary *offsetOfDomainLabels = @{
                                  @"www.baidu.com.": @(25),
                                  @"www.baidu":@(25),
                                  @"baidu.com.": @(28),
                                  @"www":@(25),
                                  @"baidu":@(28),
                                  @"com.":@(33)
                                  };
    self.offsetOfDomainLabels = offsetOfDomainLabels;
    
    NSMutableData *dataM = [NSMutableData data];
    
    // 将已有偏移量的标签排序
    NSArray *matchLabels = [self.offsetOfDomainLabels.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return (obj1.length < obj2.length);
    }];
    
    
    // 逐个排序，并记录匹配后的位置信息
    NSMutableArray *locationInfo = [NSMutableArray array];
    NSString *copyDomain = [domainName copy];
    BOOL allMatch = NO;
    for (NSString *matchLabel in matchLabels) {
        NSRange range = [copyDomain rangeOfString:matchLabel];
        NSInteger location = range.location;
        NSInteger length   = range.length;
        if (location != NSNotFound) {
            if ([matchLabel isEqualToString:domainName]) {
                allMatch = YES;
                break;
            }
            [locationInfo addObject: @{
                                       @"matchLabel":matchLabel,
                                       @"location":NSStringFromRange(range)
                                       }];
            NSMutableString *placeholder = [NSMutableString string];
            for (NSInteger i = 0; i < length; i++) {
                [placeholder appendString:@"&"];
            }
            copyDomain = [copyDomain stringByReplacingCharactersInRange:range withString:placeholder];
        }
    }

    // 全部匹配上了
    if (allMatch) {
        // 取出偏移量
        NSUInteger value = [[self.offsetOfDomainLabels valueForKey:domainName] integerValue];
        uint16_t offset = value;
        uint16_t flag = 0xc000;
        flag =  flag | offset;
        flag = htons(flag);
        [dataM appendBytes:&flag length:2];
        return [NSData dataWithData:dataM];
    }
    
    // 部分匹配上了
    if (locationInfo.count != 0) {
        NSArray *components = [copyDomain componentsSeparatedByString:@"."];
        for (NSString *compont in components) {
            NSRange range = [copyDomain rangeOfString:compont];
            BOOL match = NO;
            NSDictionary *matchInfo = nil;
            for (NSDictionary *info in locationInfo) {
                NSRange matchRange = NSRangeFromString([info valueForKey:@"location"]);
                if (NSEqualRanges(range, matchRange)) {
                    match = YES;
                    matchInfo = info;
                    break;
                }
            }
            if (match) {
                NSString *matchLabel = [matchInfo valueForKey:@"matchLabel"];
                NSInteger value = [[self.offsetOfDomainLabels valueForKey:matchLabel] integerValue];
                uint16_t offset = (uint16_t)value;
                uint16_t flag = 0xc000;
                flag =  flag | offset;
                flag = htons(flag);
                [dataM appendBytes:&flag length:2];
                
            }else {
                uint8_t size = (uint8_t)compont.length;
                [dataM appendBytes:&size length:1];
                NSString *copyCompont = [compont copy];
                const uint8_t *bytes = (uint8_t *)[copyCompont UTF8String];
                uint8_t *ptr = (uint8_t *)malloc(copyCompont.length + 1);
                memset(ptr, 0, copyCompont.length + 1);
                memcpy(ptr, bytes, copyCompont.length);
                [dataM appendBytes:ptr length:copyCompont.length];
            }
        }
        return dataM;
    }
    
    // 都未匹配上
    NSArray *components = [domainName componentsSeparatedByString:@"."];
    for (NSString *component in components) {
        if (component.length == 0) {
            uint8_t flag = 0x00;
            [dataM appendBytes:&flag length:1];
            break;
        }
        uint8_t size = (uint8_t)component.length;
        [dataM appendBytes:&size length:1];
        NSString *copyCompont = [component copy];
        const uint8_t *bytes = (uint8_t *)[copyCompont UTF8String];
        uint8_t *ptr = (uint8_t *)malloc(copyCompont.length + 1);
        memset(ptr, 0, copyCompont.length + 1);
        memcpy(ptr, bytes, copyCompont.length);
        [dataM appendBytes:ptr length:copyCompont.length];
    }
    
    return dataM;
}

/** 缓存rawData中指定域名标签的偏移量 */
- (void)cacheDomainOffset:(NSString *)domainName rawData:(NSData *)rawData {
    // 0x03www0x05baidu0xc034
    // www.baidu.com
}

#pragma mark - 域名处理
/** www.baidu.com => {www, baidu, com, www.baidu, baidu.com, www.baidu.com} */
- (NSArray *)separteLabels:(NSString *)domainName {
    
    if (domainName.length <= 2) {
        return @[];
    }
    
    NSString *lastChar = [domainName substringFromIndex:domainName.length - 1];
    if ([lastChar isEqualToString:@"."]) {
        domainName = [domainName substringToIndex:domainName.length - 1];
    }
    
    NSMutableArray *locations = [NSMutableArray array];
    [locations addObject:@(0)];
    NSString *tmp = [domainName copy];
    NSRange range = [tmp rangeOfString:@"."];
    while (range.location != NSNotFound) {
        [locations addObject: @(range.location)];
        tmp = [tmp stringByReplacingCharactersInRange:range withString:@" "];
        range = [tmp rangeOfString:@"."];
    }
    [locations addObject:@(domainName.length)];
    
    NSMutableArray *labels = [NSMutableArray array];
    for (NSInteger i = 0; i < locations.count - 1; i++) {
        for (NSInteger j = i + 1; j < locations.count; j++) {
            NSInteger length = [locations[j] integerValue] - [locations[i] integerValue];
            NSString *tmp = [domainName substringWithRange:NSMakeRange([locations[i] integerValue], length)];
            if ([[tmp substringToIndex:1] containsString:@"."]) {
                tmp = [tmp substringFromIndex:1];
            }
            if ([labels containsObject:tmp]) {
                [labels removeObject:tmp];
            }
            [labels addObject:tmp];
        }
    }
    return [NSMutableArray arrayWithArray:labels];
}


#pragma mark - 位置计算
/** header的起始位置 + c0的起始位置 */
- (uint8_t *)_headerPositionInRawData:(NSData *)rawData {
    uint8_t *bytes = (uint8_t *)rawData.bytes;
    uint8_t *c0_postion = bytes;  // 起始位置c0 + header的位置
    return c0_postion;
}
- (uint8_t *)_c0_positionInRawData:(NSData *)rawData {
    return [self _headerPositionInRawData:rawData];
}

/** query的起始位置 */
- (uint8_t *)_queryPositionInRawData:(NSData *)rawData {
    uint8_t *bytes = (uint8_t *)rawData.bytes;
    dns_header_t header;
    memcpy(&header, bytes, sizeof(dns_header_t));
    uint8_t *query_postion = bytes + sizeof(dns_header_t);  // query的起始位置
    return query_postion;
}


/** answer的起始位置 */
- (uint8_t *)_answerPositionInRawData:(NSData *)rawData {
    uint8_t *bytes = (uint8_t *)rawData.bytes;
    dns_header_t header;
    memcpy(&header, bytes, sizeof(dns_header_t));
    uint8_t *query_postion = bytes + sizeof(dns_header_t);  // query的起始位置
    dns_question_t *question = dns_parse_question((const char *)bytes, (uint32_t)rawData.length);
    uint8_t *answer_postion = query_postion + sizeof(question->dnstype) + sizeof(question->dnsclass) + strlen(question->name) + 2; // answer的起始位置
    return answer_postion;
}

/** 根据c0偏移量计算当前所在区域 */
- (IPDNSSection)sectionAreaWithOffset:(NSInteger)c0_offset inRawData:(NSData *)rawData {
    // position
    uint8_t *header_position = [self _headerPositionInRawData:rawData];
    uint8_t *query_position  = [self _queryPositionInRawData:rawData];
    uint8_t *answer_position = [self _answerPositionInRawData:rawData];
    
    // offset
    NSInteger c0 = 0;
    NSInteger queryOffset = query_position - header_position;
    NSInteger answerOffset = answer_position - header_position;
    
    if (c0_offset + c0 >= answerOffset) {
        return IPDNSSectionAnswer;
    }
    
    if (c0_offset + c0 >= queryOffset) {
        return IPDNSSectionAnswer;
    }
    
    return IPDNSSectionHeader;
}

@end
