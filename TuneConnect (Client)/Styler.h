//
//  Styler.h
//  TuneConnect
//
//  Created by Matt Patenaude on 12/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InterfaceController.h"

@interface Styler : NSObject {
	IBOutlet NSImageView *lowerBezel;
	IBOutlet NSImageView *upperBezel;
	NSImage *focusTopImage;
	NSImage *blurTopImage;
	NSImage *focusBottomImage;
	NSImage *blurBottomImage;
	IBOutlet InterfaceController *ic;
}

- (id)init;
- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowDidResignMain:(NSNotification *)notification;

- (void)setBezelHidden:(bool)isHidden;

@end
