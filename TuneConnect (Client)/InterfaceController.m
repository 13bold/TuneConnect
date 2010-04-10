//
//  InterfaceController.m
//  TuneConnect
//
//  Created by Matt Patenaude on 11/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "InterfaceController.h"


@implementation InterfaceController

- (void)composeInterface
{
	[mainWindow setMovableByWindowBackground:YES];
	[mainWindow setShowsResizeIndicator:NO];
	[compactWindow setShowsResizeIndicator:NO];
	
	// Create dictionary of main views, then layer
	mainViews = [[NSDictionary alloc] initWithObjectsAndKeys:
		artworkView, @"artworkView",
		computerList, @"computerList",
		eqView, @"eqView",
		visualizationsView, @"visualizationsView",
		musicBrowser, @"musicBrowser",
		ipAddress, @"ipAddress",
		connecting, @"connecting",
		passwordView, @"passwordView",
		preferences, @"preferences",
		nil];
	[self layerViews:mainViews intoView:mainView];
	
	// Create dictionary of control views, then layer
	controlViews = [[NSDictionary alloc] initWithObjectsAndKeys:
		connectionControls, @"connectionControls",
		playbackControls, @"playbackControls",
		okCancelControls, @"okCancelControls",
		mbControls, @"mbControls",
		emptyControls, @"emptyControls",
		closeControl, @"closeControl",
		nil];
	[self layerViews:controlViews intoView:controlView];
	
	// Add the LCD view to the upper container
	[topControlView addSubview:lcdView];
	
	// Create dictionary of LCD views, then layer
	lcdViews = [[NSDictionary alloc] initWithObjectsAndKeys:
		progressControls, @"progressControls",
		statusMessage, @"statusMessage",
		statusWithProgress, @"statusWithProgress",
		nil];
	[self layerViews:lcdViews intoView:lcdView];
	
	// View-specific init
	[artwork addSubview:overlayStatusView];
	[artwork setAllowsCutCopyPaste:YES];
	[statusMessageText setChangeInterval:5];
	
	// Window sizing
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSRect connectionFrame = [mainWindow frame];
	//connectionSize = connectionFrame.size;
	connectionSize = NSMakeSize(300, 322);
	NSPoint cPoint = NSPointFromString([defaults stringForKey:@"windowOrigin"]);
	if (!(cPoint.x == 0 && cPoint.y == 0))
	{
		cPoint.y -= connectionSize.height;
		connectionFrame.origin = cPoint;
	} else connectionFrame.origin.y += 125;
	
	standardSize = connectionSize;
	standardSize.height += 125;
	
	connectingSize = standardSize;
	connectingSize.height -= 100;
	
	passwordSize = standardSize;
	passwordSize.height -= 186;
	
	ipSize = connectionSize;
	ipSize.height -= 33;
	
	eqSize = standardSize;
	eqSize.width += 130;
	eqSize.height -= 55;
	
	visualsSize = standardSize;
	visualsSize.width += 50;
	visualsSize.height -= 100;
	
	//browserSize = standardSize;
	//browserSize.width += 350;
	//browserSize.height += 100;
	NSSize bSize = NSSizeFromString([defaults stringForKey:@"musicBrowserSize"]);
	browserSize = (bSize.height != 0 || bSize.width != 0) ? bSize : NSMakeSize(650, 547);
	
	prefsSize = standardSize;
	prefsSize.width += 200;
	prefsSize.height += 20;
	
	compactSize = standardSize;
	compactSize.height -= 300;
	
	oldOrigin = NSMakePoint(0, 0);
	
	[mainWindow setFrame:connectionFrame display:YES];
	
	// Control modifications	
	[playPauseMenuItem setKeyEquivalent:@" "];
	
	[[appController playlists] addObserver:self
						forKeyPath:@"selectedObjects"
						options:NSKeyValueObservingOptionNew
						context:nil];
						
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"compactViewAlwaysOnTop" options:NSKeyValueObservingOptionNew context:nil];
	
	// Menu Bar Controls
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"menuBarControls"])
	{
		menuBar = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
		[menuBar setImage:[NSImage imageNamed:@"MenuBar"]];
		[menuBar setAlternateImage:[NSImage imageNamed:@"MenuBarHighlight"]];
		[menuBar setToolTip:@"TuneConnect"];
		[menuBar setHighlightMode:YES];
		[menuBar setMenu:menuBarMenu];
	}
	else
		menuBar = nil;
	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"menuBarControls" options:NSKeyValueObservingOptionNew context:nil];
	
	// Finish up
	interfaceMode = TCConnect;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"useCompactView"])
	{
		playbackMode = TCCompact;
		[compactViewMenuItem setTitle:NSLocalizedString(@"Switch to Normal View", nil)];
	}
	else
	{
		playbackMode = TCPlayback;
		[compactViewMenuItem setTitle:NSLocalizedString(@"Switch to Compact View", nil)];
	}
	
	currentWindow = mainWindow;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayStatusMessage:) name:@"objectLoading" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelStatusMessage:) name:@"objectReady" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePlayStateIcon:) name:@"playStateChanged" object:nil];
}

