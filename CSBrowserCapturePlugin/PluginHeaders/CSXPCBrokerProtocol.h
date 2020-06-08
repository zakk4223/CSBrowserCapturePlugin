//
//  CSXPCBrokerProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 5/28/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CSXPCBrokerProtocol <NSObject>

-(NSUInteger)protocolVersion;
-(void)registerListener:(NSXPCListenerEndpoint *)endpoint forUUID:(NSString *)uuid;
-(void)retrieveListenerforUUID:(NSString *)uuid withReply:(void (^)(NSXPCListenerEndpoint *listener))reply;

@end

NS_ASSUME_NONNULL_END
