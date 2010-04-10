//
//  PlayerStatus.m
//  TuneConnect
//
//  Created by Matt Patenaude on 9/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PlayerStatus.h"

@implementation PlayerStatus
- (id)init
{
	if (self = [super init])
	{
		trackName = [[NSString alloc] initWithString:NSLocalizedString(@"Not Connected", nil)];
		trackArtist = [[NSString alloc] initWithString:@""];
		trackAlbum = [[NSString alloc] initWithString:@""];
		trackDuration = 0.0;
		
		trackGenre = [[NSString alloc] initWithString:@""];
		trackRating = 0;
		trackComposer = [[NSString alloc] initWithString:@""];
		
		playState = @"stopped";
		playerVolume = 70;
		playerPosition = 0;
		
		oldTrack = [[NSString alloc] initWithString:@""];
		oldAlbum = [[NSString alloc] initWithString:@""];
		
		volumeCycle = 0;
		dragInProgress = NO;
	}
	return self;
}

- (TCServer *)server
{
	return server;
}

- (void)setServer:(TCServer *)newServer
{
	server = newServer;
}

- (id)appController
{
	return appController;
}
- (void)setAppController:(id)newController
{
	appController = newController;
}

- (NSString *)trackName
{
	return trackName;
}
- (void)setTrackName:(NSString *)newTrackName
{
	NSString *old = trackName;
	trackName = [newTrackName copy];
	[old release];
}

- (NSString *)trackArtist
{
	return trackArtist;
}
- (void)setTrackArtist:(NSString *)newTrackArtist
{
	NSString *old = trackArtist;
	trackArtist = [newTrackArtist copy];
	[old release];
}

- (NSString *)trackAlbum
{
	return trackAlbum;
}
- (void)setTrackAlbum:(NSString *)newTrackAlbum
{
	NSString *old = trackAlbum;
	trackAlbum = [newTrackAlbum copy];
	[old release];
}

- (float)trackDuration
{
	return trackDuration;
}
- (void)setTrackDuration:(float)newTrackDuration
{
	trackDuration = newTrackDuration;
}

- (NSString *)trackGenre
{
	return trackGenre;
}
- (void)setTrackGenre:(NSString *)newTrackGenre
{
	NSString *old = trackGenre;
	trackGenre = [newTrackGenre copy];
	[old release];
}