- (void)layerViews:(NSDictionary *)viewList intoView:(NSView *)superview
{
	// Enumerate over the keys of viewList, and attach each corresponding
	// view object to the view passed as superview
	NSString *key;
	NSEnumerator *enumerator = [viewList keyEnumerator];
	while (key = [enumerator nextObject])
	{
		[superview addSubview:[viewList objectForKey:key]];
		[[viewList objectForKey:key] setFrame:[superview bounds]];
	}
}

- (void)setInterface:(TCInterfaceMode)mode
{
	if (mode != interfaceMode)
		oldInterfaceMode = interfaceMode;
	
	// Each interface mode must first specify the visibility of control switchers,
	// the visible view, and the control mode. Then, store the mode to the
	// instance variable interfaceMode. Immediately after specifying the view,
	// each mode should also ensure the window is resized properly.
	// These functions should also perform any interface-required initialization.
	switch (mode)
	{
		case TCConnect:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCStatus];
			[statusMessageText 
				setStringValues:[NSArray arrayWithObjects:NSLocalizedString(@"Searching for Devices...", nil), NSLocalizedString(@"Not Connected", nil), nil]
				startUpdating:YES];
			[self setView:TCComputerList];
			[self setControlMode:TCConnectionControls];
			[self resizeWindowTo:connectionSize];
			[self changeResizeStateFor:mainWindow resizable:NO];
			interfaceMode = mode;
			break;
			
		case TCConnecting:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCStatus];
			[statusMessageText setStringValues:[NSArray arrayWithObject:NSLocalizedString(@"Please wait...", nil)] startUpdating:NO];
			[self setView:TCConnectingWait];
			[self setControlMode:TCEmptyControls];
			[self resizeWindowTo:connectingSize];
			[connectionSpinner startAnimation:self];
			[self changeResizeStateFor:mainWindow resizable:NO];
			interfaceMode = mode;
			break;
			
		case TCPassword:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCStatus];
			[self setView:TCEnterPassword];
			[self setControlMode:TCOKCancelControls];
			[self resizeWindowTo:passwordSize];
			[connectionSpinner stopAnimation:self];
			[self changeResizeStateFor:mainWindow resizable:NO];
			interfaceMode = mode;
			break;
			
		case TCPlayback:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCProgress];
			[self setControlMode:TCPlaybackControls];
			[self resizeWindowTo:standardSize];
			[self setView:TCArtworkDisplay];
			[connectionSpinner stopAnimation:self];
			[self changeResizeStateFor:mainWindow resizable:NO];
			interfaceMode = mode;
			break;
			
		case TCCompact:
			[self useWindow:compactWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCProgress];
			[self setControlMode:TCPlaybackControls];
			[self resizeWindowTo:compactSize];
			[self setView:TCArtworkDisplay];
			[connectionSpinner stopAnimation:self];
			interfaceMode = mode;
			break;
			
		case TCMusicBrowser:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCProgress];
			[self setView:TCBrowser];
			[self setControlMode:TCMBControls];
			[self resizeWindowTo:browserSize];
			[self changeResizeStateFor:mainWindow resizable:YES];
			interfaceMode = mode;
			break;
			
		case TCEqualizer:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCProgress];
			[self setView:TCEQSliders];
			[self setControlMode:TCCloseControl];
			[self resizeWindowTo:eqSize];
			[self changeResizeStateFor:mainWindow resizable:NO];
			interfaceMode = mode;
			break;
			
		case TCVisualizations:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			[self setLCDView:TCProgress];
			[self setView:TCVisualPanel];
			[self setControlMode:TCCloseControl];
			[self resizeWindowTo:visualsSize];
			[self changeResizeStateFor:mainWindow resizable:NO];
			interfaceMode = mode;
			break;
		
		case TCPreferences:
			[self useWindow:mainWindow];
			[self setControlSwitchersHidden:YES];
			// not changing the LCD-- whatever it is, leave it!
			[self setView:TCPrefView];
			[self setControlMode:TCCloseControl];
			[self resizeWindowTo:prefsSize];
			[self changeResizeStateFor:mainWindow resizable:NO];
			interfaceMode = mode;
			break;
			
		default:
			NSLog(@"Invalid interface mode specified");
			break;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"interfaceDidChange" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:mode], @"mode", nil]];
}

