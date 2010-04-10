//
//  TCServerWrapper.h
//  Tunage
//
//  Created by Matt Patenaude on 2/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCServer.h"

typedef enum _TCServerRepeatSetting {
	TCServerRepeatOff = 0,
	TCServerRepeatOne = 1,
	TCServerRepeatAll = 2
} TCServerRepeatSetting;

typedef enum _TCServerVisualsSize {
	TCServerVisualsSmall = 0,
	TCServerVisualsMedium = 1,
	TCServerVisualsLarge = 2
} TCServerVisualsSize;

@interface TCServerWrapper : NSObject {
	TCServer *server;
}

- (id)initWithServer:(TCServer *)theServer;

- (NSDictionary *)serverInfo;
- (NSString *)authKeyForPassword:(NSString *)password prehashed:(bool)hashed;

- (NSArray *)sources;

- (NSArray *)playlistsOfSource:(NSString *)sourceRef;
- (NSString *)signatureOfPlaylist:(NSString *)playlistRef;
- (NSString *)signatureOfPlaylist:(NSString *)playlistRef includingGenres:(bool)genres ratings:(bool)ratings composers:(bool)composers comments:(bool)comments;

- (NSArray *)tracksOfPlaylist:(NSString *)playlistRef;
- (NSArray *)tracksOfPlaylist:(NSString *)playlistRef includingGenres:(bool)genres ratings:(bool)ratings composers:(bool)composers comments:(bool)comments;

- (NSDictionary *)tracksOfPlaylistWithSignature:(NSString *)playlistRef;
- (NSDictionary *)tracksOfPlaylistWithSignature:(NSString *)playlistRef includingGenres:(bool)genres ratings:(bool)ratings composers:(bool)composers comments:(bool)comments;

- (void)play;
- (void)pause;
- (void)playPause;
- (void)stop;
- (void)playPlaylist:(NSString *)playlistRef;
- (void)playTrack:(NSString *)trackRef;
- (void)playTrack:(NSString *)trackRef once:(bool)playOnce;
- (void)nextTrack;
- (void)prevTrack;

- (void)setVolume:(int)newVolume;
- (void)volumeUp;
- (void)volumeDown;

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
