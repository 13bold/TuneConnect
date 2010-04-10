//
//  LFController.h
//  Last.fm
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPluginInterface.h"
#import <LFScrobbler/LFScrobbler.h>
#import "EMKeychainProxy.h"
#import "EMKeychainItem.h"


@interface LFController : NSObject<TCPlugin> {
	id app;
	LFScrobbler *scrobbler;
	
	IBOutlet NSView *prefView;
	IBOutlet NSMenu *menu;
	IBOutlet NSImageView *sidebar;
}

- (id)initWithApp:(id)theApp;

- (void)performHandshake;

- (void)trackChanged:(NSNotification *)notification;
- (void)playStateChanged:(NSNotification *)notification;

- (NSString *)username;
- (void)setUsername:(NSString *)newUsername;

- (NSString *)password;
- (void)setPassword:(NSString *)newPassword;

- (IBAction)openLastFM:(id)sender;
- (IBAction)changedEnabled:(id)sender;

@end
