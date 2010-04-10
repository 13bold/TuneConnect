//
//  LFResponder.h
//  Last.fm
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LFResponder : NSObject {
	id controller;
	
	NSMutableDictionary *responses;
	NSMutableDictionary *requests;
	NSMutableDictionary *properties;
	NSMutableDictionary *rObjects;
}

- (id)initWithController:(id)newController;
- (void)beginConnectionWithRequest:(NSURLRequest *)request withTarget:(id)target selector:(SEL)selector;
- (NSString *)cIDForConnection:(NSURLConnection *)theConnection;

- (void)doNothing:(NSString *)response;

@end
