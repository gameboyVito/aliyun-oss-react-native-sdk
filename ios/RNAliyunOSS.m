//
//  RNAliyunOSS.m
//  RNAliyunOSS
//
//  Created by CHEN Jiajie on 10/6/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RNAliyunOSS.h"

@implementation RNAliyunOSS


/**
 supported two events: uploadProgress, downloadProgress
 */
-(NSArray<NSString *> *) supportedEvents
{
    return @[@"uploadProgress", @"downloadProgress"];
}


/**
 get local directory with read/write accessed
 */
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


/**
 setup initial configuration
 */
-(void) initConfiguration:(NSDictionary *)conf {
    _clientConfiguration = [OSSClientConfiguration new];
    _clientConfiguration.maxRetryCount = [RCTConvert int:conf[@"maxRetryCount"]]; //default 3
    _clientConfiguration.timeoutIntervalForRequest = [RCTConvert NSTimeInterval:conf[@"timeoutIntervalForRequest"]]; //default 30
    _clientConfiguration.timeoutIntervalForResource = [RCTConvert NSTimeInterval:conf[@"timeoutIntervalForResource"]]; //default 24 * 60 * 60
}

/**
 expose this native module to RN
 */
RCT_EXPORT_MODULE()


/**
 enable the dev mode
 */
RCT_EXPORT_METHOD(enableDevMode){
    // enable OSS logger
    [OSSLog enableLog];
}


/**
 initWithPlainTextAccessKey
 */
RCT_EXPORT_METHOD(initWithPlainTextAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey endPoint:(NSString *)endPoint configuration:(NSDictionary *)configuration){
    
    id<OSSCredentialProvider> credential = [[OSSPlainTextAKSKPairCredentialProvider alloc] initWithPlainTextAccessKey:accessKey secretKey:secretKey];
    
    [self initConfiguration: configuration];
    
    _client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:_clientConfiguration];
}


/**
 initWithImplementedSigner
 */
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


/**
 initWithSecurityToken
 */
RCT_EXPORT_METHOD(initWithSecurityToken:(NSString *)securityToken accessKey:(NSString *)accessKey secretKey:(NSString *)secretKey endPoint:(NSString *)endPoint configuration:(NSDictionary *)configuration){
    
    id<OSSCredentialProvider> credential = [[OSSStsTokenCredentialProvider alloc] initWithAccessKeyId:accessKey secretKeyId:secretKey securityToken:securityToken];
    
    [self initConfiguration: configuration];
    
    
    _client = [[OSSClient alloc] initWithEndpoint:endPoint credentialProvider:credential clientConfiguration:_clientConfiguration];
}


/**
 Asynchronously uploading
 */
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
        
        task = [_client presignPublicURLWithBucketName:bucketName withObjectKey:objectKey];
        
        if (!task.error) {
            NSLog(@"upload object success!");
            resolve(@YES);
        } else {
            NSLog(@"upload object failed, error: %@" , task.error);
            reject(@"Error", @"Upload failed", task.error);
        }
        return nil;
    }];
}


/**
 Asynchronously downloading
 */
RCT_REMAP_METHOD(asyncDownload, asyncDownloadWithBucketName:(NSString *)bucketName objectKey:(NSString *)objectKey filePath:(NSString *)filePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    
    OSSGetObjectRequest * get = [OSSGetObjectRequest new];
    
    //required fields
    get.bucketName = bucketName;
    get.objectKey = objectKey;
    
    //optional fields
    get.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"%lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        [self sendEventWithName:@"downloadProgress" body:@{@"bytesWritten":[NSString stringWithFormat:@"%lld",bytesWritten],
                                                         @"totalBytesWritten": [NSString stringWithFormat:@"%lld",totalBytesWritten],
                                                         @"totalBytesExpectedToWrite": [NSString stringWithFormat:@"%lld",totalBytesExpectedToWrite]}];
    };
    
    NSString *docDir = [self getDocumentDirectory];
    get.downloadToFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:objectKey]];
    
    OSSTask * getTask = [_client getObject:get];
    
    [getTask continueWithBlock:^id(OSSTask *task) {
        
        task = [_client presignPublicURLWithBucketName:bucketName withObjectKey:objectKey];
        
        if (!task.error) {
            NSLog(@"download object success!");
            OSSGetObjectResult *result = task.result;
            NSLog(@"download dota length: %lu", [result.downloadedData length]);
            resolve(get.downloadToFileURL);
        } else {
            NSLog(@"download object failed, error: %@" ,task.error);
            reject(@"Error", @"Download failed", task.error);
        }
        return nil;
    }];
}

@end
