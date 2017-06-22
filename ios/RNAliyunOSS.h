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
#import <AssetsLibrary/AssetsLibrary.h>

@interface RNAliyunOSS : RCTEventEmitter <RCTBridgeModule>

@property OSSClient *client;
@property OSSClientConfiguration *clientConfiguration;

-(NSString *) getDocumentDirectory;
-(void) initConfiguration:(NSDictionary *)configuration;
-(void) beginUploadingWithFilepath:(NSString *)filepath assetBinary:(void (^) (NSData *))callback;

@end

