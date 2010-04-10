//
//  TCPluginController.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCPluginController.h"


@implementation TCPluginController

+ (id)controllerForPlugin:(Class)thePlugin
{
	id newPlugin = [[self alloc] init];
	[newPlugin setPlugin:thePlugin];
	return [newPlugin autorelease];
}

- (Class)plugin
{
	return plugin;
}
- (void)setPlugin:(Class)newPlugin
{
	plugin = newPlugin;
}

- (NSString *)name
{
	return name;
}
- (void)setName:(NSString *)newName
{
	if (name)
	{
		[name release];
		name = nil;
	}
	name = [newName copy];
}

- (bool)disabled
{
	return disabled;
}
- (void)setDisabled:(bool)isDisabled
{
	NSMutableArray *dPlugins = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"disabledPlugins"]];
	
	if (isDisabled)
	{
		if (![dPlugins containsObject:name])
			[dPlugins addObject:name];
	}
	else
	{
		if ([dPlugins containsObject:name])
			[dPlugins removeObject:name];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:dPlugins forKey:@"disabledPlugins"];
	
	disabled = isDisabled;
}

- (void)setDisableValue:(bool)isDisabled
{
	disabled = isDisabled;
}
@end
