//
//  TCController.h
//  TuneConnect
//
//  Created by Matt Patenaude on 9/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Tunage/TCServer.h>
#import "NSDictionary+TCAdditions.h"
#import "MusicTree.h"
#import "PlayerStatus.h"
#import "Visualizations.h"
#import "Equalizations.h"
#import "BonjourController.h"
#import "InterfaceController.h"
#import "HotkeyController.h"
#import <Growl-WithInstaller/GrowlApplicationBridge.h>
#import "AlternatingTextField.h"
#import "TCTableController.h"
#import "TCBitrateTransformer.h"
#import "TCSampleRateTransformer.h"
#import "TCISODateFormatter.h"
#import "TCPlaylistImage.h"
#import "TCArrayCount.h"
#import "TCPluginInterface.h"
#import "TCPluginController.h"
#import "TCPluginServiceProvider.h"


@interface TCController : NSObject {
	TCServer *server;
	MusicTree *musicTree;
	Visualizations *visuals;
	
	IBOutlet NSWindow *mainWindow;
	IBOutlet BonjourController *bonjour;
	IBOutlet NSImageView *artwork;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSTextField *passwordDescription;
	IBOutlet NSButton *storePassword;
	IBOutlet NSArrayController *musicBrowser;
	
	IBOutlet TCTableController *tableController;
	
	IBOutlet InterfaceController *interface;
	
	IBOutlet NSArrayController *playlists;
	
	BOOL awaitingAuthentication;
	BOOL usingKeychain;
	
	PlayerStatus *playerStatus;
	Equalizations *equalizations;
	
	IBOutlet AlternatingTextField *trackInfo;
	IBOutlet AlternatingTextField *trackInfoCompact;
	
	IBOutlet HotkeyController *hotkeyController;
	
	// Plug-in Support
	NSMutableArray *pluginClasses;
	NSMutableArray *pluginInstances;
	IBOutlet NSMenu *pluginMenu;
	
	NSMutableArray *plugins;
	NSMutableArray *waitingOnPlugins;
	bool appCanTerminate;
	
	bool pluginsLoaded;
	
	IBOutlet NSTabView *prefsView;
}

- (id)app;

- (Class)classForPlugin:(NSString *)pluginPath;
- (void)activatePlugin:(NSString *)pluginPath;
- (void)instantiatePlugins:(Class)pluginClass;

- (NSArray *)plugins;

- (void)plugin:(id)plugin repliedToTermination:(bool)theReply;

- (IBAction)makeConnection:(id)sender;
- (void)cancelCurrentConnection;

//- (void)receivedPasswordFromSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)startConnectionWithAddress:(NSString *)address andPort:(NSString *)port withIdentifier:(NSString *)ident;

- (void)checkPasswordInField;

- (TCServer *)server;
- (void)setServer:(TCServer *)newServer;

- (bool)connected;

- (MusicTree *)musicTree;
- (void)setMusicTree:(MusicTree *)newMusicTree;

- (NSArrayController *)playlists;

- (PlayerStatus *)playerStatus;
- (void)setPlayerStatus:(PlayerStatus *)newPlayerStatus;

- (Visualizations *)visuals;
- (void)setVisuals:(Visualizations *)newVisuals;

- (Equalizations *)equalizations;
- (void)setEqualizations:(Equalizations *)newEqualizations;

- (void)serverReady:(TCServer *)theServer;
- (void)serverNeedsAuthentication:(TCServer *)theServer;
- (void)serverConnectionError:(NSError *)error;
- (void)badServerVersion:(NSString *)badVersion requires:(NSString *)requiredVersion;

- (void)interfaceChanged:(NSNotification *)changeNotification;

- (IBAction)playPauseControl:(id)sender;
- (IBAction)chooseMusic:(id)sender;
- (IBAction)showEqualizer:(id)sender;
- (IBAction)showVisualizations:(id)sender;

// Control actions
- (IBAction)playPause:(id)sender;
- (IBAction)nextTrack:(id)sender;
- (IBAction)prevTrack:(id)sender;

- (IBAction)setVolume:(id)sender;
- (IBAction)volumeUp:(id)sender;
- (IBAction)volumeDown:(id)sender;
- (IBAction)muteUnmute:(id)sender;

- (IBAction)setRating:(id)sender;

- (IBAction)increaseRating:(id)sender;
- (IBAction)decreaseRating:(id)sender;

- (IBAction)playSettings:(id)sender;

- (IBAction)queueToShuffle:(id)sender;
- (IBAction)clearLibraryCache:(id)sender;

- (IBAction)compactify:(id)sender;

// Preferences
- (IBAction)showPrefs:(id)sender;

// Other Special Stuff
- (IBAction)openBugSite:(id)sender;
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;

@end