- (float)trackRating
{
	return ((float)trackRating / 20.0);
}
- (void)setTrackRating:(float)newTrackRating
{
	trackRating = (int)((float)newTrackRating * 20.0);
	[server doCommand:@"setTrackRating" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", trackRating], @"rating", nil]];
}

- (NSString *)ratingString
{
	NSString *rating;
	NSString *rFormat = @"%@%@%@%@%@";
	
	if (server && [server activeConnection])
	{
		NSString *star = NSLocalizedString(@"ratingStar", nil);
		NSString *half = NSLocalizedString(@"ratingHalf", nil);
		NSString *e = @"";
		
		if (trackRating < 10) rating = NSLocalizedString(@"None", nil);
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
		
		rating = [NSString stringWithFormat:NSLocalizedString(@"Rating: %@", nil), rating];
	}
	else
	{
		rating = NSLocalizedString(@"Not Connected", nil);
	}
	
	return rating;
}

- (NSString *)trackComposer
{
	return trackComposer;
}
- (void)setTrackComposer:(NSString *)newTrackComposer
{
	NSString *old = trackComposer;
	trackComposer = [newTrackComposer copy];
	[old release];
}

- (NSString *)playState
{
	return playState;
}
- (void)setPlayState:(NSString *)newPlayState
{
	[self willChangeValueForKey:@"playStateInverseAction"];
	NSString *old = playState;
	playState = [newPlayState copy];
	[old release];
	[self didChangeValueForKey:@"playStateInverseAction"];
}

- (NSString *)playStateInverseAction
{
	if ([playState isEqualToString:@"playing"])
		return NSLocalizedString(@"Pause", nil);
	else
		return NSLocalizedString(@"Play", nil);
}

- (int)playerVolume
{
	return playerVolume;
}
- (void)setPlayerVolume:(int)newPlayerVolume
{
	playerVolume = newPlayerVolume;
	[server doCommand:@"setVolume" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", newPlayerVolume], @"volume", nil]];
}
- (void)muteUnmute
{
	if (playerVolume == 0)
		[self setPlayerVolume:premuteVolume];
	else
	{
		premuteVolume = playerVolume;
		[self setPlayerVolume:0];
	}
}

- (int)playerPosition
{
	return playerPosition;
}
- (void)setPlayerPosition:(int)newPlayerPosition
{
	playerPosition = newPlayerPosition;
	[server doCommand:@"setPlayerPosition" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", newPlayerPosition], @"position", nil]];
}

- (NSString *)timeElapsed
{
	int min = playerPosition / 60;
	int sec = playerPosition % 60;
	
	NSString *cleanSeconds = @"00";
	if (sec < 10) cleanSeconds = [NSString stringWithFormat:@"0%d", sec];
	else cleanSeconds = [NSString stringWithFormat:@"%d", sec];
	
	NSString *timePassed = [NSString stringWithFormat:@"%d:%@", min, cleanSeconds];
	return timePassed;
}
- (NSString *)timeRemaining
{
	int remaining = (int)trackDuration - playerPosition;
	int min = remaining / 60;
	int sec = remaining % 60;
	
	NSString *cleanSeconds = @"00";
	if (sec < 10) cleanSeconds = [NSString stringWithFormat:@"0%d", sec];
	else cleanSeconds = [NSString stringWithFormat:@"%d", sec];
	
	NSString *timeLeft = [NSString stringWithFormat:@"-%d:%@", min, cleanSeconds];
	return timeLeft;
}

- (NSString *)trackStatusDisplay
{
	if (![trackName isEqual:NSLocalizedString(@"Nothing Playing", nil)])
	{
		NSString *topPart;
		if ([trackArtist isEqualToString:@""] && [trackAlbum isEqualToString:@""])
			topPart = trackName;
		else if ([trackAlbum isEqualToString:@""])
			topPart = [NSString stringWithFormat:@"%@\n%@", trackName, trackArtist];
		else if ([trackArtist isEqualToString:@""])
			topPart = [NSString stringWithFormat:@"%@\n%@", trackName, trackAlbum];
		else
			topPart = [NSString stringWithFormat:@"%@\n%@\n%@", trackName, trackArtist, trackAlbum];
			
		return topPart;
	}
	else
		return [NSString stringWithString:trackName];
}

- (NSArray *)alternatingStatusDisplay
{
	NSString *formatString = @"%@\n%@";
	
	if ([trackArtist isEqualToString:@""] && [trackAlbum isEqualToString:@""])
		return [NSArray arrayWithObject:trackName];
	else if ([trackAlbum isEqualToString:@""])
		return [NSArray arrayWithObject:[NSString stringWithFormat:formatString, trackName, trackArtist]];
	else if ([trackArtist isEqualToString:@""])
		return [NSArray arrayWithObject:[NSString stringWithFormat:formatString, trackName, trackAlbum]];
	else
		return [NSArray arrayWithObjects:[NSString stringWithFormat:formatString, trackName, trackArtist], [NSString stringWithFormat:formatString, trackName, trackAlbum], nil];
}

- (void)beginUpdatingFromServer:(TCServer *)theServer
{
	trackName = NSLocalizedString(@"Please wait...", nil);
	[self setServer:theServer];
	[self continueUpdateCycle:nil];
}

- (void)continueUpdateCycle:(NSTimer *)oldTimer
{
	[server doCommand:@"fullStatus" withParams:[NSDictionary dictionaryWithObject:@"1" forKey:@"rating"] callingMethod:@selector(handleUpdates:) ofObject:self];
}

- (void)handleUpdates:(NSDictionary *)response
{
	[oldTrack release];
	[oldAlbum release];
	
	oldTrack = [[self trackStatusDisplay] retain];
	oldAlbum = [[self trackAlbum] copy];
	//NSLog([response description]);
	[self willChangeValueForKey:@"alternatingStatusDisplay"];
	[self willChangeValueForKey:@"trackStatusDisplay"];
	if ([response valueForKey:@"name"] == [NSNumber numberWithBool:NO])
	{
		[self setTrackName:NSLocalizedString(@"Nothing Playing", nil)];
		[self setTrackArtist:@""];
		[self setTrackAlbum:@""];
		
		[self willChangeValueForKey:@"ratingString"];
		[self willChangeValueForKey:@"trackRating"];
		trackRating = 0;
		[self didChangeValueForKey:@"trackRating"];
		[self didChangeValueForKey:@"ratingString"];
	}
	else
	{
		[self setTrackName:[response valueForKey:@"name"]];
		[self setTrackArtist:[response valueForKey:@"artist"]];
		[self setTrackAlbum:[response valueForKey:@"album"]];
		
		[self willChangeValueForKey:@"ratingString"];
		[self willChangeValueForKey:@"trackRating"];
		trackRating = [[response valueForKey:@"rating"] intValue];
		[self didChangeValueForKey:@"trackRating"];
		[self didChangeValueForKey:@"ratingString"];
	}
	[self didChangeValueForKey:@"trackStatusDisplay"];
	[self didChangeValueForKey:@"alternatingStatusDisplay"];
	
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:response];
	[result setObject:[self trackStatusDisplay] forKey:@"statusDisplay"];
	[result setObject:[self ratingString] forKey:@"ratingString"];
	
	/* BIG BUG-- Unknown cause;
		Details:
			Directly caused by line:
				NSData *artwork = [NSData dataWithContentsOfURL:artURL];
			It appears that it conflicts with the normal server communication mechanism.
			Perhaps a threading problem? All I know is that, with this line present,
			commands will sporadically be sent twice in quick succession.
			
		Update:
			It appears that this is something that NSURLConnection/CFNetwork do. Whether
			it is the correct behavior or not, I do not know, but there's nothing I can do
			to change it. Thus, a workaround is implemented in version 2.1 of the server and
			later.
	*/
	if ([[self trackStatusDisplay] isNotEqualTo:oldTrack])
	{
		NSURL *artURL = [NSURL URLWithString:[server composeURLForCommand:@"artwork" withParams:nil returnMode:TCRaw]];
		NSData *artwork = [NSData dataWithContentsOfURL:artURL];
		//id artwork = nil;
		if (artwork == nil) artwork = [NSData data];
		[result setObject:artwork forKey:@"artwork"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"trackChanged" object:self userInfo:result];
	}
	else
	{
		if (oldRating != trackRating)
		{
			NSURL *artURL = [NSURL URLWithString:[server composeURLForCommand:@"artwork" withParams:nil returnMode:TCRaw]];
			NSData *artwork = [NSData dataWithContentsOfURL:artURL];
			//id artwork = nil;
			if (artwork == nil) artwork = [NSData data];
			[result setObject:artwork forKey:@"artwork"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ratingChanged" object:self userInfo:result];
		}
	}
	
	oldRating = trackRating;
	
	if ([[self trackAlbum] isNotEqualTo:oldAlbum])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"albumChanged" object:self userInfo:result];
	}
	
	float newTrackDuration = [[response valueForKey:@"duration"] floatValue];
	if (newTrackDuration != trackDuration)
	{
		[self setTrackDuration:newTrackDuration];
	}
	
	if (![[response valueForKey:@"playState"] isEqualToString:playState])
	{
		[self setPlayState:[response valueForKey:@"playState"]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"playStateChanged" object:self userInfo:[NSDictionary dictionaryWithObject:playState forKey:@"pState"]];
	}
	
	if (!dragInProgress)
	{
		[self willChangeValueForKey:@"playerPosition"];
		[self willChangeValueForKey:@"timeElapsed"];
		[self willChangeValueForKey:@"timeRemaining"];
		playerPosition = [[response valueForKey:@"progress"] intValue];
		[self didChangeValueForKey:@"timeRemaining"];
		[self didChangeValueForKey:@"timeElapsed"];
		[self didChangeValueForKey:@"playerPosition"];
		
		[self willChangeValueForKey:@"playerVolume"];
		playerVolume = [[response valueForKey:@"volume"] intValue];
		[self didChangeValueForKey:@"playerVolume"];
	}
	
	// Replace with user defaults int value :P
	updater = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(continueUpdateCycle:) userInfo:nil repeats:NO];
}

- (void)dragInProgress:(bool)inProg
{
	dragInProgress = inProg;
}

@end
