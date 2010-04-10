//
//  Playlist.h
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCObject.h"
#import "Track.h"

@interface Playlist : TCObject {
	NSString *signature;
}

- (id)initWithProperties:(NSDictionary *)itemProperties;

- (NSMutableArray *)tracks;

- (void)populateTracks:(NSDictionary *)response;
- (void)signatureResponse:(NSDictionary *)response;
- (void)checkForUpdates;

- (void)getPlaySettingsCallingMethod:(SEL)methodSelector ofObject:(id)receivingObject;
- (void)setRepeat:(NSString *)repeatValue;
- (void)setShuffle:(NSString *)shuffleValue;

- (NSString *)itemRef;

@end
