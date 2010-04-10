//
//  Track.m
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Track.h"


@implementation Track
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
			NSArray *keys = [NSArray arrayWithObjects:@"name", @"id", @"playlist", @"source", @"duration", @"time", @"album", @"artist", @"videoType", @"genre", @"rating", @"composer", @"comments", nil];
			NSArray *values = [NSArray arrayWithObjects:NSLocalizedString(@"(Unknown)", nil), @"0", @"0", @"0", @"0", @"0:00", @"", @"", @"none", @"", @"0", @"", @"", nil];
			
			properties = [[NSMutableDictionary alloc] initWithObjects:values forKeys:keys];
		}
		else
		{
			properties = [[NSMutableDictionary alloc] initWithDictionary:itemProperties copyItems:YES];
		}
	}
	
	return self;
}

- (void)play
{
	[server doCommand:@"playTrack" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"track", nil]];
}

- (void)queueToPlaylist:(NSString *)playlistRef
{
	if ([server supportsExtension:@"tc.queueTrackToPlaylist"])
		[server doCommand:@"tc.queueTrackToPlaylist" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"track", playlistRef, @"toPlaylist", nil]];
	else
		NSLog(@"Queueing to playlists not supported by server!");
}
- (void)addToPlaylist:(NSString *)playlistRef
{
	[server doCommand:@"addTrackToPlaylist" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[self itemRef], @"track", playlistRef, @"toPlaylist", nil]];
}

- (NSString *)itemRef
{
	return [NSString stringWithFormat:@"%@:%@:%@", [properties valueForKey:@"id"], [properties valueForKey:@"playlist"], [properties valueForKey:@"source"]];
}

- (NSString *)ratingStars
{
	NSString *rating;
	NSString *rFormat = @"%@%@%@%@%@";
	
	NSString *star = NSLocalizedString(@"ratingStar", nil);
	NSString *half = NSLocalizedString(@"ratingHalf", nil);
	NSString *e = @"";
	
	int trackRating = [[properties valueForKey:@"rating"] intValue];
	
	if (trackRating < 10) rating = @"";
	else if (trackRating < 20) rating = [NSString stringWithFormat:rFormat, half, e, e, e, e];
	else if (trackRating < 30) rating = [NSString stringWithFormat:rFormat, star, e, e, e, e];
	else if (trackRating < 40) rating = [NSString stringWithFormat:rFormat, star, half, e, e, e];
	else if (trackRating < 50) rating = [NSString stringWithFormat:rFormat, star, star, e, e, e];
	else if (trackRating < 60) rating = [NSString stringWithFormat:rFormat, star, star, half, e, e];
	else if (trackRating < 70) rating = [NSString stringWithFormat:rFormat, star, star, star, e, e];
	else if (trackRating < 80) rating = [NSString stringWithFormat:rFormat, star, star, star, half, e];
	else if (trackRating < 90) rating = [NSString stringWithFormat:rFormat, star, star, star, star, e];
	else if (trackRating < 100) rating = [NSString stringWithFormat:rFormat, star, star, star, star, half];
	else if (trackRating == 100) rating = [NSString stringWithFormat:rFormat, star, star, star, star, star];
	
	return rating;
}

+ (NSString *)lengthStringFromTime:(int)seconds
{
	int min = seconds / 60;
	int sec = seconds % 60;
	
	NSString *cleanSeconds = @"00";
	if (sec < 10) cleanSeconds = [NSString stringWithFormat:@"0%d", sec];
	else cleanSeconds = [NSString stringWithFormat:@"%d", sec];
	
	NSString *time = [NSString stringWithFormat:@"%d:%@", min, cleanSeconds];
	return time;
}

@end
