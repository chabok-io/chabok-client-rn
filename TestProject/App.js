/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React from 'react';
import {Platform, Linking, StyleSheet, Button, Text, View, TextInput, NativeEventEmitter, NativeModules, ScrollView} from 'react-native';
import chabok from 'react-native-chabok';

export default class App extends React.Component {

    constructor() {
        super();

        this.state = {
            tagName: '',
            userId: undefined,
            channel: undefined,
            attributeKey: undefined,
            attributeValue: undefined,
            connectionColor: 'red',
            messageReceived: undefined,
            connectionState: 'Disconnected',
            messageBody: 'Hello world Message'
        };
    }

    componentDidMount() {
        this.initChabok();

        Linking.getInitialURL().then((url) => {
            console.log('getInitialURL = ', url);

            if (url) {
                this.handleOpenURL({ url });
            }
        });
        if (Platform.OS === 'ios') {
            Linking.addEventListener('url', this.handleOpenURL.bind(this));
        }
    }

    componentWillUnmount() {
        Linking.removeEventListener('url', this.handleOpenURL);
    }

    initChabok() {
        this.chabok = new chabok.AdpPushClient();
        // this.chabok.setDefaultTracker('jtMMkQ');

        this.chabok.setDeeplinkCallbackListener(deepLink => {
            console.log('deep link = ' + deepLink);
            alert('deep link = ' + deepLink);
        });

        this.chabok.setReferralCallbackListener(referralId => {
            console.log('referralId = ' + referralId);
            alert('referralId = ' + referralId);
        });

        const chabokEmitter = new NativeEventEmitter(NativeModules.AdpPushClient);
        
        chabokEmitter.removeAllListeners('onSubscribe');
        chabokEmitter.removeAllListeners('onUnsubscribe');
        chabokEmitter.removeAllListeners('connectionStatus');
        chabokEmitter.removeAllListeners('ChabokMessageReceived');
        chabokEmitter.removeAllListeners('onEvent');
        chabokEmitter.removeAllListeners('notificationOpened');

        chabokEmitter.addListener('onSubscribe',
            (channel) => {
                console.log('Subscribe on : ', channel);
                alert('Subscribe on ' + channel.name);
            });

        chabokEmitter.addListener('onUnsubscribe',
            (channel) => {
                console.log('Unsubscribe on : ', channel);
                alert('Unsubscribe on ' + channel.name);
            });

        chabokEmitter.addListener('connectionStatus',
            (status) => {
                let connectionColor = 'red';
                let connectionState = 'error';

                if (status === 'CONNECTED') {
                    connectionColor = 'green';
                    connectionState = 'Connected';
                } else if (status === 'CONNECTING') {
                    connectionColor = 'yellow';
                    connectionState = 'Connecting';
                } else if (status === 'DISCONNECTED') {
                    connectionColor = 'red';
                    connectionState = 'Disconnected';
                }

                this.setState({
                    connectionColor,
                    connectionState
                });
            }
        );

        chabokEmitter.addListener('ChabokMessageReceived',
            (msg) => {
                console.log('ChabokMessageReceived: ' + msg);
                alert('ChabokMessageReceived: ' + msg);
                const messageJson = this.getMessages() + JSON.stringify(msg);
                this.setState({messageReceived: messageJson});
            }
        );

        chabokEmitter.addListener('onEvent',
            (eventMsg) => {
                console.log('onEvent ' + eventMsg);
                alert('onEvent ' + eventMsg);
                const eventMessageJson = this.getEventMessage() + JSON.stringify(eventMsg);
                this.setState({eventMessage: eventMessageJson});
            }
        );

        chabokEmitter.addListener(
            'notificationOpened',
            (msg) => {
                console.log(msg);

                if (msg.actionType === 'opened') {
                    console.log("Notification opened by user");
                    alert('Notification opened by user');
                } else if (msg.actionType === 'dismissed') {
                    console.log("Notification dismissed by user");
                    alert('Notification dismissed by user');
                } else if (msg.actionType === 'action_taken') {
                    console.log("User tapped on notification ");
                    alert('User tapped on notification ' + msg.actionId + ' action');
                }

                if (msg.actionUrl) {
                    console.log("Got deep link (", msg.actionUrl, ")");
                    alert('Got deep link (' + msg.actionUrl + ')');
                }
            }
        );
    }