- (TCInterfaceMode)interface
{
	return interfaceMode;
}
- (TCInterfaceMode)playbackMode
{
	return playbackMode;
}

- (void)setView:(TCViewMode)mode
{
	// Each view mode must show the appropriate view, then hide all others.
	// Then, store the mode to the instance variable viewMode. Also, take this
	// opportunity to set the appropriate first responder, if necessary.
	switch (mode)
	{
		case TCComputerList:
			[self elevateSubview:@"computerList" inGroup:mainViews];
			viewMode = mode;
			break;
			
		case TCConnectingWait:
			[self elevateSubview:@"connecting" inGroup:mainViews];
			viewMode = mode;
			break;
			
		case TCEnterPassword:
			[self elevateSubview:@"passwordView" inGroup:mainViews];
			[mainWindow makeFirstResponder:passwordField];
			viewMode = mode;
			break;
		
		case TCIPAddress:
			[self elevateSubview:@"ipAddress" inGroup:mainViews];
			[mainWindow makeFirstResponder:ipField];
			viewMode = mode;
			break;
		
		case TCArtworkDisplay:
			[self elevateSubview:@"artworkView" inGroup:mainViews];
			viewMode = mode;
			break;
			
		case TCEQSliders:
			[self elevateSubview:@"eqView" inGroup:mainViews];
			viewMode = mode;
			break;
			
		case TCVisualPanel:
			[self elevateSubview:@"visualizationsView" inGroup:mainViews];
			viewMode = mode;
			break;
			
		case TCBrowser:
			[self elevateSubview:@"musicBrowser" inGroup:mainViews];
			viewMode = mode;
			break;
			
		case TCPrefView:
			[self elevateSubview:@"preferences" inGroup:mainViews];
			viewMode = mode;
			break;
			
		default:
			NSLog(@"Invalid view specified");
			break;
	}
}

- (void)setLCDView:(TCLCDMode)mode
{
	// Each LCD mode must first show the appropriate LCD view, then hide
	// all others. Then, store the mode to the instance variable lcdMode.
	switch (mode)
	{
		case TCStatus:
			[self elevateSubview:@"statusMessage" inGroup:lcdViews];
			lcdMode = mode;
			break;
		
		case TCProgress:
			[self elevateSubview:@"progressControls" inGroup:lcdViews];
			lcdMode = mode;
			break;
			
		case TCStatusWithProgress:
			[self elevateSubview:@"statusWithProgress" inGroup:lcdViews];
			lcdMode = mode;
			break;
			
		default:
			NSLog(@"Invalid LCD mode specified");
			break;
	}
}

