//
//  TCConnectionManager.m
//  Tunage
//
//  Created by Matt Patenaude on 2/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCConnectionManager.h"

static TCConnectionManager *sharedManager = nil;

@implementation TCConnectionManager

+ (TCConnectionManager *)sharedManager
{
	if (!sharedManager)
		sharedManager = [[TCConnectionManager alloc] init];
	
	return sharedManager;
}

- (id)init
{
	if (self = [super init])
	{
		servers = [[NSMutableDictionary alloc] init];
		wrappers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[servers release];
	[wrappers release];
	[super dealloc];
}

- (TCServer *)serverForAddress:(NSString *)address andPort:(int)port
{
	NSString *key = [NSString stringWithFormat:@"http://%@:%d/", address, port];
	
	if ([servers hasKey:key])
		return [servers objectForKey:key];
	else
	{
		TCServer *newServer = [[[TCServer alloc] initWithAddress:address andPort:[NSString stringWithFormat:@"%d", port]] autorelease];
		[servers setObject:newServer forKey:key];
		return newServer;
	}
}

- (TCServerWrapper *)interfaceForAddress:(NSString *)address andPort:(int)port
{
	NSString *key = [NSString stringWithFormat:@"http://%@:%d/", address, port];
	
	if ([wrappers hasKey:key])
		return [wrappers objectForKey:key];
	else
	{
		TCServerWrapper *newWrapper = [[[TCServerWrapper alloc] initWithServer:[self serverForAddress:address andPort:port]] autorelease];
		[wrappers setObject:newWrapper forKey:key];
		return newWrapper;
	}

}

@end
