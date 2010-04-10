//
//  LFScrobbler.h
//  LFScrobbler
//
//  Created by Matt Patenaude on 2/18/08.
//  Copyright (C) 2008 Matt Patenaude. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Cocoa/Cocoa.h>
#import "LFResponder.h"

/*!
@header LFScrobber.framework
LFScrobbler is a framework for interfacing with Last.fm's Audioscrobbler technology.
*/

/*!
@class LFScrobbler
@abstract An LFScrobbler object is used to maintain communication with the Audioscrobbler service.
@discussion The purpose of the LFScrobbler class is to encapsulate all of the functions necessary to compute
information for Audioscrobbler into one centrallized location. All you, the developer, needs to do is
tell your LFScrobbler object (created the normal way, [[LFScrobbler alloc] init]) when a new track starts
playing, when your user pauses the client, when they resume from being paused, and when they stop the
client. LFScrobbler takes care of all the logic required to decide whether or not a track should be
scrobbled, and does the scrobbling if it's required.
*/
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

/*!
@method setDelegate:
@param newDelegate An object to act as a delegate of the LFScrobbler object, implementing any assortment of
methods from @link NSObject(LFScrobblerDelegate) LFScrobblerDelegate@/link.
@abstract Set the delegate of the LFScrobbler object.
*/
- (void)setDelegate:(id)newDelegate;
/*!
@method delegate
@abstract Get the delegate used by the LFScrobbler object.
@result Returns the delegate of the LFScrobbler object.
*/
- (id)delegate;

/*!
@method setClientID:version:
@param newID The client ID assigned to you by Last.fm.
@param newVersion The version of your client.
@abstract Set the client ID of your software for use with Audioscrobbler.
@discussion All clients interfacing with Last.fm are required to have their own client ID. Obtain one for
your client by contacting russ\@last.fm, then assign it with this method before logging in. You should
also provide the version of your application. If a client ID is not set, the testing ID will be used.
*/
- (void)setClientID:(NSString *)newID version:(NSString *)newVersion;

/*!
@method loginWithUsername:password:
@param username Username of the application's user on Last.fm.
@param password Password of the application's user on Last.fm.
@abstract Login to the Last.fm service.
@discussion This method performs a handshake with the Scrobbler service to begin communication.
It is recommended that you store the username and password in the Keychain, rather than in cleartext.
*/
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;

/*!
@method playTrack:
@param track Information on the track that has just started playing. The dictionary should contain the following keys:
		name (NSString): track's name;
		artist (NSString): track's artist;
		album (NSString): track's album (empty string if not known);
		mbID (NSString): MusicBrainz ID (optional);
		length (NSNumber): track's length in seconds;
		number (NSNumber): track's position on album (optional);
@abstract Tell LFScrobbler that a new track has started playing.
@discussion It is unnecessary to first send a @link stop stop@/link command to LFScrobbler: calling playTrack:
automatically does this.
*/
- (void)playTrack:(NSDictionary *)track;

/*!
@method stop
@abstract Tell LFScrobbler that the current track has stopped playing.
@discussion Sending this will Scrobble the track, if the previous track has been playing
for more than 320 seconds. Alternatively, you can simply send a playTrack: command if a new track
has started playing (you do not need to send both commands).
*/
- (void)stop;

/*!
@method pause
@abstract Tell LFScrobbler that the user has paused the client.
@discussion This method stops the play counter temporarily, which is important for sending
accurate play statisticts to Last.fm
*/
- (void)pause;

/*!
@method resume
@abstract Tell LFScrobbler that the user has resumed playing the track.
@discussion This resumes the play counter where it left off.
*/
- (void)resume;

/*!
@method endSession
@abstract Indicate that a session has ended.
@discussion This method performs a "stop" and sends any un-Scrobbled changes to Audioscrobbler. Note that
this method uses a blocking request, rather than an asynchronous one. This can present problems, but also
allows you to use it in an applicationWillQuit: environment.
*/
- (void)endSession;

/* --------------------- PRIVATE METHODS --------------------- */
- (void)_errorForLogging:(NSString *)logString;

- (void)_stopEndingSession:(bool)endSession;
- (void)_sessionEnded;

- (void)_sendRequestsInQueue;

- (void)_connectionFailedOnRequest:(NSURLRequest *)request;

- (void)_handshakeReceived:(NSString *)rawResponse forRequest:(NSURLRequest *)request;
- (void)_submissionPosted:(NSString *)rawResponse forRequest:(NSURLRequest *)request;
- (void)_nowPlayingPosted:(NSString *)rawResponse forRequest:(NSURLRequest *)request;

@end


/*!
@category NSObject(LFScrobblerDelegate)
@abstract Methods for delegates of LFScrobbler.
@discussion Delegates of LFScrobbler can implement any or all of these methods in order
to respond to the feedback provided by LFScrobbler.
*/
@interface NSObject(LFScrobblerDelegate)
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

// Fired when there is a generic error that LFScrobbler cannot
// handle.
- (void)scrobblerError:(NSError *)error;
@end