- (void)setControlMode:(TCControlMode)mode
{
	// Each control mode must first show the appropriate control view, then hide
	// all others. Then, store the mode to the instance variable controlMode.
	switch (mode)
	{
		case TCConnectionControls:
			[self elevateSubview:@"connectionControls" inGroup:controlViews];
			controlMode = mode;
			break;
			
		case TCPlaybackControls:
			[self elevateSubview:@"playbackControls" inGroup:controlViews];
			controlMode = mode;
			break;
		
		case TCOKCancelControls:
			[self elevateSubview:@"okCancelControls" inGroup:controlViews];
			controlMode = mode;
			break;
		
		case TCMBControls:
			[self elevateSubview:@"mbControls" inGroup:controlViews];
			controlMode = mode;
			break;
			
		case TCEmptyControls:
			[self elevateSubview:@"emptyControls" inGroup:controlViews];
			controlMode = mode;
			break;
			
		case TCCloseControl:
			[self elevateSubview:@"closeControl" inGroup:controlViews];
			controlMode = mode;
			break;
		
		default:
			NSLog(@"Invalid control mode specified");
			break;
	}
}

- (void)setControlSwitchersHidden:(bool)hidden
{
	[leftViewSwitch setHidden:hidden];
	[rightViewSwitch setHidden:hidden];
}

- (IBAction)switchControlsLeft:(id)sender
{
	//[self setControlMode:[[[controlOrder allKeysForObject:[NSNumber numberWithInt:controlMode]] objectAtIndex:0] intValue]];
}

- (IBAction)switchControlsRight:(id)sender
{
	//[self setControlMode:[[controlOrder objectForKey:[[NSNumber numberWithInt:controlMode] stringValue]] intValue]];
}

- (IBAction)toggleCompactView:(id)sender
{
	// Change the playback mode, and reapply interface settings
	switch (playbackMode)
	{
		case TCPlayback:
			playbackMode = TCCompact;
			[[NSUserDefaults standardUserDefaults] setValue:@"YES" forKey:@"useCompactView"];
			[compactViewMenuItem setTitle:NSLocalizedString(@"Switch to Normal View", nil)];
			break;
		case TCCompact:
			playbackMode = TCPlayback;
			[[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:@"useCompactView"];
			[compactViewMenuItem setTitle:NSLocalizedString(@"Switch to Compact View", nil)];
			break;
		default:
			NSLog(@"What is up with you? :P");
			break;
	}
	
	if (sender != self)
		if ([appController connected]) [self setInterface:playbackMode];
}

- (void)windowFocused
{
	//[self setControlMode:oldControlMode];
}

- (void)windowBlurred
{
	oldControlMode = controlMode;
	//[self setControlMode:TCPlaybackControls];
}

- (void)elevateSubview:(NSString *)subViewKey inGroup:(NSDictionary *)viewSet
{
	NSString *key;
	NSEnumerator *enumerator = [viewSet keyEnumerator];
	
	// First, unhide the view we're elevating
	[[viewSet objectForKey:subViewKey] setHidden:NO];
	
	// Next, hide all of the others
	while (key = [enumerator nextObject])
	{
		if (![key isEqualToString:subViewKey]) [[viewSet objectForKey:key] setHidden:YES];
	}
}

- (void)changeResizeStateFor:(NSWindow *)window resizable:(BOOL)isResizable
{
	NSSize minSize = (isResizable) ? NSMakeSize(0, 0) : ([window frame]).size;
	NSSize maxSize = (isResizable) ? NSMakeSize(FLT_MAX, FLT_MAX) : ([window frame]).size;
	[window setMinSize:minSize];
	[window setMaxSize:maxSize];
	[window setShowsResizeIndicator:isResizable];
}

- (void)useWindow:(NSWindow *)window
{
	if (![currentWindow isEqual:window])
	{		
		[window makeKeyAndOrderFront:self];
		[currentWindow close];
		currentWindow = window;
	}
}

// View-specific configurators
- (IBAction)showIPEntryField:(id)sender
{
	[self setInterface:TCConnect];
	[self setView:TCIPAddress];
	[self setControlMode:TCOKCancelControls];
	[self resizeWindowTo:ipSize];
}
- (void)connectionFailedWithError:(NSError *)error
{
	[connectingText setStringValue:NSLocalizedString(@"Error!", nil)];
	[self setInterface:TCConnecting];
	[connectionSpinner stopAnimation:self];
	[statusMessageText setStringValues:[NSArray arrayWithObject:NSLocalizedString(@"Error!", nil)] startUpdating:NO];
	[connectionFailureDescription setStringValue:[NSString stringWithFormat:NSLocalizedString(@"An error occurred during connection: %@", nil), [error localizedDescription]]];
	[connectionFailureDescription setHidden:NO];
	
	[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(resetViewAfterFailure:) userInfo:nil repeats:NO];
}
- (void)resetViewAfterFailure:(NSTimer *)oldTimer
{
	[self setInterface:TCConnect];
	[connectingText setStringValue:NSLocalizedString(@"Connecting...", nil)];
	[connectionFailureDescription setHidden:YES];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSArray *selectedObjects = [[appController playlists] selectedObjects];
	if ([keyPath isEqual:@"selectedObjects"])
	{
		if ([selectedObjects count] > 0)
		{
			//NSLog(@"Selected: %@", [[[selectedObjects objectAtIndex:0] properties] valueForKey:@"name"]);
			[[selectedObjects objectAtIndex:0] getPlaySettingsCallingMethod:@selector(updatePlaySettings:) ofObject:self];
		}
		else
		{
			//NSLog(@"(Unset Selection)");
			[shuffleRepeatControl setImage:[NSImage imageNamed:@"shuffle"] forSegment:0];
			[shuffleRepeatControl setImage:[NSImage imageNamed:@"repeat-off"] forSegment:1];
		}
	}
	else if ([keyPath isEqual:@"compactViewAlwaysOnTop"])
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"compactViewAlwaysOnTop"])
			[compactWindow setLevel:NSFloatingWindowLevel];
		else
			[compactWindow setLevel:NSNormalWindowLevel];
	}
	else if ([keyPath isEqual:@"menuBarControls"])
	{
		if (menuBar == nil && [[NSUserDefaults standardUserDefaults] boolForKey:@"menuBarControls"])
		{
			menuBar = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
			[menuBar setImage:[NSImage imageNamed:@"MenuBar"]];
			[menuBar setAlternateImage:[NSImage imageNamed:@"MenuBarHighlight"]];
			[menuBar setToolTip:@"TuneConnect"];
			[menuBar setHighlightMode:YES];
			[menuBar setMenu:menuBarMenu];
		}
		else if (menuBar != nil && [[NSUserDefaults standardUserDefaults] boolForKey:@"menuBarControls"] == NO)
		{
			[[menuBar statusBar] removeStatusItem:menuBar];
			[menuBar release];
			menuBar = nil;
		}
	}
}
- (void)updatePlaySettings:(NSDictionary *)response
{
	//setImage forSegment
	[self setShuffleSetting:[[response valueForKey:@"shuffle"] boolValue]];
	
	[self setRepeatSetting:[response valueForKey:@"repeat"]];
}

