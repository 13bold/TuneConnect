//
//  InterfaceController.h
//  TuneConnect
//
//  Created by Matt Patenaude on 11/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AlternatingTextField.h"

// Interface Constants
typedef enum _TCInterfaceMode {
	TCConnect			= 0,
	TCPlayback			= 1,
	TCMusicBrowser		= 2,
	TCEqualizer			= 3,
	TCVisualizations	= 4,
	TCConnecting		= 5,
	TCPassword			= 6,
	TCPreferences		= 7,
	TCCompact			= 8
} TCInterfaceMode;

// LCD View Constants
typedef enum _TCLCDMode {
	TCProgress				= 0,
	TCStatus				= 1,
	TCStatusWithProgress	= 2
} TCLCDMode;

// View Constants
typedef enum _TCViewMode {
	TCComputerList		= 0,
	TCArtworkDisplay	= 1,
	TCEQSliders			= 2,
	TCVisualPanel		= 3,
	TCBrowser			= 4,
	TCIPAddress			= 5,
	TCConnectingWait	= 6,
	TCEnterPassword		= 7,
	TCPrefView			= 8
} TCViewMode;

// Control View Constants
typedef enum _TCControlMode {
	TCConnectionControls	= 0,
	TCPlaybackControls		= 1,
	TCOKCancelControls		= 2,
	TCMBControls			= 3,
	TCEmptyControls			= 4,
	TCCloseControl			= 5
} TCControlMode;

@interface InterfaceController : NSObject {
	// Global Containers
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSWindow *compactWindow;
	IBOutlet NSView *mainView;
	IBOutlet NSView *controlView;
	IBOutlet NSView *topControlView;
	IBOutlet NSView *lcdView;
	
	// Global Controllers
	IBOutlet id appController;
	IBOutlet id styler;
	
	// Controls
	IBOutlet NSButton *leftViewSwitch;
	IBOutlet NSButton *rightViewSwitch;
	
	// Main Subviews
	NSDictionary *mainViews;
	IBOutlet NSView *artworkView;
	IBOutlet NSView *computerList;
	IBOutlet NSView *ipAddress;
	IBOutlet NSView *eqView;
	IBOutlet NSView *visualizationsView;
	IBOutlet NSView *musicBrowser;
	IBOutlet NSView *connecting;
	IBOutlet NSView *passwordView;
	IBOutlet NSView *preferences;
	
	// LCD Subviews
	NSDictionary *lcdViews;
	IBOutlet NSView *progressControls;
	IBOutlet NSView *statusMessage;
	IBOutlet NSView *statusWithProgress;
	
	// Control Subviews
	NSDictionary *controlViews;
	IBOutlet NSView *playbackControls;
	IBOutlet NSView *connectionControls;
	IBOutlet NSView *okCancelControls;
	IBOutlet NSView *closeControl;
	IBOutlet NSView *mbControls;
	IBOutlet NSView *emptyControls;
	
	// Other Controls
	IBOutlet NSView *overlayStatusView;
	IBOutlet NSImageView *artwork;
	IBOutlet NSTextField *largeStatus;
	IBOutlet NSButton *musicChooseButton;
	IBOutlet NSTextField *songTitle;
	IBOutlet NSTextField *songSecondLine;
	IBOutlet AlternatingTextField *statusMessageText;
	IBOutlet AlternatingTextField *statusProgressMessageText;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSTextField *ipField;
	IBOutlet NSTextField *portField;
	IBOutlet NSProgressIndicator *connectionSpinner;
	IBOutlet NSProgressIndicator *loadProgress;
	bool loadProgressRunning;
	IBOutlet NSTextField *connectingText;
	IBOutlet NSTextField *connectionFailureDescription;
	IBOutlet NSMenuItem *playPauseMenuItem;
	IBOutlet NSMenuItem *compactViewMenuItem;
	IBOutlet NSSegmentedControl *playbackControl;
	IBOutlet NSSegmentedControl *playbackControlB;
	IBOutlet NSSegmentedControl *playbackControlC;
	IBOutlet NSSegmentedControl *shuffleRepeatControl;
	IBOutlet NSImageView *whiteShield;
	
	// Menu Bar Controls
	NSStatusItem *menuBar;
	IBOutlet NSMenu *menuBarMenu;	
	
	// State Settings
	BOOL shuffle;
	NSString *repeat;
	
	// Mode Containers
	TCInterfaceMode interfaceMode;
	TCInterfaceMode oldInterfaceMode;
	TCViewMode viewMode;
	TCLCDMode lcdMode;
	TCControlMode controlMode;
	TCControlMode oldControlMode;
	
	TCInterfaceMode playbackMode;
	NSWindow *currentWindow;
	
	// Window Sizing
	NSSize connectionSize;
	NSSize connectingSize;
	NSSize passwordSize;
	NSSize ipSize;
	NSSize standardSize;
	NSSize eqSize;
	NSSize visualsSize;
	NSSize browserSize;
	NSSize prefsSize;
	NSSize compactSize;
	
	NSPoint oldOrigin;
}

- (void)composeInterface;

- (void)layerViews:(NSDictionary *)viewList intoView:(NSView *)superview;

- (void)setInterface:(TCInterfaceMode)mode;
- (TCInterfaceMode)interface;
- (TCInterfaceMode)playbackMode;

- (void)setView:(TCViewMode)mode;
- (void)setLCDView:(TCLCDMode)mode;
- (void)setControlMode:(TCControlMode)mode;
- (void)setControlSwitchersHidden:(bool)hidden;

- (IBAction)switchControlsLeft:(id)sender;
- (IBAction)switchControlsRight:(id)sender;

- (IBAction)toggleCompactView:(id)sender;

- (void)windowBlurred;
- (void)windowFocused;

- (void)resizeWindowTo:(NSSize)newSize;
- (IBAction)subwindowEnd:(id)sender;

- (NSRect)constrainFrame:(NSRect)inputFrame toVisibleArea:(NSRect)visibleFrame withBuffer:(int)buffer;

- (void)elevateSubview:(NSString *)subViewKey inGroup:(NSDictionary *)viewSet;
- (void)changeResizeStateFor:(NSWindow *)window resizable:(BOOL)isResizable;

- (void)useWindow:(NSWindow *)window;

// View-specific hooks/configurators
- (IBAction)showIPEntryField:(id)sender;
- (void)connectionFailedWithError:(NSError *)error;
- (void)resetViewAfterFailure:(NSTimer *)oldTimer;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
- (void)updatePlaySettings:(NSDictionary *)response;

- (BOOL)shuffleSetting;
- (void)setShuffleSetting:(BOOL)newSetting;

- (NSString *)repeatSetting;
- (void)setRepeatSetting:(NSString *)newSetting;

- (IBAction)copyArtworkToPasteboard:(id)sender;

- (void)startProgressBar;
- (void)updateProgressBar:(NSNumber *)percentage;
- (void)stopProgressBar;

// Content-related methods
- (void)updateForTrackChange:(NSDictionary *)trackInfo;
- (void)displayStatusMessage:(NSNotification *)aNotification;
- (void)cancelStatusMessage:(NSNotification *)aNotification;
- (void)changePlayStateIcon:(NSNotification *)aNotification;

@end
