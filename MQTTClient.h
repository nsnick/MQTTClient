//
//  MQTTClient.h
//The MIT License (MIT)
//
//Copyright (c) 2015 Nick Wilkerson
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.



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
