//
//  TCObject.h
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TCObject : NSObject {
	NSMutableDictionary *properties;
	NSMutableArray *children;
	id server;
	id delegate;
	bool objectIsLeaf;
}

- (id)server;
- (void)setServer:(id)newServer;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSMutableDictionary *)properties;
- (void)setProperties:(NSDictionary *)newProperties;

- (void)setChildren:(NSArray *)newChildren;

- (bool)objectIsLeaf;

@end
