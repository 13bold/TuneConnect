//
//  MusicTree.h
//  TuneConnect
//
//  Created by Matt Patenaude on 9/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Tunage/TCServer.h>
#import "Source.h"


@interface MusicTree : NSObject {
	NSMutableArray *sources;
	
	TCServer *server;
	Source *selectedSource;
	id interfaceController;
}

- (id)server;
- (void)setServer:(id)newServer;

- (id)interfaceController;
- (void)setInterfaceController:(id)newController;

- (NSMutableArray *)sources;
- (void)setSources:(NSArray *)newSources;

- (Source *)selectedSource;
- (void)setSelectedSource:(Source *)newSource;

- (void)populateSources:(NSDictionary *)response;

- (bool)shouldShowSourceChooser;

@end
