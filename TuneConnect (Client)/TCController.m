//
//  TCController.m
//  TuneConnect
//
//  Created by Matt Patenaude on 9/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TCController.h"
#import "EMKeychainProxy.h"

@implementation TCController

+ (void)initialize
{
	TCBitrateTransformer *brTransform = [[[TCBitrateTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:brTransform forName:@"BitrateTransform"];
	
	TCSampleRateTransformer *sampTransform = [[[TCSampleRateTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:sampTransform forName:@"SampleRateTransform"];
	
	TCISODateFormatter *dateTransform = [[[TCISODateFormatter alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:dateTransform forName:@"ISODateTransform"];
	
	TCPlaylistImage *imageTransform = [[[TCPlaylistImage alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:imageTransform forName:@"PlaylistKindImage"];
	
	TCArrayCount *arrayCount = [[[TCArrayCount alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:arrayCount forName:@"ArrayCountPositive"];
}

- (id)init
{
	if (self = [super init])
	{
		[GrowlApplicationBridge setGrowlDelegate:@""];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
		[nc addObserver:self selector:@selector(trackChanged:) name:@"trackChanged" object:nil];
		[nc addObserver:self selector:@selector(albumChanged:) name:@"albumChanged" object:nil];
		[nc addObserver:self selector:@selector(ratingChanged:) name:@"ratingChanged" object:nil];
		[nc addObserver:self selector:@selector(interfaceChanged:) name:@"interfaceDidChange" object:nil];
		
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
		
		// Prepare for plug-ins
		pluginClasses = [[NSMutableArray alloc] init];
		pluginInstances = [[NSMutableArray alloc] init];
		plugins = [[NSMutableArray alloc] init];
		waitingOnPlugins = [[NSMutableArray alloc] init];
		appCanTerminate = YES;
		
		pluginsLoaded = NO;
	}
	return self;
}

- (id)app
{
	return NSApp;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	//NSLog(@"Open file command received");
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *appSupport = [@"~/Library/Application Support/TuneConnect" stringByExpandingTildeInPath];
	BOOL isDir;
	
	if (![fm fileExistsAtPath:appSupport isDirectory:&isDir])
		[fm createDirectoryAtPath:appSupport attributes:nil];
	else if (!isDir)
		return NO;
	
	NSString *destination = [appSupport stringByAppendingPathComponent:[filename lastPathComponent]];
	
	if ([fm isDeletableFileAtPath:destination])
		[fm removeFileAtPath:destination handler:nil];
	
	BOOL success = [[NSFileManager defaultManager] copyPath:filename toPath:destination handler:nil];
	
	if (pluginsLoaded && success)
	{
		Class pluginClass = [self classForPlugin:destination];
		[self instantiatePlugins:pluginClass];
	}
	
	return success;
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool:YES], @"animateWindowResize",
		[NSNumber numberWithBool:YES], @"SUCheckAtStartup",
		[NSNumber numberWithBool:YES], @"nameColumn",
		[NSNumber numberWithBool:YES], @"timeColumn",
		[NSNumber numberWithBool:YES], @"artistColumn",
		[NSNumber numberWithBool:YES], @"albumColumn",
		[NSNumber numberWithBool:YES], @"ratingColumn",
		[NSNumber numberWithBool:NO], @"genreColumn",
		[NSNumber numberWithBool:NO], @"composerColumn",
		[NSNumber numberWithBool:NO], @"commentsColumn",
		[NSNumber numberWithBool:NO], @"dateAddedColumn",
		[NSNumber numberWithBool:NO], @"bitrateColumn",
		[NSNumber numberWithBool:NO], @"sampleRateColumn",
		[NSNumber numberWithBool:YES], @"compactViewAlwaysOnTop",
		[NSNumber numberWithBool:NO], @"useCompactView",
		[NSNumber numberWithBool:NO], @"menuBarControls",
		@"{650, 547}", @"musicBrowserSize",
		@"{0, 0}", @"windowOrigin",
		[NSNumber numberWithInt:49], @"playPauseHotkey",
		[NSNumber numberWithInt:(NSControlKeyMask + NSShiftKeyMask)], @"playPauseHotkeyMod",
		[NSNumber numberWithInt:124], @"nextTrackHotkey",
		[NSNumber numberWithInt:(NSControlKeyMask + NSShiftKeyMask)], @"nextTrackHotkeyMod",
		[NSNumber numberWithInt:123], @"prevTrackHotkey",
		[NSNumber numberWithInt:(NSControlKeyMask + NSShiftKeyMask)], @"prevTrackHotkeyMod",
		[NSNumber numberWithInt:125], @"muteHotkey",
		[NSNumber numberWithInt:(NSControlKeyMask + NSShiftKeyMask)], @"muteHotkeyMod",
		[NSArray array], @"disabledPlugins",
		nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (Class)classForPlugin:(NSString *)pluginPath
{
	NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];
	
	if (pluginBundle)
	{
		NSDictionary *pluginInfo = [pluginBundle infoDictionary];
		NSString *pluginName = [pluginInfo valueForKey:@"NSPrincipalClass"];
		
		if (pluginName)
		{
			// If this line succeeds, we have to skip initialization
			// It indicates that our plugin's class already exists in the symbol table
			Class pluginClass = NSClassFromString(pluginName);
			
			if (!pluginClass)
			{
				if ([pluginName hasPrefix:@"TC"] && ![pluginInfo hasKey:@"TCAuthorVerified"])
					NSLog(@"Warning: plug-in uses TC class prefix in \"%@\"; may malfunction/crash!", pluginName);
				
				pluginClass = [pluginBundle principalClass];
				
				if ([pluginClass conformsToProtocol:@protocol(TCPlugin)] &&
					[pluginClass isKindOfClass:[NSObject class]] &&
					[pluginClass initializeClass:pluginBundle])
				{
					return pluginClass;
				}
			}
		}
	}
	return nil;
}

- (void)activatePlugin:(NSString *)pluginPath
{
	Class pluginClass = [self classForPlugin:pluginPath];
	if (pluginClass != nil) [pluginClasses addObject:pluginClass];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[hotkeyController updateHotkeysFromDefaults];
	
	//NSLog(@"Beginning main plug-in load loop");
	// Load up the plug-ins
	[[TCPluginServiceProvider sharedServiceProvider] setAppController:self];
	
	NSString *pluginDir = [[NSBundle mainBundle] builtInPlugInsPath];
	if (pluginDir)
	{
		NSEnumerator *enumerator = [[NSBundle pathsForResourcesOfType:@"tcplugin" inDirectory:pluginDir] objectEnumerator];
		NSString *pluginPath;
		while (pluginPath = [enumerator nextObject])
		{
			[self activatePlugin:pluginPath];
		}
	}
	
	NSString *globalPluginDir = [@"~/Library/Application Support/TuneConnect" stringByExpandingTildeInPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:globalPluginDir])
	{
		NSEnumerator *globalEnum = [[NSBundle pathsForResourcesOfType:@"tcplugin" inDirectory:globalPluginDir] objectEnumerator];
		NSString *gPath;
		while (gPath = [globalEnum nextObject])
		{
			[self activatePlugin:gPath];
		}
	}
	
	pluginsLoaded = YES;
	// Instantiate the plugins
	NSEnumerator *enumerator = [pluginClasses objectEnumerator];
	Class pluginClass;
	
	while (pluginClass = [enumerator nextObject])
	{
		[self instantiatePlugins:pluginClass];
	}
}

- (void)instantiatePlugins:(Class)pluginClass
{
	NSString *pluginName;
	if ([pluginClass pluginName])
		pluginName = [pluginClass pluginName];
	else
		pluginName = [[[NSBundle bundleForClass:pluginClass] infoDictionary] valueForKey:@"NSPrincipalClass"];
	
	TCPluginController *pController = [TCPluginController controllerForPlugin:pluginClass];
	[pController setName:pluginName];
	[pController setDisableValue:YES];
	[self willChangeValueForKey:@"plugins"];
	[plugins addObject:pController];
	
	if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"disabledPlugins"] containsObject:pluginName])
	{
		[pController setDisableValue:NO];
		
		NSEnumerator *pluginsToLoad = [pluginClass pluginsFor:[TCPluginServiceProvider sharedServiceProvider]];
		
		NSObject<TCPlugin> *plugin;
		
		while (plugin = [pluginsToLoad nextObject])
		{
			NSView *prefView = [plugin prefView];
			if (prefView)
			{
				NSTabViewItem *tab = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
				NSRect frame = [prefsView contentRect];
				
				[prefView setFrame:frame];
				[tab setView:prefView];
				[tab setLabel:[plugin prefViewName]];
				
				[prefsView addTabViewItem:tab];
			}
			
			NSMenu *menu = [plugin menu];
			if (menu)
			{
				if ([[pluginMenu itemAtIndex:0] tag] == 424242)
					[pluginMenu removeItemAtIndex:0];
				
				NSMenuItem *plugItem = [pluginMenu addItemWithTitle:pluginName action:NULL keyEquivalent:@""];
				[pluginMenu setSubmenu:menu forItem:plugItem];
			}
			
			[pluginInstances addObject:plugin];
		}
	}
	[self didChangeValueForKey:@"plugins"];
}

- (NSArray *)plugins
{
	return plugins;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification
{
	appCanTerminate = YES;
	NSApplicationTerminateReply reply = NSTerminateNow;
	
	// We need to ask all of our plugins (sigh)
	NSEnumerator *enumerator = [pluginInstances objectEnumerator];
	NSObject<TCPlugin> *plugin;
	
	while (plugin = [enumerator nextObject])
	{
		if ([plugin respondsToSelector:@selector(applicationShouldTerminate:)])
		{
			NSApplicationTerminateReply response;
			response = [plugin applicationShouldTerminate:aNotification];
			if (response == NSTerminateCancel)
				reply = NSTerminateCancel;
			else if (response == NSTerminateLater && reply != NSTerminateCancel)
			{
				reply = NSTerminateLater;
				[waitingOnPlugins addObject:plugin];
			}
		}
	}
	
	return reply;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)plugin:(id)plugin repliedToTermination:(bool)theReply
{
	[waitingOnPlugins removeObject:plugin];
	
	if (theReply == NO)
		appCanTerminate = NO;
	
	if ([waitingOnPlugins count] == 0)
		[NSApp replyToApplicationShouldTerminate:appCanTerminate];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Ditch our plugins
	[pluginInstances release];
	pluginInstances = nil;
	
	NSEnumerator *enumerator = [pluginClasses objectEnumerator];
	Class pluginClass;
	while (pluginClass = [enumerator nextObject])
	{
		[pluginClass terminateClass];
	}
	
	[pluginClasses release];
	pluginClasses = nil;
	
	[interface windowWillClose:[NSNotification notificationWithName:@"WindowWillCloseOHNO" object:self]];
}

- (void)awakeFromNib
{
	[interface composeInterface];
	[interface setInterface:TCConnect];
	
	[self willChangeValueForKey:@"playerStatus"];
	playerStatus = [[PlayerStatus alloc] init];
	[playerStatus setAppController:self];
	[self didChangeValueForKey:@"playerStatus"];
	[bonjour beginBrowsing];
}

- (TCServer *)server
{
	return server;
}
- (void)setServer:(TCServer *)newServer
{
	[server release];
	server = newServer;
}

- (bool)connected
{
	if (server)
		return [server activeConnection];
	else
		return NO;
}

- (MusicTree *)musicTree
{
	return musicTree;
}

- (NSArrayController *)playlists
{
	return playlists;
}

- (void)setMusicTree:(MusicTree *)newMusicTree
{
	musicTree = newMusicTree;
}

- (PlayerStatus *)playerStatus
{
	return playerStatus;
}

- (void)setPlayerStatus:(PlayerStatus *)newPlayerStatus
{
	playerStatus = newPlayerStatus;
}

- (Visualizations *)visuals
{
	return visuals;
}

- (void)setVisuals:(Visualizations *)newVisuals
{
	visuals = newVisuals;
}

- (Equalizations *)equalizations
{
	return equalizations;
}
- (void)setEqualizations:(Equalizations *)newEqualizations
{
	equalizations = newEqualizations;
}

- (IBAction)makeConnection:(id)sender
{
	[bonjour connectToCurrentlySelectedHost];
}

- (void)cancelCurrentConnection
{
	awaitingAuthentication = NO;
	[passwordField setStringValue:@""];
	
	// Don't know why releasing causes problems
	// Occurs in [server dealloc]
	//if (server) [server release];
}

- (void)startConnectionWithAddress:(NSString *)address andPort:(NSString *)port withIdentifier:(NSString *)ident
{
	if ([self connected])
	{
		[server release];
		server = nil;
	}
	[interface setInterface:TCConnecting];
	server = [[TCServer alloc] initWithAddress:address andPort:port];
	[server setDelegate:self];
	if (ident != nil) [server setIdentifier:ident];
	[server openConnection];
}

- (void)serverReady:(TCServer *)theServer
{
	if (awaitingAuthentication)
	{
		//[passwordChecking stopAnimation:self];
		//[passwordPanel close];
		[passwordField setStringValue:@""];
		awaitingAuthentication = NO;
	}
	
	[self willChangeValueForKey:@"connected"];
	// Changing the connected value
	[self didChangeValueForKey:@"connected"];
	
	// Yay
	[self willChangeValueForKey:@"musicTree"];
	
	musicTree = [[MusicTree alloc] init];
	[musicTree setServer:server];
	[musicTree setInterfaceController:interface];
	
	[self didChangeValueForKey:@"musicTree"];
	
	[playerStatus beginUpdatingFromServer:server];
	
	[trackInfo setChangeInterval:10];
	[trackInfo bind:@"stringValues" toObject:playerStatus withKeyPath:@"alternatingStatusDisplay" options:nil];
	[trackInfoCompact setChangeInterval:10];
	[trackInfoCompact bind:@"stringValues" toObject:playerStatus withKeyPath:@"alternatingStatusDisplay" options:nil];
	
	[self willChangeValueForKey:@"visuals"];
	visuals = [[Visualizations alloc] init];
	[visuals setServer:server];
	[self didChangeValueForKey:@"visuals"];
	
	[self willChangeValueForKey:@"equalizations"];
	equalizations = [[Equalizations alloc] init];
	[equalizations setServer:server];
	[self didChangeValueForKey:@"equalizations"];
	
	[GrowlApplicationBridge
		notifyWithTitle:NSLocalizedString(@"Connected to Server", nil)
		description:[NSString stringWithFormat:NSLocalizedString(@"A connection was made to the server at %@", nil), [server serverAddress]]
		notificationName:@"Connected to Server"
		iconData:nil
		priority:0
		isSticky:NO
		clickContext:nil];
	
	// All finished, show the playback interface
	[interface setInterface:[interface playbackMode]];
}

- (void)serverNeedsAuthentication:(TCServer *)theServer
{
	if (awaitingAuthentication)
	{
		if (usingKeychain)
		{
			[passwordDescription setStringValue:NSLocalizedString(@"Please enter your password", nil)];
			NSLog(@"Invalid password in Keychain");
			usingKeychain = NO;
		}
		else
			[passwordDescription setStringValue:NSLocalizedString(@"Invalid password. Please try again.", nil)];
	}
	else
	{
		awaitingAuthentication = YES;
		usingKeychain = NO;
		
		// Let's check for a Keychain item
		EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:[NSString stringWithFormat:@"%@ (TuneConnect)", [server identifier]] withUsername:@"TC"];
		if (keyItem)
		{
			usingKeychain = YES;
			[server getAuthKeyForPassword:[keyItem password]];
			return;
		}
		
		[passwordDescription setStringValue:NSLocalizedString(@"Please enter your password", nil)];
	}
	
	[interface setInterface:TCPassword];
}

- (void)serverConnectionError:(NSError *)error
{
	[interface connectionFailedWithError:error];
	[self willChangeValueForKey:@"connected"];
	// Changing the connected value
	[self didChangeValueForKey:@"connected"];
}

- (void)badServerVersion:(NSString *)badVersion requires:(NSString *)requiredVersion
{
	[self willChangeValueForKey:@"connected"];
	// Changing the connected value
	[self didChangeValueForKey:@"connected"];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithFormat:NSLocalizedString(@"Bad Version Error", nil), badVersion, requiredVersion], NSLocalizedDescriptionKey,
		nil];
	
	[interface connectionFailedWithError:[NSError errorWithDomain:@"TCConnectionError" code:42 userInfo:userInfo]];
}

- (void)interfaceChanged:(NSNotification *)changeNotification
{
	NSArray *selection;
	switch ([[[changeNotification userInfo] valueForKey:@"mode"] intValue])
	{
		case TCMusicBrowser:
			// Check for updates on current playlist
			selection = [playlists selectedObjects];
			if (selection && [selection count] > 0)
				[[selection objectAtIndex:0] checkForUpdates];
			
			break;
		case TCConnect:
			[self willChangeValueForKey:@"connected"];
			// Changing the connected value
			[self didChangeValueForKey:@"connected"];
			break;
		default:
			// Don't particularly care
			break;
	}
}

- (void)checkPasswordInField
{
	if ([storePassword state] == NSOnState)
	{
		EMGenericKeychainItem *keyItem = [[EMKeychainProxy sharedProxy] genericKeychainItemForService:[NSString stringWithFormat:@"%@ (TuneConnect)", [server identifier]] withUsername:@"TC"];
		if (keyItem) [keyItem setPassword:[passwordField stringValue]];
		else
			[[EMKeychainProxy sharedProxy] addGenericKeychainItemForService:[NSString stringWithFormat:@"%@ (TuneConnect)", [server identifier]] withUsername:@"TC" password:[passwordField stringValue]];
	}
	[interface setInterface:TCConnecting];
	[server getAuthKeyForPassword:[passwordField stringValue]];
}


- (IBAction)chooseMusic:(id)sender
{
	[interface setInterface:TCMusicBrowser];
}
- (IBAction)showEqualizer:(id)sender
{
	[interface setInterface:TCEqualizer];
}
- (IBAction)showVisualizations:(id)sender
{
	[interface setInterface:TCVisualizations];
}

// Control actions
- (IBAction)playPause:(id)sender
{
	if ([server activeConnection]) [server doCommand:@"playPause"];
}

- (IBAction)playPauseControl:(id)sender {
    int selectedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:selectedSegment];
    
	if (clickedSegmentTag == 0) [self prevTrack:self];
	else if (clickedSegmentTag == 1) [self playPause:self];
	else if (clickedSegmentTag == 2) [self nextTrack:self];
}

- (IBAction)nextTrack:(id)sender
{
	if ([server activeConnection]) [server doCommand:@"nextTrack"];
}

- (IBAction)prevTrack:(id)sender
{
	if ([server activeConnection]) [server doCommand:@"prevTrack"];
}

- (IBAction)setVolume:(id)sender
{
	if ([server activeConnection]) [server doCommand:@"setVolume" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[sender stringValue], @"volume", nil]];
}

- (IBAction)volumeUp:(id)sender
{
	if ([server activeConnection]) [server doCommand:@"volumeUp"];
}
- (IBAction)volumeDown:(id)sender
{
	if ([server activeConnection]) [server doCommand:@"volumeDown"];
}
- (IBAction)muteUnmute:(id)sender
{
	if ([server activeConnection]) [playerStatus muteUnmute];
}

- (IBAction)setRating:(id)sender
{
	if ([server activeConnection])
		[server doCommand:@"setTrackRating" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", [sender tag]], @"rating", nil]];
}

- (IBAction)increaseRating:(id)sender
{
	if ([server activeConnection])
	{
		int newRating = ((int)([playerStatus trackRating] * 20.0) + 10);
		if (newRating > 100) newRating = 100;
		
		[server doCommand:@"setTrackRating" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", newRating], @"rating", nil]];
	}
}
- (IBAction)decreaseRating:(id)sender
{
	if ([server activeConnection])
	{
		int newRating = ((int)([playerStatus trackRating] * 20.0) - 10);
		if (newRating < 0) newRating = 0;
		
		[server doCommand:@"setTrackRating" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d", newRating], @"rating", nil]];
	}
}

- (IBAction)playSettings:(id)sender
{
	if ([server activeConnection])
	{
		int clickedSegmentTag = [[sender cell] tagForSegment:[sender selectedSegment]];
		
		Playlist *playlist = [[playlists selectedObjects] objectAtIndex:0];
		
		if (clickedSegmentTag == 0) // change shuffle settings
		{
			if (![interface shuffleSetting])
				[playlist setShuffle:@"1"];
			else
				[playlist setShuffle:@"0"];
			
			[interface setShuffleSetting:(![interface shuffleSetting])];
				
		}
		else if (clickedSegmentTag == 1) // change repeat settings
		{
			NSString *oldSetting = [interface repeatSetting];
			NSString *repeatSetting;
			if ([oldSetting isEqual:@"off"])
				repeatSetting = @"all";
			else if ([oldSetting isEqual:@"all"])
				repeatSetting = @"one";
			else
				repeatSetting = @"off";
			
			[playlist setRepeat:repeatSetting];
			[interface setRepeatSetting:repeatSetting];
		}
	}
}

- (IBAction)queueToShuffle:(id)sender
{
	Track *firstTrack = [[musicBrowser selectedObjects] objectAtIndex:0];
	
	NSEnumerator *enumerator = [[musicTree sources] objectEnumerator];
	
	Source *source;
	NSString *shuffleRef = nil;
	while (source = [enumerator nextObject])
	{
		if ([[[source properties] valueForKey:@"id"] isEqual:[[firstTrack properties] valueForKey:@"source"]])
			shuffleRef = [source shuffleRef];
	}
	
	NSEnumerator *tracks = [[musicBrowser selectedObjects] objectEnumerator];
	Track *track;
	
	if (shuffleRef != nil)
	{
		switch ([sender tag])
		{
			case 1:
				// Queue to next in play order
				while (track = [tracks nextObject])
					[track queueToPlaylist:shuffleRef];
				break;
			case 2:
				// Add to end of playlist
				while (track = [tracks nextObject])
					[track addToPlaylist:shuffleRef];
				break;
			
			default:
				NSLog(@"Huh?");
				break;
		}
		
		Playlist *playlist = [[playlists selectedObjects] objectAtIndex:0];
		[playlist checkForUpdates];
	}
	else
		NSLog(@"Could not lock on source/get shuffle ref");
}

- (IBAction)clearLibraryCache:(id)sender
{
	if ([server activeConnection])
	{
		if ([server supportsExtension:@"tc.clearCache"])
			[server doCommand:@"tc.clearCache"];
	}
}

- (IBAction)compactify:(id)sender
{
	[interface setInterface:TCCompact];
}

// Notifications
- (void)trackChanged:(NSNotification *)aNotification
{
	NSDictionary *newInfo = [aNotification userInfo];
	
	NSString *trackStats;
	
	if ([[newInfo valueForKey:@"statusDisplay"] isEqual:NSLocalizedString(@"Nothing Playing", nil)])
		trackStats = [newInfo valueForKey:@"statusDisplay"];
	else
		trackStats = [NSString stringWithFormat:@"%@\n%@", [newInfo valueForKey:@"statusDisplay"], [newInfo valueForKey:@"ratingString"]];
	
	// Send a Growl notification
	[GrowlApplicationBridge
		notifyWithTitle:NSLocalizedString(@"Track Changed", nil)
		description:trackStats
		notificationName:@"Track Changed"
		iconData:[newInfo valueForKey:@"artwork"]
		priority:0
		isSticky:NO
		clickContext:nil];
	
	// Now tell the interface to update (mostly for artwork)
	[interface updateForTrackChange:newInfo];
	
	// And update the current playlist, if browser is open
	if ([interface interface] == TCMusicBrowser)
	{
		// Check for updates on current playlist
		NSArray *selection = [playlists selectedObjects];
		if (selection && [selection count] > 0)
			[[selection objectAtIndex:0] checkForUpdates];
	}
}

- (void)albumChanged:(NSNotification *)aNotification
{
	// I could do stuff here
}

- (void)ratingChanged:(NSNotification *)aNotification
{
	NSDictionary *newInfo = [aNotification userInfo];
	[GrowlApplicationBridge
		notifyWithTitle:NSLocalizedString(@"Rating Changed", nil)
		description:[NSString stringWithFormat:@"%@\n%@", [newInfo valueForKey:@"name"], [newInfo valueForKey:@"ratingString"]]
		notificationName:@"Rating Changed"
		iconData:[newInfo valueForKey:@"artwork"]
		priority:0
		isSticky:NO
		clickContext:nil];
}

// Preferences
- (IBAction)showPrefs:(id)sender
{
	[interface setInterface:TCPreferences];
}

// Other Special Stuff
- (IBAction)openBugSite:(id)sender
{
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	[ws openURL:[NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"TCBugReportingURL"]]];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL *theURL = [NSURL URLWithString:url];
	
	NSString *host = [theURL host];
	NSNumber *port = [theURL port];
	
	if (host == nil)
	{
		NSLog(@"Malformed URL: %@", url);
		return;
	}
	else
	{
		if (port == nil)
			port = [NSNumber numberWithInt:4242];
		
		[self startConnectionWithAddress:host andPort:[port stringValue] withIdentifier:nil];
		return;
	}
}

@end
