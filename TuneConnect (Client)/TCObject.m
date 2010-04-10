//
//  TCObject.m
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TCObject.h"


@implementation TCObject
- (id)server
{
	return server;
}

- (void)dealloc
{
	[properties release];
	[children release];
	[super dealloc];
}

- (void)setServer:(id)newServer
{
	server = newServer;
}

- (id)delegate
{
	return delegate;
}
- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

- (NSMutableDictionary *)properties
{
	return properties;
}

- (void)setProperties:(NSDictionary *)newProperties
{
	[properties setDictionary:newProperties];
}

- (void)setChildren:(NSArray *)newChildren
{
	[children setArray:newChildren];
}

- (bool)objectIsLeaf
{
	return objectIsLeaf;
}

@end
