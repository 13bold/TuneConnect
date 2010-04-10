//
//  BonjourController.h
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <netinet/in.h>


@interface BonjourController : NSObject {
	// Keeps track of available services
	NSMutableArray *services;
	
	// Keeps track of search status
	bool searching;
	
	NSNetServiceBrowser *browser;
	
	NSNetService *selectedService;
	
	IBOutlet NSArrayController *serviceArray;
	IBOutlet id appController;
	
	NSString *currentService;
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
        didNotSearch:(NSDictionary *)errorDict;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
        didFindService:(NSNetService *)aNetService
        moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
        didRemoveService:(NSNetService *)aNetService
        moreComing:(BOOL)moreComing;

- (void)netServiceDidResolveAddress:(NSNetService *)netService;
- (void)netService:(NSNetService *)netService
        didNotResolve:(NSDictionary *)errorDict;

- (NSMutableArray *)services;
- (void)setServices:(NSArray *)newServices;

- (bool)searching;
- (void)setSearching:(bool)isSearching;

- (void)beginBrowsing;
- (void)connectToCurrentlySelectedHost;

@end