- (BOOL)shuffleSetting
{
	return shuffle;
}
- (void)setShuffleSetting:(BOOL)newSetting
{
	shuffle = newSetting;
	
	if (shuffle)
		[shuffleRepeatControl setImage:[NSImage imageNamed:@"shuffleon"] forSegment:0];
	else
		[shuffleRepeatControl setImage:[NSImage imageNamed:@"shuffle"] forSegment:0];
}

- (NSString *)repeatSetting
{
	return repeat;
}
- (void)setRepeatSetting:(NSString *)newSetting
{
	repeat = [newSetting copy];
	
	if ([repeat isEqual:@"all"])
		[shuffleRepeatControl setImage:[NSImage imageNamed:@"repeat-all"] forSegment:1];
	else if ([repeat isEqual:@"one"])
		[shuffleRepeatControl setImage:[NSImage imageNamed:@"repeat-one"] forSegment:1];
	else
		[shuffleRepeatControl setImage:[NSImage imageNamed:@"repeat-off"] forSegment:1];
}

- (IBAction)copyArtworkToPasteboard:(id)sender
{
	// Copy to pasteboard
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:nil];
	[pb setData:[[artwork image] TIFFRepresentation] forType:NSTIFFPboardType];
}

- (void)startProgressBar
{
	//NSLog(@"Start fired");
	loadProgressRunning = YES;
	[loadProgress setIndeterminate:YES];
	[loadProgress startAnimation:self];
}
- (void)updateProgressBar:(NSNumber *)percentage
{
	//NSLog(@"Update fired: %@", [percentage description]);
	[loadProgress setIndeterminate:NO];
	if (loadProgressRunning)
	{
		[loadProgress setDoubleValue:[percentage doubleValue]];
		[loadProgress displayIfNeeded];
	}
}
- (void)stopProgressBar
{
	//NSLog(@"Stop fired");
	loadProgressRunning = NO;
	[loadProgress setIndeterminate:YES];
	[loadProgress stopAnimation:self];
}

