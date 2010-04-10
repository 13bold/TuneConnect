//
//  TCURLConnection.h
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TCURLConnection : NSURLConnection {
	NSInvocation *invocationToCall;
	NSString *cID;
	bool postRawData;
}

- (void)dealloc;
- (id)initWithRequest:(NSURLRequest *)theRequest withID:(NSString *)connectionID delegate:(id)theDelegate executingInvocation:(NSInvocation *)responseInvocation withRawData:(bool)doRaw;
- (NSInvocation *)invocationToCall;
- (void)setInvocationToCall:(NSInvocation *)newInvocation;
- (bool)postRawData;
- (void)setPostRawData:(bool)postRaw;
- (NSString *)cID;
- (void)setCID:(NSString *)newCID;

@end
