//
//  AlternatingTextField.m
//  TuneConnect
//
//  Created by Matt Patenaude on 12/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AlternatingTextField.h"


@implementation AlternatingTextField

+ (void)initialize
{
	[self exposeBinding:@"stringValues"];
}

- (NSArray *)stringValues
{
	return stringValues;
}

- (void)setStringValues:(NSArray *)newStringValues
{
	[self setStringValues:newStringValues startUpdating:YES];
}

- (void)setStringValues:(NSArray *)newStringValues startUpdating:(BOOL)begin
{
	[self stop];
	
	if (stringValues)
		[stringValues release];
		
	stringValues = [[NSArray alloc] initWithArray:newStringValues copyItems:YES];
	[self setStringValue:[stringValues objectAtIndex:0]];
	currentIndex = 0;
	
	if (begin) [self start];
}

- (void)nextStringValue:(NSTimer *)oldTimer
{
	if (currentIndex < ([stringValues count] - 1))
		currentIndex++;
	else
		currentIndex = 0;
	
	[self setStringValue:[stringValues objectAtIndex:currentIndex]];
	
	updater = [NSTimer scheduledTimerWithTimeInterval:changeInterval target:self selector:@selector(nextStringValue:) userInfo:nil repeats:NO];
}

- (void)start
{
	updater = [NSTimer scheduledTimerWithTimeInterval:changeInterval target:self selector:@selector(nextStringValue:) userInfo:nil repeats:NO];
	runningUpdater = YES;
}
- (void)stop
{
	if (runningUpdater && [updater respondsToSelector:@selector(invalidate)]) [updater invalidate];
	runningUpdater = NO;
}

- (NSTimeInterval)changeInterval
{
	return changeInterval;
}
- (void)setChangeInterval:(NSTimeInterval)newInterval
{
	changeInterval = newInterval;
}

- (void)dealloc
{
	[stringValues release];
	[super dealloc];
}

@end
