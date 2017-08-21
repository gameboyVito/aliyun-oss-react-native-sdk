
# aliyun-oss-react-native-sdk

A  React Native SDK for AliyunOSS Services, providing most of the Native OSS APIs, like client initialization, uploading & downloading etc. A truly cross-platform SDK for Aliyun OSS Users.



## Getting started

- **NPM**:

  ```npm install aliyun-oss-react-native-sdk —save
  npm install aliyun-oss-react-native-sdk —save
  ```

- **YARN**: 

  ```
  yarn add aliyun-oss-react-native-sdk
  ```

  ​



## Installation 

#### iOS

- **CocoaPods**

  `pod 'aliyun-oss-react-native-sdk', :path => '../node_modules/aliyun-oss-react-native-sdk'`

- **Non-CocoaPods**

  - In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`. Go to `node_modules` ➜ `aliyun-oss-react-native-sdk` and add `RNAliyunOss.xcodeproj`
  - In XCode, in the project navigator, select your project. Add `libRNAliyunOSS.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
  - In XCode, in the project navigator, right click `Frameworks` ➜ `Add Files to [your project's name]`. Go to `node_modules` ➜ `aliyun-oss-react-native-sdk` ➜ `AliyunSDK`. Add `AliyunOSSiOS.framework`, and select *Copy items if needed* in the pop-up box.



#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNAliyunOSSPackage;` to the imports at the top of the file
  - Add `new RNAliyunOSSPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
   ```
   	include ':aliyun-oss-react-native-sdk'
   	project(':aliyun-oss-react-native-sdk').projectDir = new File(rootProject.projectDir, 	'../node_modules/aliyun-oss-react-native-sdk/android')
   ```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
   ```
      compile project(':aliyun-oss-react-native-sdk')
   ```




## Usage

#### Import library:

```javascript
import AliyunOSS from 'aliyun-oss-react-native-sdk';
```



#### Enable the dev mode: (optional)

```
AliyunOSS.enableDevMode();
```



#### Initialization Configuration: (optional)

```
const configuration = {
   maxRetryCount: 3,	
   timeoutIntervalForRequest: 30,
   timeoutIntervalForResource: 24 * 60 * 60
};
```



#### Initialization for OSS Client: (required - either one of them)

1. *PlainTextAKSK*

   ```
   AliyunOSS.initWithPlainTextAccessKey(accessKey, secretKey, endPoint, configuration);
   ```

2. *ImplementedSigner*

   ```
   AliyunOSS.initWithImplementedSigner(signature, accessKey, endPoint, configuration);
   ```

3. *SecurityToken* (recommended)

   ```
   AliyunOSS.initWithSecurityToken(securityToken, accessKey, secretKey, endPoint, configuration);
   ```




#### Asynchronously uploading:

```
AliyunOSS.asyncUpload(bucketName, objectKey, filepath);
```

- Supported three different type of **filepath**: (prefix)
  - `assets-library://`
  - `file://`
  - `data://`



#### Asynchronously downloading:

```
AliyunOSS.asyncDownload(bucketName, objectKey, filepath);
```



#### Supported two events: (optional)

- uploadProgress

  ```
  AliyunOSS.addEventListener('uploadPress', (event) => {
    console.log(event);
  });
  ```

- downloadProgress

  ```
  AliyunOSS.addEventListener('downloadProgress', (event) => {
    console.log(event);
  });
  ```




#### Properties for Initialization:

| Property      | Type                  | Description                              |
| ------------- | --------------------- | ---------------------------------------- |
| accessKey     | String (**required**) | The access key of your OSS service       |
| secretKey     | String (**required**) | The secret key of your OSS service       |
| endPoint      | String (**required**) | The end point of your OSS service        |
| configuration | Object (optional)     | `maxRetryCount = 3`,  `timeoutIntervalForRequest = 30` ,  `timeoutIntervalForResource = 86400` (all of them are numbers) |
| signature     | String (optional)     | Also known as: Signed URL Authorization  |
| securityToken | String (optional)     | Also known as: STS Authorization         |



#### Properties for Upload and Download:

| Property   | Type                  | Description                              |
| ---------- | --------------------- | ---------------------------------------- |
| bucketName | String (**required**) | The bucket name of your OSS service      |
| objectKey  | String (**required**) | The cloud path for storing your remote file |
| filepath   | String (**required**) | The local path for loading or saving your file |



## TO-DO-LIST:

- ~~Implement android side~~  ✔︎
- Bucket management
- Advanced upload modes
- Advanced download modes



## Liscence

MIT