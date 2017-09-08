//
//  RNAliyunOSS.h
//  RNAliyunOSS
//
//  Created by CHEN Jiajie on 10/6/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <AliyunOSSiOS/OSSService.h>


@interface RNAliyunOSS : RCTEventEmitter <RCTBridgeModule>

@property OSSClient *client;
@property OSSClientConfiguration *clientConfiguration;

@property bool hasListeners;

-(NSString *)getDocumentDirectory;
-(NSString *)getTemporaryDirectory;
-(void) initConfiguration:(NSDictionary *)configuration;
-(void) beginUploadingWithFilepath:(NSString *)filepath resultBlock:(void (^) (NSData *))callback;

+ (NSString*)generateTemporaryDirectoryFrom:(NSString*)sourcePath withData:(NSData*)data;

@end

