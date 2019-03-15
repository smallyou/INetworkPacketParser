//
//  IPConstant.h
//  INetworkPacketParser
//
//  Created by smallyou on 2019/3/12.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IPErrorCode) {
    IPErrorCodeUnsupport        = 1,
    IPErrorCodeFormatError      = 2
};

FOUNDATION_EXPORT NSString *const IPErrorDomainName;

