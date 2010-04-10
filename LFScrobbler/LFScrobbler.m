//
//  LFScrobbler.m
//  LFScrobbler
//
//  Created by Matt Patenaude on 2/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LFScrobbler.h"
#import "CocoaCryptoHashing.h"
#import "NSString+LFURLAdditions.h"


@implementation LFScrobbler

- (id)init
{
	if (self = [super init])
	{
		responder = [[LFResponder alloc] initWithController:self];
		clientID = @"tst";
		version = @"1.0";
		
		user = @"storedUser";
		pass = @"storedPass";
		
		trackPlaying = NO;
		paused = NO;
		
		secondBadSession = NO;
		
		requestQueue = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	if (delegate)
		[delegate release];
	
	if (sessionID)
		[sessionID release];
	
	if (nowPlaying)
		[nowPlaying release];
	
	if (submission)
		[submission release];
	
	if (trackDict)
		[trackDict release];
		
	if (startTime)
		[startTime release];
	
	if (pauseTimes)
		[pauseTimes release];
	
	[clientID release];
	[version release];
	[requestQueue release];
	[responder release];
	[super dealloc];
}

/* --------------------- PUBLIC METHODS --------------------- */

// Set a delegate for Scrobbler responses
- (void)setDelegate:(id)newDelegate
{
	if (delegate)
	{
		[delegate release];
		delegate = nil;
	}
	delegate = [newDelegate retain];
}
- (id)delegate
{
	return delegate;
}

// All clients interfacing with Last.fm are required to
// have their own client ID. Obtain one for your client
// by contacting russ@last.fm, then assign it with this method
// before logging in. You should also provide the version of
// your application. If a client ID is not set, the testing ID
// will be used.
- (void)setClientID:(NSString *)newID version:(NSString *)newVersion
{
	if (clientID)
	{
		[clientID release];
		clientID = nil;
	}
	
	clientID = [newID copy];
	
	if (version)
	{
		[version release];
		version = nil;
	}
	
	version = [newVersion copy];
}

// Perform a handshake with the Scrobbler service
// Username and password are required, recommended you store
// them in the Keychain.
- (void)loginWithUsername:(NSString *)username password:(NSString *)password
{
	if (username == nil)
	{
		username = user;
		password = pass;
	}
	else
	{
		if (user)
		{
			[user release];
			user = nil;
		}
		if (pass)
		{
			[pass release];
			pass = nil;
		}
		user = [username copy];
		pass = [password copy];
	}
	
	int timestamp = [[NSDate date] timeIntervalSince1970];
	NSString *authToken = [[NSString stringWithFormat:@"%@%d", [password md5HexHash], timestamp] md5HexHash];
	NSString *urlString = [NSString stringWithFormat:@"http://post.audioscrobbler.com/?hs=true&p=1.2&c=%@&v=%@&u=%@&t=%d&a=%@", clientID, version, username, timestamp, authToken];
	
	NSURL *hsURL = [NSURL URLWithString:urlString];
	
	[responder beginConnectionWithRequest:[NSURLRequest requestWithURL:hsURL] withTarget:self selector:@selector(_handshakeReceived:forRequest:)];
}

// A track has started playing. Yay!
// The dictionary should contain the following keys:
//		name (NSString): track's name
//		artist (NSString): track's artist
//		album (NSString): track's album (empty string if not known)
//		mbID (NSString): MusicBrainz ID (optional)
//		length (NSNumber): track's length in seconds
//		number (NSNumber): track's position on album (-1 if not known)
- (void)playTrack:(NSDictionary *)track
{
	[self stop];
	
	if (track != nil)
	{
		//NSLog(@"Starting track: %@", [track description]);
		trackPlaying = YES;
		startTime = [[NSDate date] retain];
		trackDict = [track copy];
		pauseTimes = [[NSMutableArray alloc] init];
		
		// Make a Now-Playing post
		if (activeConnection)
		{
			NSString *postFormat = @"s=%@&a=%@&t=%@&l=%d&b=%@&n=%@&m=%@";
			
			NSString *number;
			if (![[trackDict allKeys] containsObject:@"number"])
				number = @"";
			else
				number = [[trackDict objectForKey:@"number"] description];
			
			NSString *mbID;
			if (![[trackDict allKeys] containsObject:@"mbID"])
				mbID = @"";
			else
				mbID = [trackDict valueForKey:@"mbID"];
			
			// DEBUGGING
			NSString *session = [sessionID urlReadyString];
			//NSLog(@"Session: %@", session);
			
			NSString *artist = [[trackDict objectForKey:@"artist"] urlReadyString];
			//NSLog(@"Artist: %@", artist);
			
			NSString *name = [[trackDict objectForKey:@"name"] urlReadyString];
			//NSLog(@"Name: %@", name);
			
			int length = [[trackDict valueForKey:@"length"] intValue];
			//NSLog(@"Length (sec): %d", length);
			
			NSString *album = [[trackDict valueForKey:@"album"] urlReadyString];
			//NSLog(@"Album: %@", album);
			// END DEBUGGING
			
			NSString *post = [NSString stringWithFormat:postFormat,
				session,
				artist,
				name,
				length,
				album, 
				number,
				[mbID urlReadyString]];
			
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nowPlaying];
			[request setHTTPMethod:@"POST"];
			[request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
			//NSLog(@"Making now playing request");
			[responder beginConnectionWithRequest:request withTarget:self selector:@selector(_nowPlayingPosted:forRequest:)];
		}
	}
}

// Current track has stopped playing.
// Sending this will Scrobble the track, if the previous track has been playing
// for more than 320 seconds.
// Alternatively, you can simply send another playTrack: command
- (void)stop;
{
	[self _stopEndingSession:NO];
}
- (void)_stopEndingSession:(bool)endSession
{
	//NSLog(@"Stop received...");
	if (trackPlaying)
	{
		//NSLog(@"... and track was playing, so let's check it");
		trackPlaying = NO;
		NSDate *stopTime = [NSDate date];
		
		if (paused)
		{
			//NSLog(@"It had an open pause, so we're closing it");
			[[pauseTimes lastObject] setValue:[NSDate date] forKey:@"stop"];
			paused = NO;
		}
		
		if (activeConnection)
		{
			if ([[trackDict valueForKey:@"length"] intValue] >= 30)
			{
				int playTime = [stopTime timeIntervalSinceDate:startTime];
				
				NSEnumerator *enumerator = [pauseTimes objectEnumerator];
				NSDictionary *info;
				while (info = [enumerator nextObject])
				{
					int pauseTime = [[info valueForKey:@"stop"] timeIntervalSinceDate:[info valueForKey:@"start"]];
					playTime -= pauseTime;
				}
				
				float length = [[trackDict valueForKey:@"length"] floatValue];
				
				//NSLog(@"Play time was %d, length was %d", playTime, (int)length);
				if (playTime >= 240 || (float)playTime >= (length / 2.0))
				{
					//NSLog(@"Scrobbling...");
					// Let's Scrobble it! :)
					NSString *postFormat = @"s=%@&a[0]=%@&t[0]=%@&i[0]=%d&o[0]=P&r[0]=&l[0]=%d&b[0]=%@&n[0]=%@&m[0]=%@";
					
					NSString *number;
					if (![[trackDict allKeys] containsObject:@"number"])
						number = @"";
					else
						number = [[trackDict objectForKey:@"number"] description];
					
					NSString *mbID;
					if (![[trackDict allKeys] containsObject:@"mbID"])
						mbID = @"";
					else
						mbID = [trackDict valueForKey:@"mbID"];
					
					// DEBUGGING
					NSString *session = [sessionID urlReadyString];
					//NSLog(@"Session: %@", session);
					
					NSString *artist = [[trackDict objectForKey:@"artist"] urlReadyString];
					//NSLog(@"Artist: %@", artist);
					
					NSString *name = [[trackDict objectForKey:@"name"] urlReadyString];
					//NSLog(@"Name: %@", name);
					
					int starttime = [startTime timeIntervalSince1970];
					//NSLog(@"Start timestamp: %d", starttime);
					
					int length = [[trackDict valueForKey:@"length"] intValue];
					//NSLog(@"Length (sec): %d", length);
					
					NSString *album = [[trackDict valueForKey:@"album"] urlReadyString];
					//NSLog(@"Album: %@", album);
					// END DEBUGGING
					
					NSString *post = [NSString stringWithFormat:postFormat,
						session,
						artist,
						name,
						starttime,
						length,
						album, 
						number,
						[mbID urlReadyString]];
					
					//NSLog(@"Post created");
					
					//NSLog(@"Post request: %@ -- to URL: %@", post, [submission description]);
					NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:submission];
					//NSLog(@"We have a request, setting method");
					[request setHTTPMethod:@"POST"];
					//NSLog(@"Method set, setting body");
					[request setHTTPBody:[post dataUsingEncoding:NSUTF8StringEncoding]];
					
					//NSLog(@"Request: %@", [request description]);
					
					
					
					if (endSession)
					{
						NSURLResponse *res;
						[NSURLConnection sendSynchronousRequest:request returningResponse:&res error:nil];
						[self _sessionEnded];
					}
					else
					{
						[requestQueue addObject:request];
					
						//NSLog(@"Sending Scrobble request");
						[self _sendRequestsInQueue];
					}
				}
				else
				{
					if (endSession)
						[self _sessionEnded];
				}
			}
			else
			{
				if (endSession)
					[self _sessionEnded];
			}
		}
		else
		{
			if (endSession)
				[self _sessionEnded];
		}
		
		// Empty out old garbage
		[trackDict release];
		trackDict = nil;
		[startTime release];
		startTime = nil;
		[pauseTimes release];
		pauseTimes = nil;
	}
	else
	{
		if (endSession)
			[self _sessionEnded];
	}
}

