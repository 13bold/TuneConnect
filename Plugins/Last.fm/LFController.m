//
//  LFController.m
//  Last.fm
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LFController.h"

static NSBundle *pluginBundle = nil;

@implementation LFController

- (id)initWithApp:(id)theApp
{
	if (self = [super init])
	{
		app = theApp;
		scrobbler = [[LFScrobbler alloc] init];
		[scrobbler setDelegate:self];
		[scrobbler setClientID:@"tcn" version:@"0.1"];
		
		NSImage *bar = [[[NSImage alloc] initByReferencingFile:[[pluginBundle resourcePath] stringByAppendingString:@"Lastfm-bar.png"]] autorelease];
		[sidebar setImage:bar];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"LFUser", [NSNumber numberWithBool:NO], @"LFEnabled", nil]];
		
		// Let's register for some notifications
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(trackChanged:) name:@"trackChanged" object:nil];
		[nc addObserver:self selector:@selector(playStateChanged:) name:@"playStateChanged" object:nil];
		
		// Prepare server, if possible
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LFEnabled"])
			[self performHandshake];
	}
	return self;
}

- (void)performHandshake
{
	// Time to contact the Scrobbler and get some info
	EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:@"Audioscrobbler" withUsername:[[NSUserDefaults standardUserDefaults] valueForKey:@"LFUser"]];
	
	if (keyItem)
		[scrobbler loginWithUsername:[keyItem username] password:[keyItem password]];
}

- (void)scrobblerReady:(NSDictionary *)settings
{
	NSLog(@"Communicating with Last.fm");
}

- (void)trackChanged:(NSNotification *)notification
{
	NSMutableDictionary *track = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
	if ([[track objectForKey:@"name"] isEqual:[NSNumber numberWithBool:NO]])
		[scrobbler stop];
	else
	{
		[track setValue:[track valueForKey:@"duration"] forKey:@"length"];
		[scrobbler playTrack:track];
		if ([[[app playerStatus] playState] isEqual:@"paused"])
			[scrobbler pause];
	}
}
- (void)playStateChanged:(NSNotification *)notification
{
	NSString *playState = [[notification userInfo] valueForKey:@"pState"];
	
	if ([playState isEqual:@"playing"])
		[scrobbler resume];
	else if ([playState isEqual:@"stopped"])
		[scrobbler stop];
	else if ([playState isEqual:@"paused"])
		[scrobbler pause];
}

- (void)doCleanup
{
	[scrobbler endSession];
}

- (void)sessionEnded
{
	[app replyToApplicationShouldTerminate:YES sender:self];
}

- (NSString *)username
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"LFUser"];
}
- (void)setUsername:(NSString *)newUsername
{
	if (![newUsername isEqual:@""])
	{
		EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:@"Audioscrobbler" withUsername:[self username]];
		if (keyItem)
			[keyItem setUsername:newUsername];
		else
			[[EMKeychainProxy sharedProxy] addGenericKeychainItemForService:@"Audioscrobbler" withUsername:newUsername password:[self password]];
			
		[[NSUserDefaults standardUserDefaults] setValue:newUsername forKey:@"LFUser"];
	}
	
	[scrobbler endSession];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LFEnabled"])
		[self performHandshake];
}

- (NSString *)password
{
	EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:@"Audioscrobbler" withUsername:[self username]];
	if (keyItem)
		return [keyItem password];
	else
		return @"";
}
- (void)setPassword:(NSString *)newPassword
{
	EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:@"Audioscrobbler" withUsername:[self username]];
	if (keyItem)
		[keyItem setPassword:newPassword];
		
	[scrobbler endSession];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"LFEnabled"])
		[self performHandshake];
}

- (IBAction)openLastFM:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.last.fm"]];
}

- (IBAction)changedEnabled:(id)sender
{
	if ([sender state] == NSOnState)
		[self performHandshake];
	else
		[scrobbler endSession];
}

- (void)handshakeResponseBadAuth:(NSString *)rawResponse
{
	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"LFEnabled"];
}

// PLUGIN STUFF BELOW THIS LINE

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
	LFController *c = [[[LFController alloc] initWithApp:serviceProvider] autorelease];
	
	NSEnumerator *result = [[NSArray arrayWithObject:c] objectEnumerator];
	return result;
}
- (NSView *)prefView
{
	[NSBundle loadNibNamed:@"LFUI" owner:self];
	return prefView;
}
- (NSString *)prefViewName
{
	return @"Last.fm";
}
+ (NSString *)pluginName
{
	return @"Last.fm";
}

- (NSMenu *)menu
{
	return nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification
{
	[self doCleanup];
	return NSTerminateLater;
}

@end
