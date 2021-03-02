# Table of contents:
* [Project Notes](#project-notes)
* [Android contributing instructions:](#android-contributing-instructions)
    - [Notes](#notes)
    - [Update Android native SDK](#update-android-native-sdk)
    - [Without any breaking changes](#without-any-breaking-changes)
    - [With breaking changes](#with-breaking-changes)
* [iOS contributing instructions:](#ios-contributing-instructions)
    - [Notes](#notes-1)
    - [Update iOS native SDK](#update-ios-native-sdk)
    - [Without any breaking changes](#without-any-breaking-changes-1)
    - [With breaking changes](#with-breaking-changes-1)


## Project Notes
1) For developing in this project use **WebStorm** IDE. This is the best IDE and more compatible with React-Native platform.

2) All js module codes are in `chabok-client-rn/lib` path. After applied changes in the native modules, Don't forget apply them on the js module if need.

3) SDK initialization should be in native side for each platform. For example: iOS users should call `configureEnvironment` method from native SDK in `AppDelegate.m` class.

## Android contributing instructions:

### Notes:
1) For developing Android native bridge use **Android Studio** IDE.

2) Never change the `ChabokReactPackage` class. When this class may change you need to support for specific version on the React-Native. Their breaking changes always affects of this module.

3) React-Native has any two-way communication channel from the native module to js module and conversely. You have a one-way communication service by calling `emit` method.

4) For running project on android device follow the instruction:

```
 npm run android
```

### Update Android native SDK:
All Chabok libraries follow the semantic versioning.

#### Without any breaking changes:
If it hasn't any breaking changes follow this instruction:

```
cd react-native-rn/android

vi build.gradle
```

Just change Chabok Android SDK Version:

from:
```
 api 'com.adpdigital.push:chabok-lib:3.4.0'
``` 
to:
```
 api 'com.adpdigital.push:chabok-lib:3.6.0'
```

#### With breaking changes
If it has some breaking changes first follow the above instruction. After that if breaking changes includes code changes, don't forget apply all changes in `ChabokPushModule.java` bridge class.
The `ChabokPushModule` is a simple bridge for connect the native module and js module.

## iOS contributing instructions:

### Notes:
1) For developing iOS native bridge use **Xcode** IDE. Open project from `react-native-rn/ios` path.

2) For testing iOS bridge you should use `cocoapods` with `1.7.5` version.

3) For running project on iOS device follow the instruction:

```
 cd ios
 pod install

 cd ..
 npm run ios
```

### Update iOS native SDK:
All Chabok libraries follow the semantic versioning.

#### Without any breaking changes:
If it hasn't any breaking changes follow this instruction:

```
cd react-native-rn

vi react-native-chabok.podspec
```

Just change Chabok iOS SDK Version:

from:
```
 s.dependency "ChabokPush", "~> 2.2.0"
``` 
to:
```
 s.dependency "ChabokPush", "~> 2.4.0"
```

And copy last version of iOS framework into the `react-native-rn/ios/frameworks`:

#### With breaking changes
If it has some breaking changes first follow the above instruction. After that if breaking changes includes code changes, don't forget apply all changes in `ChabokPush.m` bridge class.
The `ChabokPush` is a simple bridge for connect the native module and js module.
