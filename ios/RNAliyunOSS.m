//
//  RNAliyunOSS.m
//  RNAliyunOSS
//
//  Created by CHEN Jiajie on 10/6/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "RNAliyunOSS.h"
#import <React/RCTLog.h>
#import <React/RCTConvert.h>
@import Photos;
@import MobileCoreServices;


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
-(NSArray<NSString *> *)supportedEvents
{
    return @[@"uploadProgress", @"downloadProgress"];
}


/**
 Get local directory with read/write accessed
 
 @return document directory
 */
-(NSString *)getDocumentDirectory {
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
 Get a temporary directory inside of application's sandbox
 
 @return document directory
 */
-(NSString*)getTemporaryDirectory {
    NSString *TMP_DIRECTORY = @"react-native/";
    NSString *filepath = [NSTemporaryDirectory() stringByAppendingString:TMP_DIRECTORY];
    
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filepath isDirectory:&isDir];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath: filepath
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return filepath;
}


/**
 Setup initial configuration for initializing OSS Client
 
 @param configuration a configuration object (NSDictionary *) passed from react-native side
 */
-(void)initConfiguration:(NSDictionary *)configuration {
    _clientConfiguration = [OSSClientConfiguration new];
    _clientConfiguration.maxRetryCount = [RCTConvert int:configuration[@"maxRetryCount"]]; //default 3
    _clientConfiguration.timeoutIntervalForRequest = [RCTConvert double:configuration[@"timeoutIntervalForRequest"]]; //default 30
    _clientConfiguration.timeoutIntervalForResource = [RCTConvert double:configuration[@"timeoutIntervalForResource"]]; //default 24 * 60 * 60
}


/**
 Begin a new uploading task
 Currently, support AssetLibrary, PhotoKit, and pure File for uploading
 Also, will convert the HEIC image to JPEG format
 
 @param filepath passed from reacit-native side, it might be a path started with 'assets-library://', 'localIdentifier://', 'file:'
 @param callback a block waiting to be called right after the binary data of asset is found
 */
-(void)beginUploadingWithFilepath:(NSString *)filepath resultBlock:(void (^) (NSData *))callback {
    
    // read asset data from filepath
    if ([filepath hasPrefix:@"assets-library://"]) {
        PHAsset *asset = [PHAsset fetchAssetsWithALAssetURLs:@[filepath] options:nil].firstObject;
        [self convertToNSDataFromAsset:asset withHandler:callback];
        
    } else if ([filepath hasPrefix:@"localIdentifier://"]) {
        NSString *localIdentifier = [filepath stringByReplacingOccurrencesOfString:@"localIdentifier://" withString:@""];
        PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil].firstObject;
        [self convertToNSDataFromAsset:asset withHandler:callback];
        
    } else {
        NSData *data = [NSData dataWithContentsOfFile:filepath];
        callback(data);
        
    }
}

/**
 a helper method to do the file convertion

 @param asset PHAsset
 @param handler a callback block
 */
-(void)convertToNSDataFromAsset:(PHAsset *)asset withHandler:(void (^) (NSData *))handler
{
    PHImageManager *imageManager = [PHImageManager defaultManager];
    
    switch (asset.mediaType) {
            
        case PHAssetMediaTypeImage: {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            [imageManager requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                if ([dataUTI isEqualToString:(__bridge NSString *)kUTTypeJPEG]) {
                    handler(imageData);
                } else {
                    //if the image UTI is not JPEG, then do the convertion to make sure its compatibility
                    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                    NSDictionary *imageInfo = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
                    NSDictionary *metadata = [imageInfo copy];
                    
                    NSMutableData *imageDataJPEG = [NSMutableData data];
                    
                    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageDataJPEG, kUTTypeJPEG, 1, NULL);
                    CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metadata);
                    CGImageDestinationFinalize(destination);
                    
                    handler([NSData dataWithData:imageDataJPEG]);
                }
            }];
            break;
        }
            
        case PHAssetMediaTypeVideo:{
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            [imageManager requestExportSessionForVideo:asset options:options exportPreset:AVAssetExportPresetHighestQuality resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                
                //generate a temporary directory for caching the video (MP4 Only)
                NSString *filePath = [[self getTemporaryDirectory] stringByAppendingString:[[NSUUID UUID] UUIDString]];
                filePath = [filePath stringByAppendingString:@".mp4"];
                
                exportSession.shouldOptimizeForNetworkUse = YES;
                exportSession.outputFileType = AVFileTypeMPEG4;
                exportSession.outputURL = [NSURL fileURLWithPath:filePath];
                
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    handler([NSData dataWithContentsOfFile:filePath]);
                }];
            }];
            break;
        }
        default:
            break;
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
                resolve(task.description);
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
