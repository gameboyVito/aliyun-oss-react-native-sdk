//
//  RNAliyunOSS.m
//  RNAliyunOSS
//
//  Created by CHEN Jiajie on 10/6/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RNAliyunOSS.h"

@implementation RNAliyunOSS

// get local file dir which is readwrite able
-(NSString *) getDocumentDirectory {
    NSString * path = NSHomeDirectory();
    NSLog(@"NSHomeDirectory:%@",path);
    NSString * userName = NSUserName();
    NSString * rootPath = NSHomeDirectoryForUser(userName);
    NSLog(@"NSHomeDirectoryForUser:%@",rootPath);
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

-(void) initConfiguration:(NSDictionary *)conf {
    _clientConfiguration = [OSSClientConfiguration new];
    _clientConfiguration.maxRetryCount = [RCTConvert NSInteger:conf[@"maxRetryCount"]]; //default 3
    _clientConfiguration.timeoutIntervalForRequest = [RCTConvert NSTimeInterval:conf[@"timeoutIntervalForRequest"]]; //default 30
    _clientConfiguration.timeoutIntervalForResource = [RCTConvert NSTimeInterval:conf[@"timeoutIntervalForResource"]]; //default 24 * 60 * 60
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(enableDevMode){
    // enable OSS logger
    [OSSLog enableLog];
}

RCT_EXPORT_METHOD(initWithPlainTextAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey endPoint:(NSString *)endPoint configuration:(NSDictionary *)configuration){
    
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:accessKey secretKey:secretKey];
    
    [self initConfiguration: configuration];
    
    _client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:_clientConfiguration];
}

RCT_EXPORT_METHOD(initWithImplementedSigner:(NSString *)signature accessKey:(NSString *)accessKey endPoint:(NSString *)endPoint configuration:(NSDictionary *)configuration){
    
    id<OSSCredentialProvider> credential = [[OSSCustomSignerCredentialProvider alloc] initWithImplementedSigner:^NSString *(NSString *contentToSign, NSError *__autoreleasing *error) {
        if (signature != nil) {
            *error = nil;
        } else {
            // construct error object
            *error = [NSError errorWithDomain:endPoint code:OSSClientErrorCodeSignFailed userInfo:nil];
            return nil;
        }
        return [NSString stringWithFormat:@"OSS %@:%@", accessKey, signature];
    }];
    
    [self initConfiguration: configuration];
    
    _client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:_clientConfiguration];
}

RCT_EXPORT_METHOD(initWithSecurityToken:(NSString *)securityToken accessKey:(NSString *)accessKey secretKey:(NSString *)secretKey endPoint:(NSString *)endPoint configuration:(NSDictionary *)configuration){
    
    id<OSSCredentialProvider> credential = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:accessKey secretKeyId:secretKey securityToken:securityToken];
    
    [self initConfiguration: configuration];
    
    
    _client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:_clientConfiguration];
}

RCT_REMAP_METHOD(asyncUpload, asyncUploadWithBucketName:(NSString *)bucketName objectKey:(NSString *)objectKey filePath:(NSString *)filePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    
    OSSPutObjectRequest *put = [OSSPutObjectRequest new];
    
    //required fields
    put.bucketName = bucketName;
    put.objectKey = objectKey;
    put.uploadingFileURL = [NSURL fileURLWithPath:filePath];
    
    //optional fields
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
        [self sendEventWithName:@"uploadProgress" body:@{@"bytesSent":[NSString stringWithFormat:@"%lld",bytesSent],
                                                         @"totalByteSent": [NSString stringWithFormat:@"%lld",totalByteSent],
                                                         @"totalBytesExpectedToSend": [NSString stringWithFormat:@"%lld",totalBytesExpectedToSend]}];
    };
    
    OSSTask *putTask = [_client putObject:put];
    
    [putTask continueWithBlock:^id(OSSTask *task) {
        NSLog(@"objectKey: %@", put.objectKey);
        if (!task.error) {
            NSLog(@"upload object success!");
            resolve(@YES);
        } else {
            NSLog(@"upload object failed, error: %@" , task.error);
            reject(@"Error", @"Somthing wrong", nil);
        }
        return nil;
    }];
}

RCT_REMAP_METHOD(upload, uploadWithBucketName:(NSString *)bucketName objectKey:(NSString *)objectKey filePath:(NSString *)filePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    
    OSSPutObjectRequest *put = [OSSPutObjectRequest new];
    
    //required fields
    put.bucketName = bucketName;
    put.objectKey = objectKey;
    put.uploadingFileURL = [NSURL fileURLWithPath:filePath];
    
    //optional fields
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
        [self sendEventWithName:@"uploadProgress" body:@{@"bytesSent":[NSString stringWithFormat:@"%lld",bytesSent],
                                                         @"totalByteSent": [NSString stringWithFormat:@"%lld",totalByteSent],
                                                         @"totalBytesExpectedToSend": [NSString stringWithFormat:@"%lld",totalBytesExpectedToSend]}];
    };
    
    OSSTask *task = [_client putObject:put];
    
    [task waitUntilFinished];  //synchronization
    
    if (!task.error) {
        NSLog(@"upload object success!");
        resolve(@YES);
    } else {
        NSLog(@"upload object failed, error: %@" , task.error);
        reject(@"Error", @"Somthing wrong", nil);
    }
}

@end
