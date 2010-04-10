//
//  Playlist.m
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Playlist.h"


@implementation Playlist
- (id)init
{
	return [self initWithProperties:nil];
}

- (id)initWithProperties:(NSDictionary *)itemProperties
{
	if (self = [super init])
	{
		objectIsLeaf = YES;
		
		if (itemProperties == nil)
		{
			NSArray *keys = [NSArray arrayWithObjects:@"name", @"id", @"source", @"duration", @"trackCount", @"specialKind", @"shuffle", @"repeat", nil];
			NSArray *values = [NSArray arrayWithObjects:NSLocalizedString(@"(Unknown)", nil), @"0", @"0", @"0", @"0", @"none", [NSNumber numberWithBool:NO], @"off", nil];
			
			properties = [[NSMutableDictionary alloc] initWithObjects:values forKeys:keys];
		}
		else
		{
			properties = [[NSMutableDictionary alloc] initWithDictionary:itemProperties copyItems:YES];
		}
		
		signature = @"";
	}
	
	return self;
}

- (NSMutableArray *)tracks
{
	if (!children)
	{
		children = [[NSMutableArray alloc] init];
		
		// Post notification, "Loading \"%@\"...", [properties valueForKey:@"name"]
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		NSString *genres = [[NSNumber numberWithBool:[defaults boolForKey:@"genreColumn"]] stringValue];
		NSString *composers = [[NSNumber numberWithBool:[defaults boolForKey:@"composerColumn"]] stringValue];
		NSString *comments = [[NSNumber numberWithBool:[defaults boolForKey:@"commentsColumn"]] stringValue];
		NSString *datesAdded = [[NSNumber numberWithBool:[defaults boolForKey:@"dateAddedColumn"]] stringValue];
		NSString *bitrates = [[NSNumber numberWithBool:[defaults boolForKey:@"bitrateColumn"]] stringValue];
		NSString *sampleRates = [[NSNumber numberWithBool:[defaults boolForKey:@"sampleRateColumn"]] stringValue];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"objectLoading" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"Loading \"%@\"...", nil), [properties valueForKey:@"name"]], @"string", [NSNumber numberWithBool:YES], @"progressBar", nil]];
		[server doCommand:@"getTracks" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"ofPlaylist", @"1", @"ratings", genres, @"genres", composers, @"composers", comments, @"comments", datesAdded, @"datesAdded", bitrates, @"bitrates", sampleRates, @"sampleRates", @"1", @"signature", nil] callingMethod:@selector(populateTracks:) ofObject:self];

	}
	else
	{
		[self checkForUpdates];
	}
	return children;
}

- (void)populateTracks:(NSDictionary *)response
{
	[children release];
	children = [[NSMutableArray alloc] init];
	int trackID = 0;
	
	NSEnumerator *enumerator = [[response objectForKey:@"tracks"] objectEnumerator];
	
	[self willChangeValueForKey:@"tracks"];
	id track;
	int counter = 0;
	int totalTracks = [[response objectForKey:@"tracks"] count];
	while (track = [enumerator nextObject])
	{
		Track *newTrack = [[Track alloc] initWithProperties:track];
		[[newTrack properties] setObject:[NSNumber numberWithInt:(++trackID)] forKey:@"relativeID"];
		[[newTrack properties] setObject:[Track lengthStringFromTime:[[track valueForKey:@"duration"] intValue]] forKey:@"time"];
		[[newTrack properties] setObject:[NSNumber numberWithFloat:([[track valueForKey:@"rating"] floatValue] / 20.0)] forKey:@"fBasedRating"];
		[newTrack setServer:server];
		[children addObject:newTrack];
		[newTrack release];
		counter++;
		//NSLog(@"iteration");
		if ([delegate respondsToSelector:@selector(updateProgressBar:)])
			[delegate updateProgressBar:[NSNumber numberWithFloat:((float)counter / (float)totalTracks)]];
	}
	[self didChangeValueForKey:@"tracks"];
	
	signature = [[response objectForKey:@"signature"] copy];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"objectReady" object:self userInfo:nil];
}

- (void)signatureResponse:(NSDictionary *)response
{
	if (![signature isEqualToString:[response objectForKey:@"signature"]])
	{
		// Something's changed, we need an update!
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		NSString *genres = [[NSNumber numberWithBool:[defaults boolForKey:@"genreColumn"]] stringValue];
		NSString *composers = [[NSNumber numberWithBool:[defaults boolForKey:@"composerColumn"]] stringValue];
		NSString *comments = [[NSNumber numberWithBool:[defaults boolForKey:@"commentsColumn"]] stringValue];
		NSString *datesAdded = [[NSNumber numberWithBool:[defaults boolForKey:@"dateAddedColumn"]] stringValue];
		NSString *bitrates = [[NSNumber numberWithBool:[defaults boolForKey:@"bitrateColumn"]] stringValue];
		NSString *sampleRates = [[NSNumber numberWithBool:[defaults boolForKey:@"sampleRateColumn"]] stringValue];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"objectLoading" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"Updating \"%@\"...", nil), [properties valueForKey:@"name"]], @"string", [NSNumber numberWithBool:YES], @"progressBar", nil]];
		[server doCommand:@"getTracks" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"ofPlaylist", @"1", @"ratings", genres, @"genres", composers, @"composers", comments, @"comments", datesAdded, @"datesAdded", bitrates, @"bitrates", sampleRates, @"sampleRates", @"1", @"signature", nil] callingMethod:@selector(populateTracks:) ofObject:self];
	}
	else	// all set :)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"objectReady" object:self userInfo:nil];
}

- (void)checkForUpdates
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *genres = [[NSNumber numberWithBool:[defaults boolForKey:@"genreColumn"]] stringValue];
	NSString *composers = [[NSNumber numberWithBool:[defaults boolForKey:@"composerColumn"]] stringValue];
	NSString *comments = [[NSNumber numberWithBool:[defaults boolForKey:@"commentsColumn"]] stringValue];
	NSString *datesAdded = [[NSNumber numberWithBool:[defaults boolForKey:@"dateAddedColumn"]] stringValue];
	NSString *bitrates = [[NSNumber numberWithBool:[defaults boolForKey:@"bitrateColumn"]] stringValue];
	NSString *sampleRates = [[NSNumber numberWithBool:[defaults boolForKey:@"sampleRateColumn"]] stringValue];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"objectLoading" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"Checking for changes to \"%@\"...", nil), [properties valueForKey:@"name"]], @"string", [NSNumber numberWithBool:NO], @"progressBar", nil]];
	[server doCommand:@"signature" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"ofPlaylist", @"1", @"ratings", genres, @"genres", composers, @"composers", comments, @"comments", datesAdded, @"datesAdded", bitrates, @"bitrates", sampleRates, @"sampleRates", nil] callingMethod:@selector(signatureResponse:) ofObject:self];
}

- (void)getPlaySettingsCallingMethod:(SEL)methodSelector ofObject:(id)receivingObject
{
	[server doCommand:@"playSettings" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"ofPlaylist", nil] callingMethod:methodSelector ofObject:receivingObject];
}

- (void)setRepeat:(NSString *)repeatValue
{
	[server doCommand:@"setPlaySettings" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"ofPlaylist", repeatValue, @"repeat", nil]];
}

- (void)setShuffle:(NSString *)shuffleValue
{
	[server doCommand:@"setPlaySettings" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"ofPlaylist", shuffleValue, @"shuffle", nil]];
}

- (NSString *)itemRef
{
	return [NSString stringWithFormat:@"%@:%@", [properties valueForKey:@"id"], [properties valueForKey:@"source"]];
}

@end
