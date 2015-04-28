//
//  MQTTClient.h
//  libmosquittotest
//
//  Created by Nicholas Wilkerson on 4/26/15.
//  Copyright (c) 2015 Nicholas Wilkerson. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MQTTClientDelegate <NSObject>
-(void)messageReceived:(NSData *)messageData onTopic:(NSString *)topic;

@optional
-(void)connected;
-(void)disconnected;
-(void)published;
-(void)subscribed;
-(void)unsubscribed;


@end

@interface MQTTClient : NSObject {
    struct mosquitto *mosq;
}

-(id)init;
-(id)initWithUsername:(NSString *)username password:(NSString *)password;
-(id)initWithCACert:(NSString *)caCert clientCert:(NSString *)clientCert clientKey:(NSString *)clientKey;
-(id)initWithUsername:(NSString *)username password:(NSString *)password caCert:(NSString *)caCert clientCert:(NSString *)clientCert clientKey:(NSString *)clientKey;

-(void)connectToHost:(NSString *)host port:(int)port keepAlive:(int)keepAlive;
-(void)disconnect;

-(void)subscribeToTopic:(NSString *)topic;
-(void)unsubscribeFromTopic:(NSString *)topic;

-(void)publishToTopic:(NSString *)topic withMessageData:(NSData *)messageData;
-(void)publishToTopic:(NSString *)topic withMessageString:(NSString *)messageString;

@property (weak) id <MQTTClientDelegate> delegate;

@end
