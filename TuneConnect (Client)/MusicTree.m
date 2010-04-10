//
//  MusicTree.m
//  TuneConnect
//
//  Created by Matt Patenaude on 9/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MusicTree.h"


@implementation MusicTree
- (void)dealloc
{
	[sources release];
	[super dealloc];
}

- (id)init
{
	if (self = [super init])
	{
		selectedSource = nil;
	}
	return self;
}

- (id)server
{
	return server;
}

- (void)setServer:(id)newServer
{
	server = newServer;
}

- (id)interfaceController
{
	return interfaceController;
}
- (void)setInterfaceController:(id)newController
{
	interfaceController = newController;
}

- (NSMutableArray *)sources
{
	if (!sources)
	{
		sources = [[NSMutableArray alloc] init];
		[server doCommand:@"getSources" withParams:nil callingMethod:@selector(populateSources:) ofObject:self];

	}
	return sources;
}

- (void)setSources:(NSArray *)newSources
{
	[sources setArray:newSources];
}

- (Source *)selectedSource
{
	return selectedSource;
}
- (void)setSelectedSource:(Source *)newSource
{
	selectedSource = newSource;
}

- (void)populateSources:(NSDictionary *)response
{
	NSEnumerator *enumerator = [[response objectForKey:@"sources"] objectEnumerator];
	
	id source;
	
	[self willChangeValueForKey:@"shouldShowSourceChooser"];
	[self willChangeValueForKey:@"selectedSource"];
	[self willChangeValueForKey:@"sources"];
	
	while (source = [enumerator nextObject])
	{
		if (![[source valueForKey:@"kind"] isEqualToString:@"radio_tuner"] && ![[source valueForKey:@"kind"] isEqualToString:@"iPod"])
		{
			Source *newSource = [[Source alloc] initWithProperties:source];
			[newSource setServer:server];
			[newSource setDelegate:interfaceController];
			[sources addObject:newSource];
			[newSource release];
		}
	}
	
	selectedSource = [sources objectAtIndex:0];
	
	[self didChangeValueForKey:@"sources"];
	[self didChangeValueForKey:@"selectedSource"];
	[self didChangeValueForKey:@"shouldShowSourceChooser"];
}

- (bool)shouldShowSourceChooser
{
	if (sources)
	{
		if ([sources count] > 1)
			return YES;
		else
			return NO;
	}
	else
		return YES;
}

@end
