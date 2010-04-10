//
//  TCServer.m
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TCServer.h"


@implementation TCServer

- (id)init
{
	return [self initWithAddress:nil andPort:nil];
}

- (id)initWithAddress:(NSString *)address andPort:(NSString *)thePort
{
	if (self = [super init])
	{
		responses = [[NSMutableDictionary alloc] init];
		requests = [[NSMutableDictionary alloc] init];
		properties = [[NSMutableDictionary alloc] init];
		
		serverIdentifier = [[NSString alloc] init];
		
		if (address != nil)
		{
			[self setAddress:address andPort:thePort];
		}
		
		connectionsRunning = 0;
	}
	
	return self;
}

- (void)dealloc
{
	[requests release];
	[responses release];
	[properties release];
	
	[serverAddress release];
	[port release];
	if (suffix) [suffix release];
	if (protocolVersion) [protocolVersion release];
	if (authKey) [authKey release];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
    if (_delegate)
        [nc removeObserver:_delegate name:nil object:self];
	
	[super dealloc];
}

+ (id)connectionWithAddress:(NSString *)address andPort:(NSString *)port
{
	return [[[TCServer alloc] initWithAddress:address andPort:port] autorelease];
}


- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)newDelegate
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
    if (_delegate)
        [nc removeObserver:_delegate name:nil object:self];
		
    _delegate = newDelegate;
    
    // repeat  the following for each notification
    /*if ([_delegate respondsToSelector:@selector(ourNotifName:)])
        [nc addObserver:_delegate selector:@selector(ourNotifName:)
            name:OurClassourNotifNameNotification object:self];*/
}

- (void)openConnection
{
	NSLog(@"Opening connection to %@", [self serverAddress]);
	[self doCommand:@"serverInfo.txt" withParams:nil callingMethod:@selector(processServerInfo:) ofObject:self];
}

- (void)closeConnection
{
	activeConnection = NO;
}

- (bool)activeConnection
{
	return activeConnection;
}

- (NSString *)identifier
{
	return serverIdentifier;
}
- (void)setIdentifier:(NSString *)identifier
{
	[serverIdentifier release];
	serverIdentifier = [identifier copy];
}

- (void)setAddress:(NSString *)address
{
	serverAddress = [address copy];
}

- (NSString *)address
{
	return serverAddress;
}

- (void)setPort:(NSString *)thePort
{
	port = [thePort copy];
}

- (NSString *)port
{
	return port;
}

- (void)setAddress:(NSString *)address andPort:(NSString *)thePort
{
	[self setAddress:address];
	[self setPort:thePort];
	
	[self setIdentifier:[self serverAddress]];
}

- (NSString *)serverAddress
{
	return [NSString stringWithFormat:@"http://%@:%@/", serverAddress, port];
}

- (NSString *)composeURLForCommand:(NSString *)command withParams:(NSDictionary *)params
{
	urlString = [NSString stringWithFormat:@"%@%@", [self serverAddress], command];
	
	//if (suffix != nil) urlString = [urlString stringByAppendingString:suffix];
	
	if (requiresPassword && authKey != nil)
	{
		NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
		
		if (params != nil)
		{
			[tempDict setDictionary:params];
		}
		
		[tempDict setValue:authKey forKey:@"authKey"];
		
		params = [tempDict autorelease];
	}
	
	if (params != nil)
	{
		// Add the parameters
		urlString = [urlString stringByAppendingString:@"?"];
		
		NSMutableArray *components = [NSMutableArray arrayWithCapacity:1];
		
		NSArray *keys = [params allKeys];
		
		NSEnumerator *enumerator = [keys objectEnumerator];
		id key;
		
		while ( key = [enumerator nextObject] )
		{
			[components addObject:[NSString stringWithFormat:@"%@=%@", key, [params valueForKey:key]]];
			//[components addObject:[[key stringByAppendingString:@"="] stringByAppendingString:[params valueForKey:key]]];
		}
		
		urlString = [urlString stringByAppendingString:[components componentsJoinedByString:@"&"]];
	}
	return urlString;
}

