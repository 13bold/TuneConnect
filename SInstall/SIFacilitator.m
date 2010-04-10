//
//  SIFacilitator.m
//  SInstall
//
//  Created by Matt Patenaude on 3/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SIFacilitator.h"


@implementation SIFacilitator
- (void)awakeFromNib
{
	[prog startAnimation:self];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// Grab the server settings
	NSString *prefLocation = [@"~/Library/Preferences/net.tuneconnect.Server.plist" stringByExpandingTildeInPath];
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:86400], @"libraryExpiryTime",
		@"", @"password",
		[NSNumber numberWithInt:4242], @"port",
		[NSNumber numberWithBool:YES], @"useLibraryFile",
		nil];
	
	NSDictionary *prefs = nil;
	if (![fm fileExistsAtPath:prefLocation])
		prefs = defaults;
	else
		prefs = [NSDictionary dictionaryWithContentsOfFile:prefLocation];
	
	// Get the server port
	NSString *port = [[prefs valueForKey:@"port"] stringValue];
	
	// Check if server is running
	NSString *serverAddress = [NSString stringWithFormat:@"http://localhost:%@/tc.", port];
	NSURL *statusURL = [NSURL URLWithString:[serverAddress stringByAppendingString:@"status"]];
	NSURL *stopURL = [NSURL URLWithString:[serverAddress stringByAppendingString:@"shutdownNow"]];
	
	NSString *result = [NSString stringWithContentsOfURL:statusURL encoding:NSUTF8StringEncoding error:nil];
	if ([result isEqualToString:@"Server Running"])
	{
		// Server is running, let's stop it
		NSString *sResult = [NSString stringWithContentsOfURL:stopURL encoding:NSUTF8StringEncoding error:nil];
		if (!(sResult == nil || [sResult isEqualToString:@""]))
		{
			NSLog(@"Could not stop server");
			[statusMessage setStringValue:@"Could not stop server; aborting install."];
			[prog stopAnimation:self];
			return;
		}
	}
	
	[statusMessage setStringValue:@"Installing preference pane..."];
	[[NSWorkspace sharedWorkspace] openFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TuneConnect Server.prefPane"]];
	[NSApp terminate:self];
}

- (void)delayedQuit
{
	[NSTimer scheduledTimerWithTimeInterval:5.0 target:NSApp selector:@selector(terminate:) userInfo:nil repeats:NO];
}

@end
