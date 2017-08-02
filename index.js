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

    //Enable dev mode
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
    asyncUpload(bucketName, objectKey, filepath) {
        return RNAliyunOSS.asyncUpload(bucketName, objectKey, filepath);
    },

    /**
     * Asynchronously downloading
     */
    asyncDownload(bucketName, objectKey, filepath = null) {
        return RNAliyunOSS.asyncDownload(bucketName, objectKey, filepath);
    },

    /**
     * event listener for native upload/download event
     * @param event one of 'uploadProgress' or 'downloadProgress'
     * @param callback a callback function accepts one params: event
     */
    addEventListener(event, callback) {
        const RNAliyunEmitter = Platform.OS === 'ios' ? new NativeEventEmitter(RNAliyunOSS) : new DeviceEventEmitter(RNAliyunOSS);
        switch (event) {
            case 'uploadProgress':
                subscription = RNAliyunEmitter.addListener(
                    'uploadProgress',
                    e => callback(e)
                );
                break;
            case 'downloadProgress':
                subscription = RNAliyunEmitter.addListener(
                    'downloadProgress',
                    e => callback(e)
                );
                break;
            default:
                break;
        }
    },

    /**
     * remove event listener for native upload/download event
     * @param event one of 'uploadProgress' or 'downloadProgress'
     */
    removeEventListener(event) {
        switch (event) {
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