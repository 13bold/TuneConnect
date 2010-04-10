//
//  Visualizations.h
//  TuneConnect
//
//  Created by Matt Patenaude on 12/25/07.
//  Copyright 2007 - 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Visual.h"
#import "InterfaceController.h"


@interface Visualizations : NSObject {
	NSMutableArray *visuals;
	Visual *currentVisual;
	id server;
	
	NSNumber *fullscreen;
	NSNumber *displaying;
	NSString *name;
	NSString *size;
	
	NSDictionary *sizeMap;
}

- (void)setServer:(id)newServer;
- (id)server;

- (NSMutableArray *)visuals;
- (NSArray *)sizes;

- (Visual *)currentVisual;
- (void)setCurrentVisual:(Visual *)newVisual;

- (NSNumber *)fullscreen;
- (void)setFullscreen:(NSNumber *)newFullscreen;

- (NSNumber *)displaying;
- (void)setDisplaying:(NSNumber *)newDisplaying;

- (NSString *)size;
- (void)setSize:(NSString *)newSize;

- (void)processVisualSettings:(NSDictionary *)response;

- (void)populateVisuals:(NSDictionary *)response;

- (void)updateVisualizationSettings;

@end
