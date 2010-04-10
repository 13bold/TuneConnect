/* TuneConnect_ServerPref */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>
#import "CocoaCryptoHashing.h"
#import "UKLoginItemRegistry.h"

typedef enum _TCProperty {
	TCPropLibraryCache	= 1,
	TCPropPassword		= 2,
	TCPropExpiryTime	= 3,
	TCPropPort			= 4,
	TCPropAutostart		= 5
} TCProperty;

typedef struct {
	int value;
	int unitOffset;
} TCExpiryTime;

@interface TuneConnect_ServerPref : NSPreferencePane
{	
	IBOutlet NSSlider *onOffSwitch;
	
	IBOutlet NSButton *passwordButton;
	
	IBOutlet NSTextField *libraryStatus;
	IBOutlet NSButton *libraryButton;
	IBOutlet NSButton *autostartButton;
	IBOutlet NSTextField *passwordStatus;
	IBOutlet NSTextField *portStatus;
	IBOutlet NSTextField *expiryTime;
	
	IBOutlet NSWindow *passwordPanel;
	IBOutlet NSButton *usePassword;
	IBOutlet NSSecureTextField *password;
	IBOutlet NSSecureTextField *passwordConfirm;
	
	IBOutlet NSWindow *portPanel;
	IBOutlet NSTextField *portField;
	
	IBOutlet NSWindow *expiryPanel;
	IBOutlet NSTextField *expiryTimeField;
	IBOutlet NSStepper *expiryTimeStepper;
	IBOutlet NSPopUpButton *units;
	
	bool serverRunning;
	bool autoUpdate;
	bool centerRegistered;
	NSString *urlString;
	NSMutableData *receivedData;
	NSString *pathToApp;
	
	NSTask *server;
	NSArray *serverArguments;
	
	NSString *oldPort;
	
	NSDictionary *serverSettings;
	NSString *settingsFile;
	
	NSWindow *currentSheet;
}

- (void)mainViewDidLoad;
- (void)checkIfServerRunningAfterCommand:(NSString *)command;
- (void)processRequestWithCommand:(NSString *)command;
- (void)serverLaunched:(NSNotification *)aNotification;
- (IBAction)startStopServer:(id)sender;
- (IBAction)openSheet:(id)sender;
- (IBAction)endSheet:(id)sender;

// Actions
- (IBAction)enableDisableLibraryFile:(id)sender;
- (IBAction)enableDisableAutostart:(id)sender;

// Handlers
- (void)processPasswordFrom:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)processPortFrom:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)processExpiryFrom:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

// Workers
- (void)writeChangesToFile;
- (void)updateStatusForProperty:(TCProperty)property;

// Miscellaneous
- (TCExpiryTime)expiryTimeForSeconds:(int)seconds;
@end
