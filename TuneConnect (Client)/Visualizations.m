//
//  Visualizations.m
//  TuneConnect
//
//  Created by Matt Patenaude on 12/25/07.
//  Copyright 2007 - 2008 __MyCompanyName__. All rights reserved.
//

#import "Visualizations.h"


@implementation Visualizations

- (id)init
{
	if (self = [super init])
	{
		// Localization note: localize the keys, NOT THE OBJECTS
		sizeMap = [[NSDictionary alloc] initWithObjectsAndKeys:@"large", NSLocalizedString(@"Large", nil), @"medium", NSLocalizedString(@"Medium", nil), @"small", NSLocalizedString(@"Small", nil), nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceChanged:) name:@"interfaceDidChange" object:nil];
	}
	return self;
}

- (void)interfaceChanged:(NSNotification *)aNotification
{
	if ([[[aNotification userInfo] valueForKey:@"mode"] intValue] == TCVisualizations)
	{
		if (!visuals) visuals = [[NSMutableArray alloc] init];
		[server doCommand:@"visualSettings" withParams:nil callingMethod:@selector(processVisualSettings:) ofObject:self];
	}
}

- (void)setServer:(id)newServer
{
	server = newServer;
}
- (id)server
{
	return server;
}

- (NSMutableArray *)visuals
{
	if (!visuals)
	{
		visuals = [[NSMutableArray alloc] init];
		[server doCommand:@"visualSettings" withParams:nil callingMethod:@selector(processVisualSettings:) ofObject:self];
	}
	return visuals;
}
- (NSArray *)sizes
{
	return [NSArray arrayWithObjects:[[sizeMap allKeysForObject:@"large"] objectAtIndex:0], [[sizeMap allKeysForObject:@"medium"] objectAtIndex:0], [[sizeMap allKeysForObject:@"small"] objectAtIndex:0], nil];
}

- (Visual *)currentVisual
{
	return currentVisual;
}
- (void)setCurrentVisual:(Visual *)newVisual
{
	currentVisual = newVisual;
	name = [[newVisual properties] valueForKey:@"name"];
		
	[self updateVisualizationSettings];
}

- (NSNumber *)fullscreen
{
	return fullscreen;
}
- (void)setFullscreen:(NSNumber *)newFullscreen
{
	[fullscreen release];
	fullscreen = [newFullscreen retain];
	
	[self updateVisualizationSettings];
}

- (NSNumber *)displaying
{
	return displaying;
}
- (void)setDisplaying:(NSNumber *)newDisplaying
{
	[displaying release];
	displaying = [newDisplaying retain];
	
	[self updateVisualizationSettings];
}

- (NSString *)size
{
	return size;
}
- (void)setSize:(NSString *)newSize
{
	[size release];
	size = [newSize copy];
	
	[self updateVisualizationSettings];
}

- (void)processVisualSettings:(NSDictionary *)response
{
	[self willChangeValueForKey:@"fullscreen"];
	[fullscreen release];
	fullscreen = [[response valueForKey:@"fullScreen"] retain];
	[self didChangeValueForKey:@"fullscreen"];
	
	[self willChangeValueForKey:@"displaying"];
	[displaying release];
	displaying = [[response valueForKey:@"displaying"] retain];
	[self didChangeValueForKey:@"displaying"];
	
	[self willChangeValueForKey:@"name"];
	[name release];
	name = [[response valueForKey:@"name"] retain];
	[self didChangeValueForKey:@"name"];
	
	[self willChangeValueForKey:@"size"];
	[size release];
	size = [[[sizeMap allKeysForObject:[response valueForKey:@"size"]] objectAtIndex:0] retain];
	[self didChangeValueForKey:@"size"];
	
	[server doCommand:@"visuals" withParams:nil callingMethod:@selector(populateVisuals:) ofObject:self];
}

- (void)populateVisuals:(NSDictionary *)response
{
	NSEnumerator *enumerator = [[response objectForKey:@"visuals"] objectEnumerator];
	
	id visual;
	
	[self willChangeValueForKey:@"currentVisual"];
	[self willChangeValueForKey:@"visuals"];
	[visuals removeAllObjects];
	while (visual = [enumerator nextObject])
	{
		Visual *newVisual = [[Visual alloc] initWithProperties:visual];
		[newVisual setServer:server];
		[visuals addObject:newVisual];
		
		if ([[visual valueForKey:@"name"] isEqualToString:name])
			currentVisual = newVisual;
		
		[newVisual release];
	}
	
	[self didChangeValueForKey:@"visuals"];
	[self didChangeValueForKey:@"currentVisual"];
}

- (void)updateVisualizationSettings
{
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[[[currentVisual properties] valueForKey:@"id"] stringValue], @"visual", [sizeMap valueForKey:size], @"size", [displaying stringValue], @"displaying", [fullscreen stringValue], @"fullScreen", nil];
	[server doCommand:@"setVisualizations" withParams:params];
}

- (void)dealloc
{
	[fullscreen release];
	[displaying release];
	[name release];
	[size release];
	[sizeMap release];
	[super dealloc];
}

@end