// Current track has been paused.
// This stops the play counter temporarily.
- (void)pause
{
	if (trackPlaying)
	{
		paused = YES;
		
		NSMutableDictionary *pauseDict = [NSMutableDictionary dictionaryWithObject:[NSDate date] forKey:@"start"];
		[pauseTimes addObject:pauseDict];
	}
}

// Current track has resumed after pause.
// This resumes the play counter where it left off.
- (void)resume
{
	if (trackPlaying && paused)
	{
		paused = NO;
		
		[[pauseTimes lastObject] setValue:[NSDate date] forKey:@"stop"];
	}
}

// Perform a "stop" and send any un-Scrobbled changes, then discard
// session ID, linked URLs, and any stored username/password
// information.
- (void)endSession
{
	waitingOnSessionEnd = NO;
	[self _stopEndingSession:YES];
}

/* --------------------- PRIVATE METHODS --------------------- */
- (void)_errorForLogging:(NSString *)logString
{
	if ([delegate respondsToSelector:@selector(scrobblerError:)])
	{
		NSError *err = [NSError errorWithDomain:@"LFScrobblerErrorDomain" code:0 userInfo:[NSDictionary dictionaryWithObject:logString forKey:NSLocalizedDescriptionKey]];
		[delegate scrobblerError:err];
	}
	else
		NSLog(logString);
}

