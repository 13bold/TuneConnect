//
//  Styler.m
//  TuneConnect
//
//  Created by Matt Patenaude on 12/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Styler.h"


@implementation Styler
- (id)init
{
	if (self = [super init])
	{
		// if on Leopard
		focusTopImage = [NSImage imageNamed:@"top-focus-leopard"];
		blurTopImage = [NSImage imageNamed:@"top-blur-leopard"];
		focusBottomImage = [NSImage imageNamed:@"bottom-focus-leopard"];
		blurBottomImage = [NSImage imageNamed:@"bottom-blur-leopard"];
	}
	return self;
}
- (void)windowDidBecomeMain:(NSNotification *)notification
{
	[lowerBezel setImage:focusBottomImage];
	[upperBezel setImage:focusTopImage];
	[ic windowFocused];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	[lowerBezel setImage:blurBottomImage];
	[upperBezel setImage:blurTopImage];
	[ic windowBlurred];
}

- (void)setBezelHidden:(bool)isHidden
{
	[lowerBezel setHidden:isHidden];
	[upperBezel setHidden:isHidden];
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)proposedFrame
{
	return [ic windowShouldZoom:window toFrame:proposedFrame];
}

- (NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize
{
	return [ic windowWillResize:window toSize:proposedFrameSize];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[ic windowWillClose:notification];
}

@end
