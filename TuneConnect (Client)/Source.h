//
//  Source.h
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCObject.h"
#import "Playlist.h"

@interface Source : TCObject {
	NSString *shuffleListRef;
}

- (id)initWithProperties:(NSDictionary *)itemProperties;

- (NSMutableArray *)playlists;

- (void)populatePlaylists:(NSDictionary *)response;
- (NSString *)shuffleRef;

@end
