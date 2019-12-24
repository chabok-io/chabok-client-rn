![Logo](https://github.com/chabok-io/chabok-assets/blob/master/sdk-logo/RN-Bridge.svg)

# Chabok Push Client for React Native (Bridge)

[![NpmVersion](https://img.shields.io/npm/v/react-native-chabok.svg)](https://www.npmjs.com/package/react-native-chabok)
[![npm](https://img.shields.io/npm/dt/react-native-chabok.svg)](https://www.npmjs.com/package/react-native-chabok)

React native wrapper for chabok library.
This client library supports react-native to use chabok push library.
A Wrapper around native library to use chabok functionalities in react-native environment.

## installation
For installation refer to [React-Native (Bridge) docs](https://doc.chabok.io/react-native-bridge/introducing.html) and platform specific parts (Android and iOS).

To install packages:

```bash
yarn add react-native-chabok
```
or

```bash
npm install react-native-chabok --save
```

For linking `react-native-chabok`

```bash
react-native link react-native-chabok
```

## Getting Started - Android
1. Add Google and Chabok plugins to `build.gradle` project level file.

```groovy
buildscript {
    repositories {
        google()
        jcenter()
        maven {
            url "https://plugins.gradle.org/m2/" 
        }
    }
    
    dependencies {    
        classpath "io.chabok.plugin:chabok-services:1.0.0"
        classpath "com.google.gms:google-services:4.3.2"
    }
}
```

2. Apply Google and Chabok plugins and add Chabok dependencies to `build.gradle` application level file.

```groovy
dependencies {
    implementation 'com.adpdigital.push:chabok-lib:3.1.0'
    implementation 'me.leolin:ShortcutBadger:1.1.22@aar'  
    implementation 'com.google.firebase:firebase-messaging:17.1.0'
    implementation 'com.android.installreferrer:installreferrer:1.0'
}

apply plugin: 'io.chabok.plugin.chabok-services'
apply plugin: 'com.google.gms.google-services'
```

4. Initialize Chabok SDK in your `MainApplication.java`:

```java
public class MainApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        AdpPushClient.configureEnvironment(Environment.SANDBOX); // or PRODUCTION
    }
}
```

## Getting started - iOS

1. The native iOS SDKs need to be setup using Cocoapods. In your project's `ios` directory, create a Podfile.

```bash
$ cd ios
$ pod init
```

2. Edit the Podfile to include `ChabokPush` as a dependency for your project, and then install the pod with `pod instal`.

```bash
use_frameworks!
platform :ios, '9.0'

target 'YOUR_TARGET_NAME' do

  # Pods for AwesomeProject
  pod 'ChabokPush'

end
```

3. Import inside `AppDelegate`:

```objectivec

#import "AppDelegate.h"
#import <AdpPushClient/AdpPushClient.h>

- (BOOL)application:(UIApplication *)application
            didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [PushClientManager.defaultManager configureEnvironment:Sandbox]; // or PRODUCTION
 
    return YES;
}

```

## Basic Usage
In your `App.js`:

### Initialize
For initializing the Chabok in javascript follow the bellow code:

```js
import { NativeEventEmitter, NativeModules } from 'react-native';
import chabok from 'react-native-chabok';

this.chabok = new chabok.AdpPushClient();
```

### Change chabok environment
With using `configureEnvironment` can change the Chabok environment to sandbox or production.

### Login user
To login user in the Chabok service use `login` method:
```js
this.chabok.login('USER_ID');
```

### Getting message
To get the Chabok message `addListener` on `ChabokMessageReceived` event:

```js
const chabokEmitter = new NativeEventEmitter(NativeModules.AdpPushClient);

chabokEmitter.addListener('ChabokMessageReceived',
    (msg) => {
        alert(JSON.stringify(msg));
    });
```

### Getting connection status
To get connection state `addListener` on `connectionStatus` event:

```js
const chabokEmitter = new NativeEventEmitter(NativeModules.AdpPushClient);

chabokEmitter.addListener(
    'connectionStatus',
        (status) => {
            if (status === 'CONNECTED') {
                //Connected to chabok
            } else if (status === 'CONNECTING') {
                //Connecting to chabok
            } else if (status === 'DISCONNECTED') {
                //Disconnected
            } else {
                // Closed
            }
    });
```

### Publish message
For publishing a message use `publish` method:

```js
const msg = {
    channel: "default",
    userId: "USER_ID",
    content:'Hello world',
    data: OBJECT
        };
this.chabok.publish(msg)
```

### Subscribe on channel
To subscribe on a channel use `subscribe` method:
```js
this.chabok.subscribe('CHANNEL_NAME');
```

### Unsubscribe to channel
To unsubscribe to channel use `unSubscribe` method: 

```js
this.chabok.unSubscribe('CHANNEL_NAME');
```

### Publish event
To publish an event use `publishEvent` method:

```js
this.chabok.publishEvent('EVENT_NAME', [OBJECT]);
```

### Subscribe on event
To subscribe on an event use `subscribeEvent` method:

```js
this.chabok.subscribeEvent("EVENT_NAME");
```

For subscribe on a single device use the other signature:

```js
this.chabok.subscribeEvent("EVENT_NAME","INSTALLATION_ID");
```

### Unsubscribe to event
To unsubscribe on an event use `unSubscribeEvent` method:

```js
this.chabok.unSubscribeEvent("EVENT_NAME");
```

For  unsubscribe to a single device use the other signature:

```js
this.chabok.unSubscribeEvent("EVENT_NAME", "INSTALLATION_ID");
```

### Getting event message
To get the EventMessage define `onEvent` method to  `addListener`:

```js
const chabokEmitter = new NativeEventEmitter(NativeModules.AdpPushClient);

chabokEmitter.addListener('onEvent', 
	(eventMsg) => {
		alert(JSON.stringify(eventMsg));
	}
);
```

### Track
To track user interactions  use `track` method :
```js
this.chabok.track('TRACK_NAME', [OBJECT]);
```

### Add tag
Adding tag in the Chabok have `addTag` and `addTags` methods:

```js
this.chabok.addTag('TAG_NAME')
    .then(res => {
        alert('This tag was assign to ' + this.chabok.getUserId() + ' user');
        })
    .catch(_ => console.warn("An error happend adding tag ...",_));
```

### Remove tag
Removing tag in the Chabok have `removeTag` and `removeTags` methods:

```js
this.chabok.removeTag('TAG_NAME')
    .then(res => {
        alert('This tag was removed from ' + this.chabok.getUserId() + ' user');
        })
    .catch(_ => console.warn("An error happend removing tag ..."));
```
