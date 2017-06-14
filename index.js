import {DeviceEventEmitter, NativeEventEmitter, NativeModules, Platform} from "react-native";
const {RNAliyunOSS} = NativeModules;

let subscription;

//default configuration for OSS Client
const conf = {
    maxRetryCount: 3,
    timeoutIntervalForRequest: 30,
    timeoutIntervalForResource: 24 * 60 * 60
};

export default AliyunOSS = {

    //enable the dev mode
    enableDevMode() {
        RNAliyunOSS.enableDevMode();
    },

    /**
     * Initialize the OSS Client
     * Mode: PlainTextAKSK
     */
    initWithPlainTextAccessKey(accessKey, secretKey, endPoint, configuration = conf) {
        RNAliyunOSS.initWithPlainTextAccessKey(accessKey, secretKey, endPoint, configuration);
    },

    /**
     * Initialize the OSS Client
     * Mode: ImplementedSigner
     */
    initWithImplementedSigner(signature, accessKey, endPoint, configuration = conf) {
        RNAliyunOSS.initWithImplementedSigner(signature, accessKey, endPoint, configuration);
    },

    /**
     * Initialize the OSS Client
     * Mode: SecurityToken (STS)
     */
    initWithSecurityToken(securityToken, accessKey, secretKey, endPoint, configuration = conf) {
        RNAliyunOSS.initWithSecurityToken(securityToken, accessKey, secretKey, endPoint, configuration);
    },

    /**
     * Asynchronously uploading
     */
    asyncUpload(bucketName, objectKey, filePath) {
        return RNAliyunOSS.asyncUpload(bucketName, objectKey, filePath);
    },

    /**
     * Asynchronously downloading
     */
    asyncDownload(bucketName, objectKey, filePath) {
        return RNAliyunOSS.asyncDownload(bucketName, objectKey, filePath);
    },

    /**
     * event listener for native upload/download event
     * @param type one of 'uploadProgress' or 'downloadProgress'
     * @param callback a callback function accepts one params: event
     */
    addEventListener(type, callback) {
        const RNAliyunEmitter = Platform.OS === 'ios' ? new NativeEventEmitter(RNAliyunOSS) : new DeviceEventEmitter(RNAliyunOSS);
        switch (type) {
            case 'uploadProgress':
                subscription = RNAliyunEmitter.addListener(
                    'uploadProgress',
                    event => callback(event)
                );
                break;
            case 'downloadProgress':
                subscription = RNAliyunEmitter.addListener(
                    'downloadProgress',
                    event => callback(event)
                );
                break;
            default:
                break;
        }
    },

    /**
     * remove event listener for native upload/download event
     * @param type one of 'uploadProgress' or 'downloadProgress'
     */
    removeEventListener(type) {
        switch (type) {
            case 'uploadProgress':
                subscription.remove();
                break;
            case 'downloadProgress':
                subscription.remove();
                break;
            default:
                break;
        }
    }
};
