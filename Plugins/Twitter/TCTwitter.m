//
//  TCTwitter.m
//  Twitter
//
//  Created by Matt Patenaude on 2/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCTwitter.h"

static NSBundle *pluginBundle = nil;

@implementation TCTwitter

// Implementation
- (id)initWithProvider:(id)newApp
{
	if (self = [super init])
	{
		app = [newApp retain];
		sharedResponder = [[TCTwitterAgent alloc] init];
		
		songPattern = [[pluginBundle localizedStringForKey:@"is listening to %@." value:@"is listening to %@." table:nil] retain];
		tagline = [[pluginBundle localizedStringForKey:@"via TuneConnect" value:@"via TuneConnect" table:nil] retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackChanged:) name:@"trackChanged" object:nil];
		updateURL = [[NSURL URLWithString:@"http://twitter.com/statuses/update.xml"] retain];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:20], @"TCTwitterMinSeconds", [NSNumber numberWithBool:YES], @"TCTwitterIncludeTCPlug", nil]];
	}
	return self;
}

- (void)dealloc
{
	if (currentTimer)
	{
		[currentTimer release];
		[currentTimer invalidate];
	}
	
	if (currentTrack)
		[currentTrack release];
	
	[songPattern release];
	[tagline release];
	
	[updateURL release];
	[sharedResponder release];
	[app release];
	[super dealloc];
}

- (void)trackChanged:(NSNotification *)notification
{
	if (currentTimer)
	{
		[currentTimer release];
		[currentTimer invalidate];
		currentTimer = nil;
	}
	
	if (currentTrack)
	{
		[currentTrack release];
		currentTrack = nil;
	}
	
	if (![[[notification userInfo] objectForKey:@"name"] isEqual:[NSNumber numberWithBool:NO]])
	{
		currentTrack = [[[app playerStatus] trackStatusDisplay] copy];
		currentTimer = [[NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] integerForKey:@"TCTwitterMinSeconds"] target:self selector:@selector(checkTimer:) userInfo:nil repeats:NO] retain];
	}
}

- (void)checkTimer:(NSTimer *)theTimer
{
	[currentTimer release];
	currentTimer = nil;
	
	if ([[[app playerStatus] trackStatusDisplay] isEqual:currentTrack])
	{
		// Submit for update to Twitter
		NSLog(@"Submitting for update: %@", [[app playerStatus] trackName]);
		
		NSString *trackString = [NSString stringWithFormat:@"\"%@\"", [[app playerStatus] trackName]];
		
		if (![[[app playerStatus] trackArtist] isEqual:@""])
			trackString = [trackString stringByAppendingFormat:@" (%@)", [[app playerStatus] trackArtist]];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TCTwitterIncludeTCPlug"])
			trackString = [trackString stringByAppendingFormat:@" %@", tagline];
		
		NSString *submission = [NSString stringWithFormat:@"status=%@", [[NSString stringWithFormat:songPattern, trackString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:updateURL];
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:[submission dataUsingEncoding:NSUTF8StringEncoding]];
		
		[NSURLConnection connectionWithRequest:request delegate:sharedResponder];
	}
	
	[currentTrack release];
	currentTrack = nil;
}

// Standard Plug-in Stuff
+ (BOOL)initializeClass:(NSBundle *)theBundle
{
	if (pluginBundle)
		return NO;
	
	pluginBundle = [theBundle retain];
	return YES;
}
+ (void)terminateClass
{
	[pluginBundle release];
	pluginBundle = nil;
}
+ (NSEnumerator *)pluginsFor:(id)serviceProvider
{
	id plugin = [[[self alloc] initWithProvider:serviceProvider] autorelease];
	return [[NSArray arrayWithObject:plugin] objectEnumerator];
}
+ (NSString *)pluginName
{
	return @"Twitter";
}
- (NSMenu *)menu
{
	return nil;
}
- (NSView *)prefView
{
	return nil;
}
- (NSString *)prefViewName
{
	return @"Twitter";
}

- (void)doCleanup
{
	// No clean-up to do
}

@end
