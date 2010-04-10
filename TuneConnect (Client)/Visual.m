//
//  Visual.m
//  TuneConnect
//
//  Created by Matt Patenaude on 12/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Visual.h"


@implementation Visual

- (id)init
{
	return [self initWithProperties:nil];
}

- (id)initWithProperties:(NSDictionary *)itemProperties
{
	if (self = [super init])
	{
		if (itemProperties == nil)
		{
			NSArray *keys = [NSArray arrayWithObjects:@"name", @"id", nil];
			NSArray *values = [NSArray arrayWithObjects:NSLocalizedString(@"(Unknown)", nil), @"0", nil];
			
			properties = [[NSMutableDictionary alloc] initWithObjects:values forKeys:keys];
		}
		else
		{
			properties = [[NSMutableDictionary alloc] initWithDictionary:itemProperties copyItems:YES];
		}
	}
	
	return self;
}

@end