- (void)processServerInfo:(NSDictionary *)serverInfo
{
	NSLog(@"Connection went active!");
	protocolVersion = [[[serverInfo valueForKey:@"version"] stringValue] retain];
	suffix = [[serverInfo valueForKey:@"suffix"] retain];
	requiresPassword = [[serverInfo valueForKey:@"requiresPassword"] boolValue];
	supportsArtwork = [[serverInfo valueForKey:@"supportsArtwork"] boolValue];
	extensions = [[serverInfo valueForKey:@"extensions"] retain];
	
	if ([[serverInfo valueForKey:@"version"] floatValue] < 1.1)
	{
		if ([_delegate respondsToSelector:@selector(badServerVersion:requires:)])
			[_delegate badServerVersion:protocolVersion requires:@"1.1"];
		return;
	}
	
	if (requiresPassword)
	{
		if ([_delegate respondsToSelector:@selector(serverNeedsAuthentication:)])
			[_delegate serverNeedsAuthentication:self];
	}
	else
	{
		activeConnection = YES;
		
		if ([_delegate respondsToSelector:@selector(serverReady:)])
			[_delegate serverReady:self];
	}	
}

- (void)doRawCommand:(NSString *)command
{
	[self doRawCommand:command withParams:nil callingMethod:nil ofObject:nil];
}

- (void)doRawCommand:(NSString *)command withParams:(NSDictionary *)params
{
	[self doRawCommand:command withParams:params callingMethod:nil ofObject:nil];
}

- (void)doRawCommand:(NSString *)command withParams:(NSDictionary *)params callingMethod:(SEL)methodSelector ofObject:(id)receivingObject
{
	[self doServerCommand:command withParams:params callingMethod:methodSelector ofObject:receivingObject withRawData:YES];
}

- (void)doCommand:(NSString *)command
{
	[self doCommand:command withParams:nil callingMethod:nil ofObject:nil];
}

- (void)doCommand:(NSString *)command withParams:(NSDictionary *)params
{
	[self doCommand:command withParams:params callingMethod:nil ofObject:nil];
}

- (void)doCommand:(NSString *)command withParams:(NSDictionary *)params callingMethod:(SEL)methodSelector ofObject:(id)receivingObject
{
	[self doServerCommand:command withParams:params callingMethod:methodSelector ofObject:receivingObject withRawData:NO];
}

