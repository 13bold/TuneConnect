//
//  LFScrobbler.h
//  LFScrobbler
//
//  Created by Matt Patenaude on 2/18/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LFResponder.h"


@interface LFScrobbler : NSObject {
	LFResponder *responder;
	NSString *clientID;
	NSString *version;
	
	NSString *sessionID;
	NSURL *nowPlaying;
	NSURL *submission;
	
	NSString *user;
	NSString *pass;
	
	bool activeConnection;
	bool waitingOnSessionEnd;
	
	id delegate;
	
	bool trackPlaying;
	bool paused;
	NSDictionary *trackDict;
	NSDate *startTime;
	NSMutableArray *pauseTimes;
	
	bool secondBadSession;
	
	NSMutableArray *requestQueue;
}

/* --------------------- PUBLIC METHODS --------------------- */

// Set a delegate for Scrobbler responses
- (void)setDelegate:(id)newDelegate;
- (id)delegate;

// All clients interfacing with Last.fm are required to
// have their own client ID. Obtain one for your client
// by contacting russ@last.fm, then assign it with this method
// before logging in. You should also provide the version of
// your application. If a client ID is not set, the testing ID
// will be used.
- (void)setClientID:(NSString *)newID version:(NSString *)newVersion;

// Perform a handshake with the Scrobbler service
// Username and password are required, recommended you store
// them in the Keychain.
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;

// A track has started playing. Yay!
// The dictionary should contain the following keys:
//		name (NSString): track's name
//		artist (NSString): track's artist
//		album (NSString): track's album (empty string if not known)
//		mbID (NSString): MusicBrainz ID (optional)
//		length (NSNumber): track's length in seconds
//		number (NSNumber): track's position on album (optional)
- (void)playTrack:(NSDictionary *)track;

// Current track has stopped playing.
// Sending this will Scrobble the track, if the previous track has been playing
// for more than 320 seconds.
// Alternatively, you can simply send another playTrack: command
- (void)stop;

// Current track has been paused.
// This stops the play counter temporarily.
- (void)pause;

// Current track has resumed after pause.
// This resumes the play counter where it left off.
- (void)resume;

// Perform a "stop" and send any un-Scrobbled changes, then discard
// session ID, linked URLs, and any stored username/password
// information.
- (void)endSession;

/* --------------------- PRIVATE METHODS --------------------- */

- (void)_stopEndingSession:(bool)endSession;
- (void)_sessionEnded;

- (void)_sendRequestsInQueue;

- (void)_connectionFailedOnRequest:(NSURLRequest *)request;

- (void)_handshakeReceived:(NSString *)rawResponse forRequest:(NSURLRequest *)request;
- (void)_submissionPosted:(NSString *)rawResponse forRequest:(NSURLRequest *)request;
- (void)_nowPlayingPosted:(NSString *)rawResponse forRequest:(NSURLRequest *)request;

@end
