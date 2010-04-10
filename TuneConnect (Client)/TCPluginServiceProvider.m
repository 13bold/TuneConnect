//
//  TCPluginServiceProvider.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCPluginServiceProvider.h"

static TCPluginServiceProvider *sharedProvider = nil;

@implementation TCPluginServiceProvider

+ (TCPluginServiceProvider *)sharedServiceProvider
{
	if (!sharedProvider)
	{
		sharedProvider = [[self alloc] init];
	}
	return sharedProvider;
}

- (void)setAppController:(id)newController
{
	if (appController)
	{
		[appController release];
		appController = nil;
	}
	appController = [newController retain];
}

- (id)app
{
	return [appController app];
}
- (id)playerStatus
{
	return [appController playerStatus];
}
- (id)musicTree
{
	return [appController musicTree];
}
- (id)interface
{
	return [appController interface];
}
- (id)visualizations
{
	return [appController visuals];
}
- (id)equalizer
{
	return [appController equalizations];
}
- (id)server
{
	return [appController server];
}
- (bool)connected
{
	return [appController connected];
}

- (void)sendGrowlNotification:(NSString *)notification withTitle:(NSString *)title imageData:(NSData *)image
{
	[GrowlApplicationBridge
		notifyWithTitle:title
		description:notification
		notificationName:@"Plug-in Notification"
		iconData:image
		priority:0
		isSticky:NO
		clickContext:nil];
}

- (void)replyToApplicationShouldTerminate:(bool)theReply sender:(id)plugin
{
	[appController plugin:plugin repliedToTermination:theReply];
}

@end
