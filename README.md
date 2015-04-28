# MQTTClient
MQTTClient is an Objective-C wrapper for libmosquitto.  MQTTClient supports authentication and TLS encryption.  
MQTTClient has been tested with libmosquitto 1.4.1.  Download the latest libmosquitto here http://mosquitto.org/download/

# MQTTClient with TLS
Add MQTTClient.h and MQTTClient.m to your project.  

Add the libmosquitto source from the link above to your project.

Compile openssl for iOS using the instructions here https://github.com/x2on/OpenSSL-for-iPhone
Add the compiled openssl framework to your project.

Create certificates for client and server using 
  http://rockingdlabs.dunmire.org/exercises-experiments/ssl-client-certs-to-secure-mqtt

Add client.crt, client.key, and ca.crt to your project

Set a preprocessor flag in XCode "WITH_TLS" by clicking the project in XCode then click the target then click build settings
Search for preprocessor macros and add "WITH_TLS" to debug and release

Call init then connect then subscribe
```objc
-(id)initWithUsername:(NSString *)username password:(NSString *)password caCert:(NSString *)caCert clientCert:(NSString *)clientCert clientKey:(NSString *)clientKey;

-(void)connectToHost:(NSString *)host port:(int)port keepAlive:(int)keepAlive;

-(void)subscribeToTopic:(NSString *)topic;
```
# MQTTClient without TLS
Add MQTTClient.h and MQTTClient.m to your project.  
Add the libmosquitto source from the link above to your project.

Designate one of the objects as the MQTTClientDelegate
There is one required method 
```objc
-(void)messageReceived:(NSData *)messageData onTopic:(NSString *)topic;
```
Call init and then connect 
```objc
-(id)init;

-(id)initWithUsername:(NSString *)username password:(NSString *)password;

-(void)connectToHost:(NSString *)host port:(int)port keepAlive:(int)keepAlive;

-(void)subscribeToTopic:(NSString *)topic;
```
