//
//  BonjourController.m
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BonjourController.h"


@implementation BonjourController
- (id)init
{
    self = [super init];
    services = [[NSMutableArray alloc] init];
    searching = NO;
	
    return self;
}



- (void)dealloc

{
    [services release];
	[browser release];
    [super dealloc];
}

- (NSMutableArray *)services
{
	return services;
}
- (void)setServices:(NSArray *)newServices
{
	[services setArray:newServices];
}

- (bool)searching
{
	return searching;
}
- (void)setSearching:(bool)isSearching
{
	searching = isSearching;
}

- (void)beginBrowsing
{
	browser = [[NSNetServiceBrowser alloc] init];
	[browser setDelegate:self];
	[browser searchForServicesOfType:@"_tunage._tcp" inDomain:@""];
}

- (void)connectToCurrentlySelectedHost
{
	if ([[serviceArray selectedObjects] count] > 0)
	{
		selectedService = [[serviceArray selectedObjects] objectAtIndex:0];
		[selectedService setDelegate:self];
		[selectedService resolveWithTimeout:5.0];
	}
}

// Sent when browsing begins

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser

{
    searching = YES;
}



// Sent when browsing stops

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    searching = NO;
}



// Sent if browsing fails

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
			 didNotSearch:(NSDictionary *)errorDict

{
    searching = NO;
}



// Sent when a service appears

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		   didFindService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing
{
	[self willChangeValueForKey:@"services"];
    [services addObject:aNetService];
	[self didChangeValueForKey:@"services"];
}



// Sent when a service disappears

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		 didRemoveService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing

{
	[self willChangeValueForKey:@"services"];
    [services removeObject:aNetService];
	[self didChangeValueForKey:@"services"];
}

- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
	// Service resolved!
	[netService stop];
	
	struct sockaddr_in *socketAddress;
	
	socketAddress = (struct sockaddr_in *) [[[netService addresses] objectAtIndex:0] bytes];
	
	[appController startConnectionWithAddress:[NSString stringWithFormat: @"%s", inet_ntoa(socketAddress->sin_addr)] andPort:[NSString stringWithFormat:@"%d", ntohs(socketAddress->sin_port)] withIdentifier:[netService name]];
}

- (void)netService:(NSNetService *)netService
        didNotResolve:(NSDictionary *)errorDict
{
	// Implement error handling later!
	[netService stop];
}

@end
