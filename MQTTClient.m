//
//  MQTTClient.m
//
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


#define DEBUG 1
#import "MQTTClient.h"
#include "mosquitto.h"

@implementation MQTTClient

static MQTTClient *globalSelf;


void on_connect(struct mosquitto *mosq, void *userdata, int result)
{
    NSLog(@"on_connct");
    if(!result){
        if ([globalSelf.delegate respondsToSelector:@selector(connected)]) {
            [globalSelf.delegate connected];
        } else {
            NSLog(@"does not respond to connected");
        }
    }else{
        switch (result) {
            case 1:
                NSLog(@"MQTT: Connect Error unacceptable protocol version");
                break;
            case 2:
                NSLog(@"MQTT: Connect Error identifier rejected");
                break;
            case 3:
                NSLog(@"MQTT: Connect Error broker unavailable");
                break;
            default:
                break;
        }
    }
}

void on_disconnect(struct mosquitto *mosq, void *userdata, int result) {
    if ([globalSelf.delegate respondsToSelector:@selector(disconnected)]) {
        [globalSelf.delegate disconnected];
    }
    if (result) {
        [globalSelf printMosqErr:result];
    }
}

void on_subscribe(struct mosquitto *mosq, void *userdata, int mid, int qos_count, const int *granted_qos)
{
    if ([globalSelf.delegate respondsToSelector:@selector(subscribed)]) {
        [globalSelf.delegate subscribed];
    }
}

void on_unsubscribe(struct mosquitto *mosq, void *userdata, int mid) {
    if ([globalSelf.delegate respondsToSelector:@selector(unsubscribed)]) {
        [globalSelf.delegate unsubscribed];
    }
}

void on_publish(struct mosquitto *mosq, void *userdata, int result) {
    if ([globalSelf.delegate respondsToSelector:@selector(published)]) {
        [globalSelf.delegate published];
    }
    if (result) {
        [globalSelf printMosqErr:result];
    }
}

void on_message(struct mosquitto *mosq, void *userdata, const struct mosquitto_message *message)
{
    NSLog(@"message received");
    NSString *topic = [[NSString alloc] initWithCString:message->topic encoding:NSUTF8StringEncoding];
    NSData *messageData = [[NSData alloc] initWithBytes:message->payload length:message->payloadlen];
    [globalSelf.delegate messageReceived:messageData onTopic:topic];
}

void on_log(struct mosquitto *mosq, void *userdata, int level, const char *str)
{
    if (DEBUG) NSLog(@"MQTT Log: %s\n", str);
}

-(id)init {
    return [self initWithUsername:nil password:nil caCert:nil clientCert:nil clientKey:nil];
}

-(id)initWithUsername:(NSString *)username password:(NSString *)password {
    return [self initWithUsername:username password:password caCert:nil clientCert:nil clientKey:nil];
}

-(id)initWithCACert:(NSString *)caCert clientCert:(NSString *)clientCert clientKey:(NSString *)clientKey {
    return [self initWithUsername:nil password:nil caCert:caCert clientCert:clientCert clientKey:clientKey];
}

-(id)initWithUsername:(NSString *)username password:(NSString *)password caCert:(NSString *)caCert clientCert:(NSString *)clientCert clientKey:(NSString *)clientKey  {
    self = [super init];
    if (self) {
        globalSelf = self;
        bool clean_session = true;
        mosquitto_lib_init();
        mosq = NULL;
        mosq = mosquitto_new(NULL, clean_session, NULL);
        if(!mosq){
            NSLog(@"Error creating mosq");
        }
        if (username && password) {
            int mosqErr = mosquitto_username_pw_set(mosq, [username UTF8String], [password UTF8String]);
            if (mosqErr) {
                NSLog(@"MQTT: Error Setting Username or Password");
                [self printMosqErr:mosqErr];
            }
        }
        mosquitto_log_callback_set(mosq, on_log);
        mosquitto_connect_callback_set(mosq, on_connect);
        mosquitto_disconnect_callback_set(mosq, on_disconnect);
        mosquitto_subscribe_callback_set(mosq, on_subscribe);
        mosquitto_unsubscribe_callback_set(mosq, on_unsubscribe);
        mosquitto_publish_callback_set(mosq, on_publish);
        mosquitto_message_callback_set(mosq, on_message);

        if (caCert || clientCert || clientKey) {
            int mosqerr = mosquitto_tls_set(mosq, [[[NSBundle mainBundle] pathForResource:caCert ofType:nil] UTF8String], NULL, [[[NSBundle mainBundle] pathForResource:clientCert ofType:nil] UTF8String], [[[NSBundle mainBundle] pathForResource:clientKey ofType:nil] UTF8String], NULL);
            if (mosqerr) {
                NSLog(@"MOSQ: Error Setting TLS");
                [self printMosqErr:mosqerr];
            }
        }
        
    }
    return self;
}

