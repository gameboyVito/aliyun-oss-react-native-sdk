//
//  RNAliyunOSS.h
//  RNAliyunOSS
//
//  Created by CHEN Jiajie on 10/6/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <React/RCTLog.h>
#import <React/RCTConvert.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <AliyunOSSiOS/OSSService.h>

@interface RNAliyunOSS : RCTEventEmitter <RCTBridgeModule>

@property OSSClient *client;
@property OSSClientConfiguration *clientConfiguration;

-(NSString *) getDocumentDirectory;
-(void) initConfiguration: (NSDictionary *)conf;

@end