// Content-related Methods
- (void)updateForTrackChange:(NSDictionary *)trackInfo
{
	if ([trackInfo valueForKey:@"name"] == [NSNumber numberWithBool:NO])
	{
		[artwork setImage:[NSImage imageNamed:@"whiteBG"]];
		[largeStatus setStringValue:NSLocalizedString(@"Nothing\nPlaying", nil)];
		[largeStatus setHidden:NO];
		[overlayStatusView setHidden:NO];
		[musicChooseButton setHidden:NO];
	}
	else
	{
		[musicChooseButton setHidden:YES];
			
		/*if ([[trackInfo valueForKey:@"album"] isEqualToString:@""] || [[trackInfo valueForKey:@"artist"] isEqualToString:@""])
		{
			NSString *identifier = @"";
			
			if (![[trackInfo valueForKey:@"album"] isEqualToString:@""]) identifier = [trackInfo valueForKey:@"album"];
			if (![[trackInfo valueForKey:@"artist"] isEqualToString:@""]) identifier = [trackInfo valueForKey:@"artist"];
			
			[songSecondLine setStringValue:identifier];
		}
		else [songSecondLine setStringValue:[NSString stringWithFormat:@"%@ (%@)", [trackInfo valueForKey:@"artist"], [trackInfo valueForKey:@"album"]]];
		*/
		
		if ([[trackInfo valueForKey:@"artwork"] length] == 0)
		{
			[artwork setImage:[NSImage imageNamed:@"no-art"]];
			//[largeStatus setStringValue:NSLocalizedString(@"No Art\nAvailable", nil)];
			[largeStatus setHidden:YES];
			[overlayStatusView setHidden:YES];
		}
		else
		{
			[overlayStatusView setHidden:YES];
			[largeStatus setHidden:YES];
			[artwork setImage:[[[NSImage alloc] initWithData:[trackInfo valueForKey:@"artwork"]] autorelease]];
		}
	}
}

- (void)resizeWindowTo:(NSSize)newSize
{
	NSRect frame = [mainWindow frame];
	NSPoint temp = frame.origin;
	
	if (oldOrigin.y != 0 || oldOrigin.x != 0)
	{
		frame.origin = oldOrigin;
		NSRect newFrame = [self constrainFrame:frame toVisibleArea:[[NSScreen mainScreen] visibleFrame] withBuffer:10];
		
		if (!(newFrame.origin.x == temp.x && newFrame.origin.y == temp.y))
			frame.origin = temp;
	}
	
	frame.origin.y += (frame.size.height - newSize.height);
	frame.size = newSize;
	
	oldOrigin = frame.origin;
	
	frame = [self constrainFrame:frame toVisibleArea:[[NSScreen mainScreen] visibleFrame] withBuffer:10];
	
	//[mainWindow setMaxSize:NSMakeSize(0, 0)];
	//[mainWindow setMinSize:NSMakeSize(0, 0)];
	[mainWindow setFrame:frame display:YES animate:[[NSUserDefaults standardUserDefaults] boolForKey:@"animateWindowResize"]];
	//[mainWindow setMaxSize:frame.size];
	//[mainWindow setMinSize:frame.size];
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)proposedFrame
{
	if (interfaceMode != TCConnect && interfaceMode != TCConnecting && interfaceMode != TCPassword)
	{
		if (interfaceMode == TCCompact)
		{
			[self toggleCompactView:self];
			[self setInterface:oldInterfaceMode];
		}
		else
		{
			if (playbackMode == TCPlayback)
				[self toggleCompactView:self];
			[self setInterface:playbackMode];
		}
	}
	return NO;
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
	if (interfaceMode == TCMusicBrowser)
	{
		browserSize = proposedFrameSize;
		[[NSUserDefaults standardUserDefaults] setValue:NSStringFromSize(proposedFrameSize) forKey:@"musicBrowserSize"];
	}
	return proposedFrameSize;
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSPoint origin = ([mainWindow frame]).origin;
	origin.y += ([mainWindow frame]).size.height;
	[[NSUserDefaults standardUserDefaults] setValue:NSStringFromPoint(origin) forKey:@"windowOrigin"];
}

