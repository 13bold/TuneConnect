//
//  LFResponder.m
//  Last.fm
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LFResponder.h"


@implementation LFResponder

- (id)initWithController:(id)newController
{
	if (self = [super init])
	{
		controller = newController;
		
		responses = [[NSMutableDictionary alloc] init];
		requests = [[NSMutableDictionary alloc] init];
		properties = [[NSMutableDictionary alloc] init];
		rObjects = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)beginConnectionWithRequest:(NSURLRequest *)request withTarget:(id)target selector:(SEL)selector
{
	NSString *connectionID = [NSString stringWithFormat:@"%@##%@", [[request URL] absoluteString], [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S:%F" timeZone:nil locale:nil]];
	NSInvocation *responseInvocation = nil;
	
	if (target != nil && selector != nil)
	{
		NSMethodSignature *sig = [[target class] instanceMethodSignatureForSelector:selector];
		responseInvocation = [NSInvocation invocationWithMethodSignature:sig];
		[responseInvocation setTarget:target];
		[responseInvocation setSelector:selector];
	}
	else
	{
		NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:@selector(doNothing:)];
		responseInvocation = [NSInvocation invocationWithMethodSignature:sig];
		[responseInvocation setTarget:self];
		[responseInvocation setSelector:@selector(doNothing:)];
	}
	
	NSURLConnection *theConnection = [NSURLConnection connectionWithRequest:request delegate:self];
	
	[rObjects setObject:request forKey:connectionID];
	[requests setObject:theConnection forKey:connectionID];
	[responses setObject:[[[NSMutableData alloc] init] autorelease] forKey:connectionID];
	[properties setObject:[[[NSDictionary alloc] initWithObjectsAndKeys:responseInvocation, @"invocation", nil] autorelease] forKey:connectionID];
}

- (NSString *)cIDForConnection:(NSURLConnection *)theConnection
{
	return [[requests allKeysForObject:theConnection] objectAtIndex:0];
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
	NSString *cID = [self cIDForConnection:connection];
	
	[controller _connectionFailedOnRequest:[rObjects objectForKey:cID]];
	
	[responses removeObjectForKey:cID];
	[properties removeObjectForKey:cID];
	[requests removeObjectForKey:cID];
	[rObjects removeObjectForKey:cID];
	//[myData release];
	
	[controller _errorForLogging:[NSString stringWithFormat:@"Uh oh, an error: %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]]];
	//NSLog(@"Uh oh, an error: %@ %@", [error localizedDescription], [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *cID = [self cIDForConnection:connection];
	//NSLog(@"Success for: %@", cID);
	
	NSString *theUserInfo = [[[NSString alloc] initWithData:[responses objectForKey:cID] encoding:NSUTF8StringEncoding] autorelease];
	
	NSInvocation *completionInvocation = [[properties objectForKey:cID] objectForKey:@"invocation"];
	
	NSURLRequest *request = [rObjects objectForKey:cID];
	
	// invoke the completion invocation
	[completionInvocation setArgument:&theUserInfo atIndex:2];
	[completionInvocation setArgument:&request atIndex:3];
	[completionInvocation invoke];
	//[[NSNotificationCenter defaultCenter] postNotificationName:[connection notificationToPost] object:self userInfo:theUserInfo];
	
	[responses removeObjectForKey:cID];
	[properties removeObjectForKey:cID];
	[requests removeObjectForKey:cID];
	[rObjects removeObjectForKey:cID];
}

- (void)doNothing:(NSString *)response
{
	// Placeholder
}

@end
