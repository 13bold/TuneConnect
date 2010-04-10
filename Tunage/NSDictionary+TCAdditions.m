//
//  NSDictionary+TCAdditions.m
//  Tunage
//
//  Created by Matt Patenaude on 2/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSDictionary+TCAdditions.h"


@implementation NSDictionary (TCAdditions)

- (bool)hasKey:(NSString *)key
{
	return [[self allKeys] containsObject:key];
}

@end