- (void)doServerCommand:(NSString *)command withParams:(NSDictionary *)params callingMethod:(SEL)methodSelector ofObject:(id)receivingObject withRawData:(bool)doRaw
{
	urlString = [self composeURLForCommand:command withParams:params];
	
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                        cachePolicy:NSURLRequestUseProtocolCachePolicy
					timeoutInterval:60.0];
	
	//NSLog(@"Calling %@", urlString);
	
	NSString *connectionID = [NSString stringWithFormat:@"%@##%@", urlString, [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S:%F" timeZone:nil locale:nil]];
	
	NSInvocation *responseInvocation;
	
	if (methodSelector == nil)
	{
		methodSelector = @selector(doNothing:);
		receivingObject = self;
	}
	
	if (methodSelector != nil)
	{
		NSMethodSignature *sig = [[receivingObject class] instanceMethodSignatureForSelector:methodSelector];
		responseInvocation = [NSInvocation invocationWithMethodSignature:sig];
		[responseInvocation setTarget:receivingObject];
		[responseInvocation setSelector:methodSelector];
	}
	
	[self startConnection];
	
	//NSLog(@"Init-ing NSURLConnection to %@", urlString);
	NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	
	if (theConnection)
	{
		[requests setObject:theConnection forKey:connectionID];
		[responses setObject:[[NSMutableData alloc] init] forKey:connectionID];
		[properties setObject:[[NSDictionary alloc] initWithObjectsAndKeys:responseInvocation, @"invocation", [NSNumber numberWithBool:doRaw], @"doRaw", nil] forKey:connectionID];
		//myData = [[NSMutableData data] retain];
	}
	else
	{
		// There was an error!
		NSLog(@"Danger, danger Will Robinson!");
	}
}

- (NSString *)cIDForConnection:(NSURLConnection *)theConnection
{
	return [[requests allKeysForObject:theConnection] objectAtIndex:0];
}

- (void)getAuthKeyForPassword:(NSString *)password
{
	password = [password sha1HexHash];
	[self doCommand:@"getAuthKey" withParams:[NSDictionary dictionaryWithObjectsAndKeys:password, @"password", nil] callingMethod:@selector(handleAuthKey:) ofObject:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSString *cID = [self cIDForConnection:connection];
	//NSLog(@"Response received: %@", cID);
	[[responses objectForKey:cID] setLength:0];
	//[myData setLength:0];
	//[responses setValue:data forKey:[connection cID]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSString *cID = [self cIDForConnection:connection];
	//NSLog(@"Data for: %@", cID);
	[[responses objectForKey:cID] appendData:data];
	//[myData appendData:data];
	//[responses setValue:oldData forKey:[connection cID]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self stopConnection];
	
	NSString *cID = [self cIDForConnection:connection];
	
	[[responses objectForKey:cID] release];
	[responses removeObjectForKey:cID];
	
	[[properties objectForKey:cID] release];
	[properties removeObjectForKey:cID];
	
	[requests removeObjectForKey:cID];
	//[myData release];
	[connection release];
	
	NSLog(@"Uh oh, an error: %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	
	if ([_delegate respondsToSelector:@selector(serverConnectionError:)])
			[_delegate serverConnectionError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *cID = [self cIDForConnection:connection];
	//NSLog(@"Success for: %@", cID);

	NSDictionary *theUserInfo;
	
	if ([[[properties objectForKey:cID] objectForKey:@"doRaw"] boolValue])
	{
		theUserInfo = [NSDictionary dictionaryWithObject:[responses objectForKey:cID] forKey:@"data"];
		//theUserInfo = [NSDictionary dictionaryWithObject:myData forKey:@"data"];
	}
	else
	{
		NSString *dataAsString = [[NSString alloc] initWithData:[responses objectForKey:cID] encoding:NSUTF8StringEncoding];
		theUserInfo = [NSDictionary dictionaryWithJSONString:dataAsString];
		[dataAsString release];
	}
	
	NSInvocation *completionInvocation = [[properties objectForKey:cID] objectForKey:@"invocation"];
	
	// invoke the completion invocation
	[completionInvocation setArgument:&theUserInfo atIndex:2];
	[completionInvocation invoke];
	//[[NSNotificationCenter defaultCenter] postNotificationName:[connection notificationToPost] object:self userInfo:theUserInfo];
	
	[self stopConnection];
	
	[[responses objectForKey:cID] release];
	[responses removeObjectForKey:cID];
	
	[[properties objectForKey:cID] release];
	[properties removeObjectForKey:cID];
	
	[requests removeObjectForKey:cID];
	//[myData release];
	[connection release];
}

- (void)startConnection
{
	connectionsRunning++;
	if ([_delegate respondsToSelector:@selector(connectionStatusChanged:)])
		[_delegate connectionStatusChanged:connectionsRunning];
}

- (void)stopConnection
{
	connectionsRunning--;
	if ([_delegate respondsToSelector:@selector(connectionStatusChanged:)])
		[_delegate connectionStatusChanged:connectionsRunning];
}

- (void)doNothing:(NSDictionary *)response
{
	// This is a filler method for requests to nowhere
}

- (void)handleAuthKey:(NSDictionary *)response
{
	id newAuthKey = [response valueForKey:@"authKey"];
	
	if ([newAuthKey isKindOfClass:[NSNumber class]] && [newAuthKey boolValue] == NO)
	{
		NSLog(@"Wrong password, try again.");
		
		if ([_delegate respondsToSelector:@selector(serverNeedsAuthentication:)])
			[_delegate serverNeedsAuthentication:self];
	}
	else
	{
		authKey = [newAuthKey copy];
		activeConnection = YES;
		
		if ([_delegate respondsToSelector:@selector(serverReady:)])
			[_delegate serverReady:self];
	}
}

- (bool)supportsExtension:(NSString *)extensionName
{
	return [extensions containsObject:extensionName];
}

@end
