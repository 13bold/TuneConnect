//
//  TCSystemBeepPlugin.m
//  TCSystemBeep
//
//  Created by Matt Patenaude on 2/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCSystemBeepPlugin.h"

static NSBundle *pluginBundle = nil;

@implementation TCSystemBeepPlugin

- (id)init
{
	if (self = [super init])
	{
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(trackChanged:) name:@"trackChanged" object:nil];
	}
	return self;
}

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

+ (NSEnumerator *)pluginsFor:(id)anObject
{
	NSEnumerator *result = [[NSArray arrayWithObject:[[[TCSystemBeepPlugin alloc] init] autorelease]] objectEnumerator];
	return result;
}

- (NSView *)prefView
{
	return nil;
}
- (NSString *)prefViewName
{
	return nil;
}

- (void)trackChanged:(NSNotification *)aNotification
{
	// Do something when track changes :)
	NSBeep();
}

@end
