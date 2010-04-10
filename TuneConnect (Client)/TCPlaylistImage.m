//
//  TCPlaylistImage.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCPlaylistImage.h"


@implementation TCPlaylistImage

+ (Class)transformedValueClass
{
	return [NSImage class];
}
+ (BOOL)allowsReverseTransformation
{
	return NO;
}
- (id)transformedValue:(id)value
{
	NSString *type = [value valueForKey:@"specialKind"];
	NSImage *icon;
	if ([type isEqual:@"Music"])
		icon = [NSImage imageNamed:@"music"];
	else if ([type isEqual:@"Movies"])
		icon = [NSImage imageNamed:@"movies"];
	else if ([type isEqual:@"TV_Shows"])
		icon = [NSImage imageNamed:@"TVShows"];
	else if ([type isEqual:@"Audiobooks"])
		icon = [NSImage imageNamed:@"audiobook"];
	else if ([type isEqual:@"Purchased_Music"])
		icon = [NSImage imageNamed:@"purchasedMusicPlaylist"];
	else if ([type isEqual:@"Podcasts"])
		icon = [NSImage imageNamed:@"podcast"];
	else if ([type isEqual:@"folder"])
		icon = [NSImage imageNamed:@"folder"];
	else if ([type isEqual:@"Party_Shuffle"])
		icon = [NSImage imageNamed:@"partyShuffle"];
	else
	{
		if ([[value valueForKey:@"smart"] boolValue])
			icon = [NSImage imageNamed:@"smartPlaylist"];
		else
			icon = [NSImage imageNamed:@"userPlaylist"];
	}
	return icon;
}

@end