- (void)_sendRequestsInQueue
{
	NSMutableArray *requests = [[requestQueue copy] autorelease];
	NSEnumerator *enumerator = [requests objectEnumerator];
	
	[requestQueue removeAllObjects];
	
	//NSLog(@"Sending requests in queue");
	
	NSURLRequest *request;
	while (request = [enumerator nextObject])
	{
		//NSLog([request description]);
		[responder beginConnectionWithRequest:request withTarget:self selector:@selector(_submissionPosted:forRequest:)];
	}
}

- (void)_sessionEnded
{
	waitingOnSessionEnd = NO;
	
	if (user)
		[user release];
	user = @"storedUser";
	
	if (pass)
		[pass release];
	pass = @"storedPass";
	
	if (sessionID)
		[sessionID release];
	sessionID = nil;
	
	if (nowPlaying)
		[nowPlaying release];
	nowPlaying = nil;
	
	if (submission)
		[submission release];
	submission = nil;
	
	activeConnection = NO;
	trackPlaying = NO;
	paused = NO;
	secondBadSession = NO;
	
	if ([delegate respondsToSelector:@selector(sessionEnded)])
		[delegate sessionEnded];
}

- (void)_connectionFailedOnRequest:(NSURLRequest *)request
{
	[requestQueue addObject:request];
	if (waitingOnSessionEnd)
		[self _sessionEnded];
}

