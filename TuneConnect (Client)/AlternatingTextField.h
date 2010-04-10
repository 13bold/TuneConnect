//
//  AlternatingTextField.h
//  TuneConnect
//
//  Created by Matt Patenaude on 12/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AlternatingTextField : NSTextField {
	NSArray *stringValues;
	NSTimer *updater;
	int currentIndex;
	
	NSTimeInterval changeInterval;
	BOOL runningUpdater;
}

- (NSArray *)stringValues;
- (void)setStringValues:(NSArray *)newStringValues startUpdating:(BOOL)begin;
- (void)nextStringValue:(NSTimer *)oldTimer;

- (void)start;
- (void)stop;

- (NSTimeInterval)changeInterval;
- (void)setChangeInterval:(NSTimeInterval)newInterval;

@end
