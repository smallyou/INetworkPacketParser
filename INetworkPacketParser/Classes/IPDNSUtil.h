//
//  IPDNSUtil.h
//  INetworkPacketParser
//
//  Created by admin on 2019/3/13.
//

#ifndef IPDNSUtil_h
#define IPDNSUtil_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#endif /* IPDNSUtil_h */


/**
 compress domain label
 example: www => 0x3www

 @param domain_label_origin domain label
 @param length length of label
 @param compresslabel result
 @return length of compress label
 */
uint8_t compress_label(const char *domain_label_origin, uint8_t length, uint8_t **compresslabel);

/**
 compress domain
 example: www.baidu.com => 0x3www0x5baidu.com0x3com
 
 @param domain_name_origin domain name
 @param length length of domainname
 @param compresslabel result
 @return length
 */
uint8_t compress_domain(const char *domain_name_origin, uint8_t length, uint8_t **compresslabel);
