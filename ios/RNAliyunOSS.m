//
//  RNAliyunOSS.m
//  RNAliyunOSS
//
//  Created by CHEN Jiajie on 10/6/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RNAliyunOSS.h"

@implementation RNAliyunOSS

@synthesize client;

// get local file dir which is readwrite able
- (NSString *)getDocumentDirectory {
    NSString * path = NSHomeDirectory();
    NSLog(@"NSHomeDirectory:%@",path);
    NSString * userName = NSUserName();
    NSString * rootPath = NSHomeDirectoryForUser(userName);
    NSLog(@"NSHomeDirectoryForUser:%@",rootPath);
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(enableDevMode){
    // enable OSS logger
    [OSSLog enableLog];
}

RCT_EXPORT_METHOD(initOSSClientWithPlainTextAccessKey: (NSString *)accessKey secretKey: (NSString *)secretKey endPoint: (NSString *)endPoint configuration: (NSDictionary *)configuration){
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:accessKey secretKey:secretKey];
    
    OSSClientConfiguration * conf = [OSSClientConfiguration new];
    conf.maxRetryCount = [RCTConvert NSInteger:configuration[@"maxRetryCount"]]; // maximum retry times when netowrk error happened, default 3
    conf.timeoutIntervalForRequest = [RCTConvert NSTimeInterval:configuration[@"timeoutIntervalForRequest"]]; // timeout interval, default 30
    conf.timeoutIntervalForResource = [RCTConvert NSTimeInterval:configuration[@"timeoutIntervalForResource"]]; // maximum network transportation interval, default 24 * 60 * 60
    
    client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:conf];
}

@end