- (NSRect)constrainFrame:(NSRect)inputFrame toVisibleArea:(NSRect)visibleFrame withBuffer:(int)buffer
{	
	if (inputFrame.origin.x < visibleFrame.origin.x)
		inputFrame.origin.x = visibleFrame.origin.x + buffer;
		
	if (inputFrame.origin.y < visibleFrame.origin.y)
		inputFrame.origin.y = visibleFrame.origin.y + buffer;
	
	int appHorizontal = (inputFrame.origin.x + inputFrame.size.width);
	int visibleHorizontal = (visibleFrame.origin.x + visibleFrame.size.width);
	
	int appVertical = (inputFrame.origin.y + inputFrame.size.height);
	int visibleVertical = (visibleFrame.origin.y + visibleFrame.size.height);
	
	if (appHorizontal > visibleHorizontal)
		inputFrame.origin.x -= (appHorizontal - visibleHorizontal) + buffer;
	
	if (appVertical > visibleVertical)
		inputFrame.origin.y -= (appVertical - visibleVertical) + buffer;
	
	return inputFrame;
}

- (IBAction)subwindowEnd:(id)sender
{	
	switch (interfaceMode)
	{
		case TCEqualizer:
			// Yay! All done here
			[self setInterface:playbackMode];
			break;
		
		case TCVisualizations:
			// Yay! need to send settings...
			[self setInterface:playbackMode];
			break;
			
		case TCMusicBrowser:
			// Yay! All done here
			[self setInterface:playbackMode];
			break;
			
		case TCConnect:
			if ([sender tag] == 1)	// Person clicked OK, pass the info on to the controller
				[appController startConnectionWithAddress:[ipField stringValue] andPort:[portField stringValue] withIdentifier:nil];
			else	// Person clicked Cancel, return to the Bonjour view
				[self setInterface:TCConnect];
			break;
			
		case TCPassword:
			if ([sender tag] == 1)	// Person clicked OK, pass the info on to the controller
				[appController checkPasswordInField];
			else	// Person clicked Cancel, return to the Bonjour view
			{
				[self setInterface:TCConnect];
				[appController cancelCurrentConnection];
			}
			break;
		
		case TCPreferences:
			// All done :)
			[self setInterface:oldInterfaceMode];
			break;
		
		default:
			NSLog(@"... how the hell did you get here?");
			break;
	}
}

- (void)displayStatusMessage:(NSNotification *)aNotification
{
	if ([[[aNotification userInfo] objectForKey:@"progressBar"] boolValue])
	{
		[statusProgressMessageText setStringValues:[NSArray arrayWithObject:[[aNotification userInfo] valueForKey:@"string"]] startUpdating:NO];
		[self setLCDView:TCStatusWithProgress];
		if (!loadProgressRunning) [self startProgressBar];
	}
	else
	{
		[statusMessageText setStringValues:[NSArray arrayWithObject:[[aNotification userInfo] valueForKey:@"string"]] startUpdating:NO];
		[self setLCDView:TCStatus];
	}
}
- (void)cancelStatusMessage:(NSNotification *)aNotification
{
	[self setLCDView:TCProgress];
	if (loadProgressRunning) [self stopProgressBar];
}

- (void)changePlayStateIcon:(NSNotification *)aNotification
{
	NSString *playState = [[aNotification userInfo] valueForKey:@"pState"];
	
	NSImage *pImage;
	
	if ([playState isEqualToString:@"playing"])	
		pImage = [NSImage imageNamed:@"pause"];
	else
		pImage = [NSImage imageNamed:@"play"];
		
	[playbackControl setImage:pImage forSegment:1];
	[playbackControlB setImage:pImage forSegment:1];
	[playbackControlC setImage:pImage forSegment:1];
}
@end
