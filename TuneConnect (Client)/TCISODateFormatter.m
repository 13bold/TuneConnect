//
//  TCISODateFormatter.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCISODateFormatter.h"


@implementation TCISODateFormatter

+ (Class)transformedValueClass
{
	return [NSString class];
}
+ (BOOL)allowsReverseTransformation
{
	return NO;
}
- (id)transformedValue:(id)value
{
	NSMutableString *dateString = [NSMutableString stringWithString:value];
	[dateString replaceOccurrencesOfString:@"T" withString:@" " options:nil range:NSMakeRange(0, [dateString length])];
	[dateString replaceOccurrencesOfString:@"Z" withString:@" +0000" options:nil range:NSMakeRange(0, [dateString length])];
	
	NSDate *date = [NSDate dateWithString:dateString];
	
	return [date descriptionWithCalendarFormat:@"%1m/%e/%y %1I:%M %p" timeZone:[NSTimeZone defaultTimeZone] locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

@end
