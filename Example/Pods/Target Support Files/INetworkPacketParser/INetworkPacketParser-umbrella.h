#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "IPConstant.h"
#import "IPDNSMessage.h"
#import "IPDNSProtocol.h"
#import "IPPacket.h"
#import "IPTCPSegment.h"
#import "IPUDPSegment.h"

FOUNDATION_EXPORT double INetworkPacketParserVersionNumber;
FOUNDATION_EXPORT const unsigned char INetworkPacketParserVersionString[];