    handleOpenURL(event) {
        console.log("Got deep-link url = ", event.url);
        alert('Got deep-link url = ' + event.url);
        const route = event.url.replace(/.*?:\/\//g, '');
        // do something with the url, in our case navigate(route)

        if (event && event.url) {
            this.chabok.appWillOpenUrl(event.url);
        }
    }

    //  ----------------- Register Group -----------------
    onRegisterTapped() {
        const {userId} = this.state;
        if (userId) {
            this.chabok.login(userId);
        } else {
            console.warn('The userId is undefined');
        }
    }
    onUnregisterTapped() {
        this.chabok.logout();
    }
    onSubscribeTapped() {
        if (this.state.channel) {
            this.chabok.subscribe(this.state.channel);
        } else {
            console.warn('The channel name is undefined');
        }
    }
    onUnsubscribeTapped() {
        if (this.state.channel) {
            this.chabok.unSubscribe(this.state.channel);
        } else {
            console.warn('The channel name is undefined');
        }
    }
    onSetAttributesTapped() {
        const attrs = {
            'firstname': 'Farbod',
            'lastname': 'Samsamipour',
            'age': 28,
            'isCool': true,
            'birthday': new Date()
        };
        this.chabok.setUserAttributes(attrs);
    }

    // ----------------- Publish Group -----------------
    onPublishTapped() {
        const msg = {
            channel: "default",
            user: this.state.userId,
            content: this.state.messageBody || 'Hello world'
        };
        this.chabok.publish(msg)
    }
    onPublishEventTapped() {
        this.chabok.publishEvent('batteryStatus', {state: 'charging'});
    }

  //  ----------------- Tag Group -----------------
  onAddTagTapped() {
        if (this.state.tagName) {
            this.chabok.addTag(this.state.tagName)
                .then(({count}) => {
                    alert(this.state.tagName + ' tag was assign to ' + this.getUserId() + ' user with '+ count + ' devices');
                })
                .catch(_ => console.warn("An error happend adding tag ..."));
        } else {
            console.warn('The tagName is undefined');
        }
    }
    onRemoveTagTapped() {
        if (this.state.tagName) {
            this.chabok.removeTag(this.state.tagName)
                .then(({count}) => {
                    alert(this.state.tagName + ' tag was removed from ' + this.getUserId() + ' user with '+ count + ' devices');
                })
                .catch(_ => console.warn("An error happend removing tag ..."));
        } else {
            console.warn('The tagName is undefined');
        }
    }

  //  ----------------- Track Group -----------------
    onAddToCartTrackTapped() {
        this.chabok.track('AddToCard', {order: '200', 'buyDate': new Date()});
    }
    onPurchaseTrackTapped() {
        this.chabok.trackPurchase('Purchase', {revenue: '15000', data: {'purchaseDatetime': new Date(), 'offPrice': true}});
    }
    onCommentTrackTapped() {
        this.chabok.track('Comment', {postId: '1234555677754d', 'commentDate': new Date()});
    }
    onLikeTrackTapped() {
        this.chabok.track('Like', {postId: '1234555677754d', 'likeDate': new Date()});
    }

    getUserId() {
        return this.state.userId || ''
    }

    getAttributeKey() {
        return this.state.attributeKey || ''
    }

    getAttributeValue() {
        return this.state.attributeValue || ''
    }

    getMessages() {
        if (this.state.messageReceived) {
            return this.state.messageReceived + '\n --------- \n\n';
        }
        return '';
    }

    getTagName() {
        return this.state.tagName || '';
    }

    getMessageBody() {
        return this.state.messageBody || '';
    }

    onAddToArrayTapped() {
        this.chabok.addToUserAttributeArray(this.state.attributeKey, this.state.attributeValue);
    }
    
    onRemoveFromArrayTapped() {
        this.chabok.removeFromUserAttributeArray(this.state.attributeKey, this.state.attributeValue);
    }
    
    onUnsetTapped() {
        this.chabok.unsetUserAttribute(this.state.attributeKey);
    }

    render() {
        return (
            <View style={styles.container}>
                <View style={styles.nestedButtonView} marginTop={-10}>
                    <View style={styles.circleView} backgroundColor={this.state.connectionColor}/>
                    <Text>{this.state.connectionState}</Text>
                </View>
                <View style={styles.nestedButtonView}>
                    <TextInput
                        style={styles.input}
                        placeholder="User id"
                        width="60%"
                        onChangeText={userId => this.setState({userId})}>{this.getUserId()}</TextInput>
                    <TextInput
                        style={styles.input}
                        width="40%"
                        placeholder="Channel name"
                        onChangeText={channel => this.setState({channel})}/>
                </View>

                <View style={styles.nestedButtonView}>
                    <Button
                        style={styles.button}
                        title="Login"
                        onPress={this.onRegisterTapped.bind(this)}/>
                    <Button
                        style={styles.button}
                        title="Logout"
                        onPress={this.onUnregisterTapped.bind(this)}/>
                    <Button
                        style={styles.button}
                        title="Sub"
                        onPress={this.onSubscribeTapped.bind(this)}/>
                    <Button
                        style={styles.button}
                        title="Unsub"
                        onPress={this.onUnsubscribeTapped.bind(this)}/>
                    <Button
                        style={styles.button}
                        title="Attr"
                        onPress={this.onSetAttributesTapped.bind(this)}/>
                </View>

                <View style={styles.nestedButtonView}>
                    <TextInput
                        style={styles.input}
                        onChangeText={messageBody => this.setState({messageBody})}
                        width="100%">{this.getMessageBody()}</TextInput>
                </View>
                <View style={styles.nestedButtonView}>
                    <Button
                        style={styles.button}
                        title="Publish"
                        onPress={this.onPublishTapped.bind(this)}/>
                    <Button
                        style={styles.button}
                        title="PublishEvent"
                        onPress={this.onPublishEventTapped.bind(this)}/>
                </View>
                <View style={styles.nestedButtonView}>
                    <TextInput
                        style={styles.input}
                        placeholder='Tag name'
                        onChangeText={tagName => this.setState({tagName})}
                        width='100%'>{this.getTagName()}</TextInput>
                </View>
                <View style={styles.nestedButtonView}>
                    <Button
                        style={styles.button}
                        title="AddTag"
                        onPress={this.onAddTagTapped.bind(this)}/>
                    <Button
                        style={styles.button}
                        title="RemoveTag"
                        onPress={this.onRemoveTagTapped.bind(this)}/>
                </View>
                <View style={styles.nestedButtonView}>
                    <Text>Track user: </Text>
                </View>
                <View style={styles.nestedButtonView}>
                    <Button style={styles.button} title="AddToCart" onPress={this.onAddToCartTrackTapped.bind(this)}/>
                    <Button style={styles.button} title="Purchase"  onPress={this.onPurchaseTrackTapped.bind(this)}/>
                    <Button style={styles.button} title="Comment"   onPress={this.onCommentTrackTapped.bind(this)}/>
                    <Button style={styles.button} title="Like"      onPress={this.onLikeTrackTapped.bind(this)}/>
                </View>
                <View style={styles.nestedButtonView}>
                    <TextInput
                        style={styles.input}
                        placeholder="attribute key"
                        width="50%"
                        onChangeText={attributeKey => this.setState({attributeKey})}>{this.getAttributeKey()}</TextInput>
                    <TextInput
                        style={styles.input}
                        placeholder="attribute value"
                        width="50%"
                        onChangeText={attributeValue => this.setState({attributeValue})}>{this.getAttributeValue()}</TextInput>
                </View>
                <View style={styles.nestedButtonView}>
                    <Button style={styles.button} title="AddToArray" onPress={this.onAddToArrayTapped.bind(this)}/>
                    <Button style={styles.button} title="RemoveFromArray"  onPress={this.onRemoveFromArrayTapped.bind(this)}/>
                    <Button style={styles.button} title="Unset"   onPress={this.onUnsetTapped.bind(this)}/>
                </View>
                <View>
                    <ScrollView>
                        <Text style={styles.textView}>{this.getMessages()}</Text>
                    </ScrollView>
                </View>
            </View>
        );
    }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        paddingTop: 50,
        paddingRight: 12,
        paddingLeft: 12,
        paddingBottom: 12,
        width: '100%',
    },
    nestedButtonView: {
        flexDirection: 'row',
        alignItems: 'center'
    },
    circleView:{
        width: 15,
        height: 15,
        borderRadius: 8,
        marginTop: 10,
        marginBottom: 10,
        marginRight: 10,
        marginLeft: 4
    },
    button: {
        padding: 2,
        marginLeft: 2,
        marginRight: 2
    },
    textView:{
      borderColor: 'rgba(127,127,127,0.3)',
        backgroundColor: 'rgba(127,127,127,0.06)',
        width: '100%',
        height: '70%',
    },
    input: {
        padding: 4,
        height: 40,
        borderColor: 'rgba(127,127,127,0.3)',
        borderWidth: 1,
        borderRadius: 4,
        marginBottom: 0,
        marginRight: 5,
        marginLeft: 0
    }
});