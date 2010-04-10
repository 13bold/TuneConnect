//
//  Track.h
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCObject.h"


@interface Track : TCObject {
	
}

- (id)initWithProperties:(NSDictionary *)itemProperties;

- (void)play;
- (void)queueToPlaylist:(NSString *)playlistRef;
- (void)addToPlaylist:(NSString *)playlistRef;

- (NSString *)itemRef;
- (NSString *)ratingStars;

+ (NSString *)lengthStringFromTime:(int)seconds;

@end
