//
//  TCDisablingSlider.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCDisablingSlider.h"


@implementation TCDisablingSlider

- (void)mouseDown:(NSEvent *)theEvent
{
	[[appController playerStatus] dragInProgress:YES];
	[super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[[appController playerStatus] dragInProgress:NO];
	[super mouseUp:theEvent];
}


@end
