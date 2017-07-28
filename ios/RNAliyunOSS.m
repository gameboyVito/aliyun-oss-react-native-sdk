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
 Will be called when this module's first listener is added.
 
 */
-(void)startObserving {
    _hasListeners = YES;
    // Set up any upstream listeners or background tasks as necessary
}


/**Will be called when this module's last listener is removed, or on dealloc.
 
 */
-(void)stopObserving {
    _hasListeners = NO;
    // Remove upstream listeners, stop unnecessary background tasks
}


/**
 Supported two events: uploadProgress, downloadProgress
 
 @return an array stored all supported events
 */
-(NSArray<NSString *> *) supportedEvents
{
    return @[@"uploadProgress", @"downloadProgress"];
}


/**
 Get local directory with read/write accessed
 
 @return document directory
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
 Setup initial configuration for initializing OSS Client
 
 @param configuration a configuration object (NSDictionary *) passed from react-native side
 */
-(void) initConfiguration:(NSDictionary *)configuration {
    _clientConfiguration = [OSSClientConfiguration new];
    _clientConfiguration.maxRetryCount = [RCTConvert int:configuration[@"maxRetryCount"]]; //default 3
    _clientConfiguration.timeoutIntervalForRequest = [RCTConvert double:configuration[@"timeoutIntervalForRequest"]]; //default 30
    _clientConfiguration.timeoutIntervalForResource = [RCTConvert double:configuration[@"timeoutIntervalForResource"]]; //default 24 * 60 * 60
}

// at the moment it is not possible to upload image by reading PHAsset
// we are saving image and saving it to the tmp location where we are allowed to access image later
+ (NSString*) generateTemporaryDirectoryFrom:(NSString*)sourcePath withData:(NSData*)data
{
    NSString *temporaryDirectory = [NSTemporaryDirectory() stringByAppendingString:@"react-native-aliyun-oss/"];
    
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:temporaryDirectory isDirectory:&isDir];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath: temporaryDirectory
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // create temp file
    NSString *newFilePath = [temporaryDirectory stringByAppendingString:[[NSUUID UUID] UUIDString]];
    newFilePath = [[newFilePath stringByAppendingString:@"."] stringByAppendingString:[sourcePath pathExtension]];

    [data writeToFile:newFilePath atomically:YES];
    
    return newFilePath;
}


/**
 Begin a new uploading task by getting a correct asset binary NSData, since the assets-library do not have a real path
 
 @param filepath passed from reacit-native side, it might be a path started with 'assets-library:' or 'file:'
 @param callback a block waiting to be called right after the binary data of asset is found
 */
-(void) beginUploadingWithFilepath:(NSString *)filepath resultBlock:(void (^) (NSData *))callback {
    
    NSURL *sourceURL = [[NSURL alloc] initWithString:filepath];
    
    // read asset data from filepath
    if ([filepath hasPrefix:@"assets-library:"]) {
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library assetForURL:sourceURL
                 resultBlock:^(ALAsset *asset) {
                     
                     ALAssetRepresentation *representation = [asset defaultRepresentation];
                     
                     Byte *buffer = (Byte*)malloc(representation.size);
                     NSUInteger buffered = [representation getBytes:buffer fromOffset:0.0 length:representation.size error:nil];
                     NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                     
                     //return the binary data of the Image
                     callback(data);
                 }
                failureBlock:^(NSError *error) {
                    NSLog(@"ALAssetsLibrary assetForURL error: %@", error);
                }];
    } else {
        NSData *data = [NSData dataWithContentsOfURL: sourceURL];
        callback(data);
    }
}


/**
 Expose this native module to RN
 
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
 Asynchronous uploading
 
 */
RCT_REMAP_METHOD(asyncUpload, asyncUploadWithBucketName:(NSString *)bucketName objectKey:(NSString *)objectKey filepath:(NSString *)filepath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    
    [self beginUploadingWithFilepath:filepath resultBlock:^(NSData *data) {
    
        OSSPutObjectRequest *put = [OSSPutObjectRequest new];
        
        //required fields
        put.bucketName = bucketName;
        put.objectKey = objectKey;
        put.uploadingData = data;
        
        //optional fields
        put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
            NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
            
            // Only send events if anyone is listening
            if (_hasListeners) {
                [self sendEventWithName:@"uploadProgress" body:@{@"bytesSent":[NSString stringWithFormat:@"%lld",bytesSent],
                                                                 @"totalByteSent": [NSString stringWithFormat:@"%lld",totalByteSent],
                                                                 @"totalBytesExpectedToSend": [NSString stringWithFormat:@"%lld",totalBytesExpectedToSend]}];
            }
        };
        
        OSSTask *putTask = [_client putObject:put];
        
        [putTask continueWithBlock:^id(OSSTask *task) {
            
            if (!task.error) {
                NSLog(@"upload object success!");
                resolve(@YES);
            } else {
                NSLog(@"upload object failed, error: %@" , task.error);
                reject(@"Error", @"Upload failed", task.error);
            }
            return nil;
        }];
        
    }];
}


/**
 Asynchronous downloading
 
 */
RCT_REMAP_METHOD(asyncDownload, asyncDownloadWithBucketName:(NSString *)bucketName objectKey:(NSString *)objectKey filepath:(NSString *)filepath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    
    OSSGetObjectRequest * get = [OSSGetObjectRequest new];
    
    //required fields
    get.bucketName = bucketName;
    get.objectKey = objectKey;
    
    //optional fields
    get.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        NSLog(@"%lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
        // Only send events if anyone is listening
        if (_hasListeners) {
            [self sendEventWithName:@"downloadProgress" body:@{@"bytesWritten":[NSString stringWithFormat:@"%lld",bytesWritten],
                                                               @"totalBytesWritten": [NSString stringWithFormat:@"%lld",totalBytesWritten],
                                                               @"totalBytesExpectedToWrite": [NSString stringWithFormat:@"%lld",totalBytesExpectedToWrite]}];
        }
    };
    
    if (filepath) {
        get.downloadToFileURL = [NSURL fileURLWithPath:[filepath stringByAppendingPathComponent:objectKey]];
    } else {
        NSString *docDir = [self getDocumentDirectory];
        get.downloadToFileURL = [NSURL fileURLWithPath:[docDir stringByAppendingPathComponent:objectKey]];
    }
    
    OSSTask * getTask = [_client getObject:get];
    
    [getTask continueWithBlock:^id(OSSTask *task) {
        
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
