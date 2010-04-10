//
//  LFScrobblerDelegate.h
//  LFScrobbler
//
//  Created by Matt Patenaude on 2/18/08.
//  Copyright 2008 Matt Patenaude. All rights reserved.
//

@protocol LFScrobblerDelegate

// Fired when a handshake response is first received;
// the raw server response is passed as a parameter.
- (void)handshakeResponseReceived:(NSString *)rawResponse;

// Fired when a handshake response is received, and returns
// a BANNED status; the raw server response is passed as
// a parameter.
- (void)handshakeResponseBanned:(NSString *)rawResponse;

// Fired when a handshake response is received, and returns
// a BADAUTH status (check the username and password); the
// raw server response is passed as a parameter.
- (void)handshakeResponseBadAuth:(NSString *)rawResponse;

// Fired when a handshake response is received, and returns
// a general failure; the raw server response is passed as
// a parameter. NOTE: this is ONLY sent if the response is
// not one of OK, BANNED, BADAUTH, or BADTIME.
- (void)handshakeResponseFailed:(NSString *)rawResponse;

// Fired when a handshake response is received, and returns
// an OK status. This indidcates that the Scrobbler is ready
// to receive track information. The server settings (sessionID (NSString),
// nowPlayingURL (NSURL), and submissionURL (NSURL)) are returned
// as a dictionary.
- (void)scrobblerReady:(NSDictionary *)settings;

// Fired when a submission cannot be sent to Last.fm for an
// unknown reason; the raw server response is passed as a
// parameter.
- (void)submissionFailed:(NSString *)rawResponse;

// Fired when a submission is successfully posted to Last.fm;
// the raw server response is passed as a parameter.
- (void)submissionPosted:(NSString *)rawResponse;

// Fired when a Now Playing update cannot be sent to Last.fm
// for an unknown reason; the raw server response is passed as
// a paramter.
- (void)nowPlayingFailed:(NSString *)rawResponse;

// Fired when a Now Playing update is successfully posted to
// Last.fm; the raw server response is passed as a paramter.
- (void)nowPlayingPosted:(NSString *)rawResponse;

// Fired when a session successfully completes.
- (void)sessionEnded;
@end