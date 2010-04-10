//
//  TCIMReporter.m
//  TCIMReporter
//
//  Created by Matt Patenaude on 2/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCIMReporter.h"

static NSBundle *pluginBundle = nil;

@implementation TCIMReporter

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
	TCIMReporter *reporter = [[[TCIMReporter alloc] init] autorelease];
	[reporter setController:anObject];
	
	NSEnumerator *result = [[NSArray arrayWithObject:reporter] objectEnumerator];
	return result;
}
- (NSView *)prefView
{
	[NSBundle loadNibNamed:@"TCIMPrefs" owner:self];
	return prefView;	
}
- (NSString *)prefViewName
{
	return @"IM Status";
}

// Implementation of Plugin
- (void)setController:(id)newController
{
	appController = newController;
}
- (void)trackChanged:(NSNotification *)trackChange
{
	// Perform updates
	NSDictionary *errorDict;
	NSAppleEventDescriptor *returnDescriptor = nil;
	
	NSAppleScript *icScript = [[NSAppleScript alloc] initWithSource:
		[NSString stringWithFormat:@"\
		tell application \"iChat\"\n\
		set status message to \"%@\"\n\
		end tell", @"Track Changed!"]];
	
	returnDescriptor = [icScript executeAndReturnError:&errorDict];
	[icScript release];
}

@end
