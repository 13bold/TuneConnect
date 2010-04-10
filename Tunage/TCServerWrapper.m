//
//  TCServerWrapper.m
//  Tunage
//
//  Created by Matt Patenaude on 2/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCServerWrapper.h"


@implementation TCServerWrapper

- (id)initWithServer:(TCServer *)theServer
{
	if (self = [super init])
	{
		server = [theServer retain];
	}
	return self;
}

- (void)dealloc
{
	[server release];
	[super dealloc];
}

// First two methods need work, big time!

- (NSDictionary *)serverInfo
{
	return [server doBlockingCommand:@"serverInfo.txt" withParams:nil];
}
- (NSString *)authKeyForPassword:(NSString *)password prehashed:(bool)hashed
{
	if (!hashed)
		password = [password sha1HexHash];
	
	NSDictionary *result = [server doBlockingCommand:@"getAuthKey" withParams:[NSDictionary dictionaryWithObjectsAndKeys:password, @"password", nil]];
	
	if ([[result valueForKey:@"authKey"] isKindOfClass:[NSNumber class]])
		return nil;
	else
		return [result valueForKey:@"authKey"];
}
// Begin correctly implemented methods :P
- (NSArray *)sources
{
	NSDictionary *result = [server doBlockingCommand:@"getSources" withParams:nil];
	return [result valueForKey:@"sources"];
}

- (NSArray *)playlistsOfSource:(NSString *)sourceRef
{
	NSDictionary *result = [server doBlockingCommand:@"getPlaylists" withParams:[NSDictionary dictionaryWithObjectsAndKeys:sourceRef, @"ofSource", nil]];
	return [result valueForKey:@"playlists"];
}
- (NSString *)signatureOfPlaylist:(NSString *)playlistRef
{
	NSDictionary *result = [server doBlockingCommand:@"signature" withParams:[NSDictionary dictionaryWithObjectsAndKeys:playlistRef, @"ofPlaylist", nil]];
	return [result valueForKey:@"signature"];
}
- (NSString *)signatureOfPlaylist:(NSString *)playlistRef includingGenres:(bool)genres ratings:(bool)ratings composers:(bool)composers comments:(bool)comments
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:playlistRef, @"ofPlaylist", nil];
	
	if (genres)
		[params setValue:@"1" forKey:@"genres"];
	else
		[params setValue:@"0" forKey:@"genres"];
	
	if (ratings)
		[params setValue:@"1" forKey:@"ratings"];
	else
		[params setValue:@"0" forKey:@"ratings"];
	
	if (composers)
		[params setValue:@"1" forKey:@"composers"];
	else
		[params setValue:@"0" forKey:@"composers"];
	
	if (comments)
		[params setValue:@"1" forKey:@"comments"];
	else
		[params setValue:@"0" forKey:@"comments"];
	
	NSDictionary *result = [server doBlockingCommand:@"signature" withParams:params];
	return [result valueForKey:@"signature"];
}

- (NSArray *)tracksOfPlaylist:(NSString *)playlistRef
{
	NSDictionary *result = [server doBlockingCommand:@"getTracks" withParams:nil];
	return [result valueForKey:@"tracks"];
}
- (NSArray *)tracksOfPlaylist:(NSString *)playlistRef includingGenres:(bool)genres ratings:(bool)ratings composers:(bool)composers comments:(bool)comments
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:playlistRef, @"ofPlaylist", nil];
	
	if (genres)
		[params setValue:@"1" forKey:@"genres"];
	else
		[params setValue:@"0" forKey:@"genres"];
	
	if (ratings)
		[params setValue:@"1" forKey:@"ratings"];
	else
		[params setValue:@"0" forKey:@"ratings"];
	
	if (composers)
		[params setValue:@"1" forKey:@"composers"];
	else
		[params setValue:@"0" forKey:@"composers"];
	
	if (comments)
		[params setValue:@"1" forKey:@"comments"];
	else
		[params setValue:@"0" forKey:@"comments"];
	
	NSDictionary *result = [server doBlockingCommand:@"getTracks" withParams:params];
	return [result valueForKey:@"tracks"];
}

- (NSDictionary *)tracksOfPlaylistWithSignature:(NSString *)playlistRef
{
	return [server doBlockingCommand:@"getTracks" withParams:nil];
}
- (NSDictionary *)tracksOfPlaylistWithSignature:(NSString *)playlistRef includingGenres:(bool)genres ratings:(bool)ratings composers:(bool)composers comments:(bool)comments
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:playlistRef, @"ofPlaylist", nil];
	
	if (genres)
		[params setValue:@"1" forKey:@"genres"];
	else
		[params setValue:@"0" forKey:@"genres"];
	
	if (ratings)
		[params setValue:@"1" forKey:@"ratings"];
	else
		[params setValue:@"0" forKey:@"ratings"];
	
	if (composers)
		[params setValue:@"1" forKey:@"composers"];
	else
		[params setValue:@"0" forKey:@"composers"];
	
	if (comments)
		[params setValue:@"1" forKey:@"comments"];
	else
		[params setValue:@"0" forKey:@"comments"];
	
	return [server doBlockingCommand:@"getTracks" withParams:params];
}

