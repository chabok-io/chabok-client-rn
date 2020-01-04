"use strict";

/**
 * This exposes the native AdpPushClient module as a JS module.
 */
import {NativeModules, Platform} from "react-native";

const AdpNativeModule = NativeModules.AdpPushClient;

export const playServicesAvailability = AdpNativeModule.playServicesAvailability;

export class AdpPushClient {

    login = (userId) => AdpNativeModule.login(userId);

    appWillOpenUrl = (url) => AdpNativeModule.appWillOpenUrl(url);

    setDefaultTracker = (defaultTracker) => AdpNativeModule.setDefaultTracker(defaultTracker);

    /**
     * @deprecated the function has been replaced with AdpNativeModule.setUserAttributes()
     */
    setUserInfo = (userInfo) => AdpNativeModule.setUserAttributes(userInfo);

    /**
     * @deprecated the function has been replaced with AdpNativeModule.getUserAttributes()
     */
    getUserInfo = () => AdpNativeModule.getUserAttributes();

    setUserAttributes = (userAttributes) => AdpNativeModule.setUserAttributes(userAttributes);
    getUserAttributes = () => AdpNativeModule.getUserAttributes();

    unsetUserAttribute = (attributeKey) => AdpNativeModule.unsetUserAttribute(attributeKey);
    addToUserAttributeArray = (attributeKey, attributeValue) => AdpNativeModule.addToUserAttributeArray(attributeKey, attributeValue);
    removeFromUserAttributeArray = (attributeKey, attributeValue) => AdpNativeModule.removeFromUserAttributeArray(attributeKey, attributeValue);

    incrementUserAttribute = (attribute, value = 1) => {
        if (typeof value != 'number') {
            throw new Error('Invalid increment value. value = ' + value);
        }
        AdpNativeModule.incrementUserAttribute(attribute, value);
    }

    setDeeplinkCallbackListener = (deeplinkCallbackListener) => {
        if (deeplinkCallbackListener) {
            AdpNativeModule.setOnDeeplinkResponseListener().then((deeplink) => {
                deeplinkCallbackListener(deeplink)
            });
        } else {
            throw new Error('deeplinkCallbackListener is invalid, please provide a callback');
        }
    }

    setReferralCallbackListener = (referralCallbackListener) => {
        if (referralCallbackListener) {
            AdpNativeModule.setOnReferralResponseListener().then((referralId) => {
                referralCallbackListener(referralId)
            });
        } else {
            throw new Error('referralCallbackListener is invalid, please provide a callback');
        }
    }

    trackPurchase = (eventName, chabokEvent) => {
        AdpNativeModule.trackPurchase(eventName, chabokEvent);
    }

    setDefaultNotificationChannel = (channelName) => {
        setDefaultNotificationChannel(channelName);
    }

    logout = () => AdpNativeModule.logout();

    /*
    For publish in public channel set userId to "*".
        * payload.channel: String
        * payload.content: String
        * payload.data: Object
        * payload.userId: String(optional)
     */
    publish = async (payload) => {
        if (!payload) {
            return Promise.reject(new Error('payload is required'))
        }
        if (!payload.channel || typeof payload.channel !== 'string') {
            return Promise.reject(new Error('channel must be a string value!'))
        }
        if (!payload.content || typeof payload.content !== 'string') {
            return Promise.reject(new Error('content must be a string value!'))
        }
        if (payload.userId && typeof payload.userId !== 'string') {
            return Promise.reject(new Error('userId must be a string value!'))
        }
        if (payload.data && typeof payload.data !== 'object') {
            return Promise.reject(new Error('data must be an object!'))
        }

        return await AdpNativeModule.publish(payload);
    };

    publishEvent = async (eventName, data) => {
        if (!data) {
            return Promise.reject(new Error("data must be a object value"))
        }
        if (!eventName || typeof eventName !== 'string') {
            return Promise.reject(new Error("eventName must be a string value"))
        }

        return await AdpNativeModule.publishEvent(eventName, data)
    };

    addTag = async (tag) => {
        return await AdpNativeModule.addTag(tag);
    };

    addTags = async (...tag) => {
        return await AdpNativeModule.addTags(tag);
    };

    removeTag = async (tag) => {
        return await AdpNativeModule.removeTag(tag);
    };

    removeTags = async (...tag) => {
        return await AdpNativeModule.removeTags(tag);
    };

    getInstallationId = async () => {
        return await AdpNativeModule.getInstallationId()
    }

    getUserId = async () => {
        return await AdpNativeModule.getUserId()
    }

    resetBadge = () => {
        AdpNativeModule.resetBadge()
    }

    track = (trackName, data) => {
        AdpNativeModule.track(trackName, data)
    }

    subscribe = async (channel) => {
        return await AdpNativeModule.subscribe(channel);
    };

    subscribeEvent = async (eventName, installationId) => {
        if (!eventName || typeof eventName !== 'string') {
            return Promise.reject(new Error("eventName must be a string value"))
        }

        return await AdpNativeModule.subscribeEvent(eventName, installationId);
    };

    unSubscribe = async (channel) => {
        return await AdpNativeModule.unSubscribe(channel);
    };

    unSubscribeEvent = async (eventName, installationId) => {
        if (!eventName || typeof eventName !== 'string') {
            return Promise.reject(new Error("eventName must be a string value"))
        }

        return await AdpNativeModule.unSubscribeEvent(eventName, installationId);
    };
}