-(void)connectToHost:(NSString *)host port:(int)port keepAlive:(int)keepAlive {
    int mosqErr;
    if((mosqErr = mosquitto_connect(mosq, [host UTF8String], port, keepAlive)) != 0){
        NSLog(@"Unable to Connect");
        [self printMosqErr:mosqErr];
    }
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        while(!mosquitto_loop(mosq, -1, 1)){
        }
        NSLog(@"destroying mosq");
        mosquitto_destroy(mosq);
        mosquitto_lib_cleanup();
    });
}

-(void)disconnect {
    mosquitto_disconnect(mosq);
}

-(void)subscribeToTopic:(NSString *)topic {
    int mosqErr = mosquitto_subscribe(mosq, NULL, [topic UTF8String], 2);
    if (mosqErr) {
        NSLog(@"Error Subscribing to Topic: %@", topic);
        [self printMosqErr:mosqErr];
    }
}

-(void)unsubscribeFromTopic:(NSString *)topic {
    int mosqErr = mosquitto_unsubscribe(mosq, NULL, [topic UTF8String]);
    if (mosqErr) {
        NSLog(@"Error Unsubscribing from Topic: %@", topic);
        [self printMosqErr:mosqErr];
    }
}

-(void)publishToTopic:(NSString *)topic withMessageData:(NSData *)messageData {
    int mosqErr = mosquitto_publish(mosq, NULL, [topic UTF8String], [messageData length], [messageData bytes], 1, true);
    if (mosqErr) {
        NSLog(@"Error Publishing to Topic: %@", topic);
        [self printMosqErr:mosqErr];
    }
}

-(void)publishToTopic:(NSString *)topic withMessageString:(NSString *)messageString {
    int mosqErr = mosquitto_publish(mosq, NULL, [topic UTF8String], [messageString length], [messageString UTF8String], 1, true);
    if (mosqErr) {
        NSLog(@"Error Publishing to Topic: %@", topic);
        [self printMosqErr:mosqErr];
    }
}


-(void)printMosqErr:(int)err {
    switch (err) {
        case MOSQ_ERR_CONN_PENDING:
            NSLog(@"MQTT: MOSQ_ERR_CONN_PENDING");
            break;
        case MOSQ_ERR_NOMEM:
            NSLog(@"MQTT: MOSQ_ERR_NOMEM");
            break;
        case MOSQ_ERR_PROTOCOL:
            NSLog(@"MQTT: MOSQ_ERR_PROTOCOL");
            break;
        case MOSQ_ERR_INVAL:
            NSLog(@"MQTT: MOSQ_ERR_INVAL");
            break;
        case MOSQ_ERR_NO_CONN:
            NSLog(@"MQTT: MOSQ_ERR_NO_CONN");
            break;
        case MOSQ_ERR_CONN_REFUSED:
            NSLog(@"MQTT: MOSQ_ERR_CONN_REFUSED");
            break;
        case MOSQ_ERR_NOT_FOUND:
            NSLog(@"MQTT: MOSQ_ERR_NOT_FOUND");
            break;
        case MOSQ_ERR_CONN_LOST:
            NSLog(@"MQTT: MOSQ_ERR_CONN_LOST");
            break;
        case MOSQ_ERR_TLS:
            NSLog(@"MQTT: MOSQ_ERR_TLS");
            break;
        case MOSQ_ERR_PAYLOAD_SIZE:
            NSLog(@"MQTT: MOSQ_ERR_PAYLOAD_SIZE");
            break;
        case MOSQ_ERR_NOT_SUPPORTED:
            NSLog(@"MQTT: MOSQ_ERR_NOT_SUPPORTED");
            break;
        case MOSQ_ERR_AUTH:
            NSLog(@"MQTT: MOSQ_ERR_AUTH");
            break;
        case MOSQ_ERR_ACL_DENIED:
            NSLog(@"MQTT: MOSQ_ERR_ACL_DENIED");
            break;
        case MOSQ_ERR_UNKNOWN:
            NSLog(@"MQTT: MOSQ_ERR_UNKNOWN");
            break;
        case MOSQ_ERR_ERRNO:
            NSLog(@"MQTT: MOSQ_ERR_ERRNO: %s", strerror(errno));
            break;
        case MOSQ_ERR_EAI:
            NSLog(@"MQTT: MOSQ_ERR_EAI");
            break;
        default:
            break;
    }
}


@end