- (void)_handshakeReceived:(NSString *)rawResponse forRequest:(NSURLRequest *)request
{
	if ([delegate respondsToSelector:@selector(handshakeResponseReceived:)])
		[delegate handshakeResponseReceived:rawResponse];
	
	NSArray *info = [rawResponse componentsSeparatedByString:@"\n"];
	
	NSString *response = [info objectAtIndex:0];
	
	if ([response isEqual:@"OK"])
	{
		// Go on :)
		if (sessionID)
		{
			[sessionID release];
			sessionID = nil;
		}
		sessionID = [[info objectAtIndex:1] copy];
		//NSLog(@"Session ID: %@", sessionID);
		if (nowPlaying)
		{
			[nowPlaying release];
			nowPlaying = nil;
		}
		nowPlaying = [[NSURL URLWithString:[info objectAtIndex:2]] retain];
		if (submission)
		{
			[submission release];
			submission = nil;
		}
		submission = [[NSURL URLWithString:[info objectAtIndex:3]] retain];
		
		activeConnection = YES;
		
		NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
			sessionID, @"sessionID",
			nowPlaying, @"nowPlayingURL",
			submission, @"submissionURL",
			nil];
		
		if ([delegate respondsToSelector:@selector(scrobblerReady:)])
			[delegate scrobblerReady:settings];
		
		if ([requestQueue count] > 0)
			[self _sendRequestsInQueue];
	}
	else if ([response isEqual:@"BANNED"])
	{
		if ([delegate respondsToSelector:@selector(handshakeResponseBanned:)])
			[delegate handshakeResponseBanned:rawResponse];
	}
	else if ([response isEqual:@"BADAUTH"])
	{
		if ([delegate respondsToSelector:@selector(handshakeResponseBadAuth:)])
			[delegate handshakeResponseBadAuth:rawResponse];
	}
	else if ([response isEqual:@"BADTIME"])
	{
		//NSLog(@"LFScrobbler handshake failed, timestamp error: system clock problem?");
	}
	else
	{
		// General failure
		//NSLog([response description]);
		if ([delegate respondsToSelector:@selector(handshakeResponseFailed:)])
			[delegate handshakeResponseFailed:rawResponse];
	}
}

- (void)_submissionPosted:(NSString *)rawResponse forRequest:(NSURLRequest *)request
{
	//NSLog(@"Response received...");
	NSArray *info = [rawResponse componentsSeparatedByString:@"\n"];
	
	NSString *response = [info objectAtIndex:0];
	
	if ([response isEqual:@"OK"])
	{
		//NSLog(@"Scrobble successful!");
		secondBadSession = NO;
		
		if ([delegate respondsToSelector:@selector(submissionPosted:)])
			[delegate submissionPosted:rawResponse];
	}
	else if ([response isEqual:@"BADSESSION"])
	{
		activeConnection = NO;
		[requestQueue addObject:request];
		if (!secondBadSession)
		{
			//NSLog(@"LFScrobbler: invalid session, re-handshaking");
			secondBadSession = YES;
			[self loginWithUsername:nil password:nil];
		}
		else
		{
			//NSLog(@"LFScrobbler: invalid session received twice, new handshakes don't help");
			secondBadSession = NO;
		}
	}
	else
	{
		[requestQueue addObject:request];
		if ([delegate respondsToSelector:@selector(submissionFailed:)])
			[delegate submissionFailed:rawResponse];
	}
	
	if (waitingOnSessionEnd)
		[self _sessionEnded];
}

- (void)_nowPlayingPosted:(NSString *)rawResponse forRequest:(NSURLRequest *)request
{
	NSArray *info = [rawResponse componentsSeparatedByString:@"\n"];
	
	NSString *response = [info objectAtIndex:0];
	
	if ([response isEqual:@"OK"])
	{
		//NSLog(@"Now Playing update successful!");
		secondBadSession = NO;
		
		if ([delegate respondsToSelector:@selector(nowPlayingPosted:)])
			[delegate nowPlayingPosted:rawResponse];
	}
	else if ([response isEqual:@"BADSESSION"])
	{
		activeConnection = NO;
		if (!secondBadSession)
		{
			//NSLog(@"LFScrobbler: invalid session, re-handshaking");
			secondBadSession = YES;
			[self loginWithUsername:nil password:nil];
		}
		else
		{
			//NSLog(@"LFScrobbler: invalid session received twice, new handshakes don't help");
			secondBadSession = NO;
		}
	}
	else
	{
		if ([delegate respondsToSelector:@selector(nowPlayingFailed:)])
			[delegate nowPlayingFailed:rawResponse];
	}
}

@end
