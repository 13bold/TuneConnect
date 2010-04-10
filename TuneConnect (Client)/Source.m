//
//  Source.m
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Source.h"

@implementation Source
- (id)init
{
	return [self initWithProperties:nil];
}

- (id)initWithProperties:(NSDictionary *)itemProperties
{
	if (self = [super init])
	{
		if (itemProperties == nil)
		{
			NSArray *keys = [NSArray arrayWithObjects:@"name", @"kind", @"id", nil];
			NSArray *values = [NSArray arrayWithObjects:NSLocalizedString(@"(Unknown)", nil), @"library", @"0", nil];
			
			properties = [[NSMutableDictionary alloc] initWithObjects:values forKeys:keys];
		}
		else
		{
			properties = [[NSMutableDictionary alloc] initWithDictionary:itemProperties copyItems:YES];
		}
	}
	
	return self;
}

- (NSMutableArray *)playlists
{
	//NSLog(@"Anything? (%@) -children", [properties valueForKey:@"name"]);
	if (!children)
	{
		children = [[NSMutableArray alloc] init];
		[server doCommand:@"getPlaylists" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[properties valueForKey:@"id"], @"ofSource", nil] callingMethod:@selector(populatePlaylists:) ofObject:self];
	}
	return children;
}

- (void)populatePlaylists:(NSDictionary *)response
{
	NSEnumerator *enumerator = [[response objectForKey:@"playlists"] objectEnumerator];
	
	id playlist;
	
	[self willChangeValueForKey:@"playlists"];
	
	while (playlist = [enumerator nextObject])
	{
		Playlist *newPlaylist = [[Playlist alloc] initWithProperties:playlist];
		[newPlaylist setServer:server];
		[newPlaylist setDelegate:[self delegate]];
		[children addObject:newPlaylist];
		
		if ([[playlist valueForKey:@"specialKind"] isEqual:@"Party_Shuffle"])
			shuffleListRef = [[newPlaylist itemRef] retain];
		
		[newPlaylist release];
	}
	
	[self didChangeValueForKey:@"playlists"];
}

- (NSString *)shuffleRef
{
	return shuffleListRef;
}

@end
