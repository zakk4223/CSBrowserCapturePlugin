//
//  CSXPCConnectionVendor.h
//  CocoaSplit
//
//  Created by Zakk on 9/3/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CSXPCConnectionVendor <NSObject>

-(void)registerXPCEndpoint:(NSXPCListenerEndpoint *)endpoint forUUID:(NSString *)uuid;
-(void)deregisterXPCEndpointForUUID:(NSString *)uuid;
-(void)getXPCEndpointForUUID:(NSString *)uuid withReply:(void (^)(NSXPCListenerEndpoint *))reply;

@end
