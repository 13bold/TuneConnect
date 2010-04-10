//
//  TCTwitter.h
//  Twitter
//
//  Created by Matt Patenaude on 2/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPluginInterface.h"
#import "TCTwitterAgent.h"


@interface TCTwitter : NSObject<TCPlugin> {
	id app;
	TCTwitterAgent *sharedResponder;
	NSTimer *currentTimer;
	NSString *currentTrack;
	
	NSString *songPattern;
	NSString *tagline;
	
	NSURL *updateURL;
}

- (id)initWithProvider:(id)newApp;
- (void)trackChanged:(NSNotification *)notification;
- (void)checkTimer:(NSTimer *)theTimer;

@end
