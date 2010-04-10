//
//  PlayerStatus.h
//  TuneConnect
//
//  Created by Matt Patenaude on 9/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Tunage/TCServer.h>
#import "InterfaceController.h"


@interface PlayerStatus : NSObject {
	NSString *trackName;
	NSString *trackArtist;
	NSString *trackAlbum;
	float trackDuration;
	
	NSString *trackGenre;
	int trackRating;
	NSString *trackComposer;
	
	NSString *playState;
	int playerVolume;
	int premuteVolume;
	int playerPosition;
	
	TCServer *server;
	
	NSTimer *updater;
	
	NSString *oldTrack;
	int oldRating;
	NSString *oldAlbum;
	
	id appController;
	
	int volumeCycle;
	bool dragInProgress;
}

- (TCServer *)server;
- (void)setServer:(TCServer *)newServer;

- (id)appController;
- (void)setAppController:(id)newController;

- (NSString *)trackName;
- (void)setTrackName:(NSString *)newTrackName;

- (NSString *)trackArtist;
- (void)setTrackArtist:(NSString *)newTrackArtist;

- (NSString *)trackAlbum;
- (void)setTrackAlbum:(NSString *)newTrackAlbum;

- (float)trackDuration;
- (void)setTrackDuration:(float)newTrackDuration;

- (NSString *)trackGenre;
- (void)setTrackGenre:(NSString *)newTrackGenre;

- (float)trackRating;
- (void)setTrackRating:(float)newTrackRating;

- (NSString *)ratingString;

- (NSString *)trackComposer;
- (void)setTrackComposer:(NSString *)newTrackComposer;

- (NSString *)playState;
- (void)setPlayState:(NSString *)newPlayState;

- (int)playerVolume;
- (void)setPlayerVolume:(int)newPlayerVolume;
- (void)muteUnmute;

- (int)playerPosition;
- (void)setPlayerPosition:(int)newPlayerPosition;

- (NSString *)timeElapsed;
- (NSString *)timeRemaining;

- (NSString *)trackStatusDisplay;

- (void)beginUpdatingFromServer:(TCServer *)theServer;

- (void)continueUpdateCycle:(NSTimer *)oldTimer;
- (void)handleUpdates:(NSDictionary *)response;

- (void)dragInProgress:(bool)inProg;

@end
