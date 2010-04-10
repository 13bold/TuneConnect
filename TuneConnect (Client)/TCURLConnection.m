//
//  TCURLConnection.m
//  TuneConnect Obj-C Interface
//
//  Created by Matt Patenaude on 9/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "TCURLConnection.h"


@implementation TCURLConnection

- (void)dealloc
{
	[invocationToCall release];
	[cID release];
	[super dealloc];
}

- (id)initWithRequest:(NSURLRequest *)theRequest
							withID:(NSString *)connectionID
						  delegate:(id)theDelegate
			   executingInvocation:(NSInvocation *)responseInvocation
					   withRawData:(bool)doRaw
{
	self = [super initWithRequest:theRequest delegate:theDelegate];
	[self setCID:connectionID];
	if (responseInvocation != nil)
	{
		[self setInvocationToCall:responseInvocation];
	}
	[self setPostRawData:doRaw];
	return self;
}

- (NSInvocation *)invocationToCall
{
	return invocationToCall;
}

- (void)setInvocationToCall:(NSInvocation *)newInvocation
{
	invocationToCall = [newInvocation retain];
}

- (bool)postRawData
{
	return postRawData;
}

- (void)setPostRawData:(bool)postRaw
{
	postRawData = postRaw;
}

- (NSString *)cID
{
	return cID;
}

- (void)setCID:(NSString *)newCID
{
	cID = [newCID copy];
}

@end
