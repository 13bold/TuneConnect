//
//  TCIMStatus.m
//  IM Status
//
//  Created by Matt Patenaude on 2/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCIMStatus.h"

static NSBundle *pluginBundle = nil;

@implementation TCIMStatus

- (id)initWithServiceProvider:(id)serviceProvider
{
	if (self = [super init])
	{
		app = serviceProvider;
	}
	return self;
}

// Plugin Implementation Below This Line

+ (BOOL)initializeClass:(NSBundle *)theBundle
{
	if (pluginBundle)
		return NO;
	
	pluginBundle = [theBundle retain];
	return YES;
}
+ (void)terminateClass
{
	[pluginBundle release];
	pluginBundle = nil;
}
+ (NSEnumerator *)pluginsFor:(id)serviceProvider
{
	id plugin = [[[self alloc] initWithServiceProvider:serviceProvider] autorelease];
	return [[NSArray arrayWithObject:plugin] objectEnumerator];
}
+ (NSString *)pluginName
{
	return @"IM Status";
}
- (NSMenu *)menu
{
	return nil;
}
- (NSView *)prefView
{
	return nil;
}
- (NSString *)prefViewName
{
	return @"IM Status";
}

@end