- (void)play
{
	[server doBlockingCommand:@"play" withParams:nil];
}
- (void)pause
{
	[server doBlockingCommand:@"pause" withParams:nil];
}
- (void)playPause
{
	[server doBlockingCommand:@"playPause" withParams:nil];
}
- (void)stop
{
	[server doBlockingCommand:@"stop" withParams:nil];
}
- (void)playPlaylist:(NSString *)playlistRef
{
	[server doBlockingCommand:@"playPlaylist" withParams:[NSDictionary dictionaryWithObjectsAndKeys:playlistRef, @"playlist", nil]];
}
- (void)playTrack:(NSString *)trackRef
{
	[server doBlockingCommand:@"playTrack" withParams:[NSDictionary dictionaryWithObjectsAndKeys:trackRef, @"track", nil]];
}
- (void)playTrack:(NSString *)trackRef once:(bool)playOnce
{
	NSMutableDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:trackRef, @"track", nil];
	
	if (playOnce)
		[params setValue:@"1" forKey:@"once"];
	else
		[params setValue:@"0" forKey:@"once"];
	
	[server doBlockingCommand:@"playTrack" withParams:params];
}
- (void)nextTrack
{
	[server doBlockingCommand:@"nextTrack" withParams:nil];
}
- (void)prevTrack
{
	[server doBlockingCommand:@"prevTrack" withParams:nil];
}

- (void)setVolume:(int)newVolume
{
	[server doBlockingCommand:@"setVolume" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", newVolume], @"volume", nil]];
}
- (void)volumeUp
{
	[server doBlockingCommand:@"volumeUp" withParams:nil];
}
- (void)volumeDown
{
	[server doBlockingCommand:@"volumeDown" withParams:nil];
}

- (NSDictionary *)currentTrack;
- (NSDictionary *)currentTrackIncludingGenre:(bool)genre rating:(bool)rating composer:(bool)composer comments:(bool)comments;
- (NSDictionary *)playerStatus;
- (NSDictionary *)fullStatus;
- (NSDictionary *)fullStatusIncludingGenre:(bool)genre rating:(bool)rating composer:(bool)composer comments:(bool)comments;

- (void)setPlayerPosition:(int)newPosition;

- (NSImage *)artwork;

- (NSDictionary *)playSettingsOfPlaylist;
- (void)setShuffle:(bool)shuffleOn forPlaylist:(NSString *)playlistRef;
- (void)setRepeat:(TCServerRepeatSetting)repeat forPlaylist:(NSString *)playlistRef;

- (NSDictionary *)searchFor:(NSString *)query;
- (NSDictionary *)searchFor:(NSString *)query includingGenres:(bool)genres ratings:(bool)ratings composers:(bool)composers comments:(bool)comments;

- (NSDictionary *)EQSettings;
- (NSArray *)EQPresets;
- (void)setEQState:(bool)eqOn;
- (void)setValue:(float)newValue forEQBand:(NSString *)band;
- (void)setEQPreset:(NSString *)presetID;

- (NSArray *)visuals;
- (NSDictionary *)visualSettings;
- (void)setVisual:(NSString *)visualID;
- (void)setVisualizationsFullscreen:(bool)fullscreen;
- (void)setVisualizationsOn:(bool)visualsOn;
- (void)setVisualizationsSize:(TCServerVisualsSize)visualSize;

- (void)setName:(NSString *)name ofTrack:(NSString *)trackRef;
- (void)setArtist:(NSString *)artist ofTrack:(NSString *)trackRef;
- (void)setAlbum:(NSString *)album ofTrack:(NSString *)trackRef;
- (void)setRating:(int)rating ofTrack:(NSString *)trackRef;
- (void)setGenre:(NSString *)genre ofTrack:(NSString *)trackRef;
- (void)setComposer:(NSString *)composer ofTrack:(NSString *)trackRef;
- (void)setComments:(NSString *)comments ofTrack:(NSString *)trackRef;

- (void)createPlaylistNamed:(NSString *)name;
- (void)addTrack:(NSString *)trackRef toPlaylist:(NSString *)playlistRef;
- (void)deleteTrack:(NSString *)trackRef;
- (void)deletePlaylist:(NSString *)playlistRef;

@end
