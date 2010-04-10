//
//  TCServer.h
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDictionary+BSJSONAdditions.h"
#import "NSScanner+BSJSONAdditions.h"
#import "CocoaCryptoHashing.h"

@interface TCServer : NSObject {
	id _delegate;
	
	bool activeConnection;
	NSString *serverAddress;
	NSString *port;
	NSString *suffix;
	NSString *protocolVersion;
	NSArray *extensions;
	
	bool requiresPassword;
	NSString *authKey;
	bool supportsArtwork;
	
	NSString *serverIdentifier;
	
	NSString *urlString;
	NSMutableDictionary *responses;
	NSMutableDictionary *requests;
	NSMutableDictionary *properties;
	
	int connectionsRunning;
}

- (id)init;
- (id)initWithAddress:(NSString *)address andPort:(NSString *)port;
- (void)dealloc;
+ (id)connectionWithAddress:(NSString *)address andPort:(NSString *)port;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSString *)cIDForConnection:(NSURLConnection *)theConnection;

- (void)openConnection;
- (void)closeConnection;
- (bool)activeConnection;

- (NSString *)identifier;
- (void)setIdentifier:(NSString *)identifier;

- (void)setAddress:(NSString *)address;
- (NSString *)address;
- (void)setPort:(NSString *)thePort;
- (NSString *)port;
- (void)setAddress:(NSString *)address andPort:(NSString *)thePort;

- (NSString *)serverAddress;
- (NSString *)composeURLForCommand:(NSString *)command withParams:(NSDictionary *)params;

- (void)processServerInfo:(NSDictionary *)serverInfo;
- (void)doRawCommand:(NSString *)command;
- (void)doRawCommand:(NSString *)command withParams:(NSDictionary *)params;
- (void)doRawCommand:(NSString *)command withParams:(NSDictionary *)params callingMethod:(SEL)methodSelector ofObject:(id)receivingObject;

- (void)doCommand:(NSString *)command;
- (void)doCommand:(NSString *)command withParams:(NSDictionary *)params;
- (void)doCommand:(NSString *)command withParams:(NSDictionary *)params callingMethod:(SEL)methodSelector ofObject:(id)receivingObject;

- (void)doServerCommand:(NSString *)command withParams:(NSDictionary *)params callingMethod:(SEL)methodSelector ofObject:(id)receivingObject withRawData:(bool)doRaw;

- (void)getAuthKeyForPassword:(NSString *)password;

- (void)startConnection;
- (void)stopConnection;

- (void)doNothing:(NSDictionary *)response;
- (void)handleAuthKey:(NSDictionary *)response;

- (bool)supportsExtension:(NSString *)extensionName;

@end

@interface NSObject (TCServerDelegate)

- (void)serverReady:(TCServer *)theServer;
- (void)serverNeedsAuthentication:(TCServer *)theServer;
- (void)serverConnectionError:(NSError *)error;
- (void)badServerVersion:(NSString *)badVersion requires:(NSString *)requiredVersion;

- (void)connectionStatusChanged:(int)connections;

@end