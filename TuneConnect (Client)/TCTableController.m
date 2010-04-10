//
//  TCTableController.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCTableController.h"


@implementation TCTableController

- (void)awakeFromNib
{	
	columns = [[NSArray alloc] initWithObjects:nameColumn, timeColumn, artistColumn, albumColumn, ratingColumn, genreColumn, composerColumn, commentsColumn, dateAddedColumn, bitrateColumn, sampleRateColumn, nil];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults addObserver:self forKeyPath:@"nameColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"timeColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"artistColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"albumColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"ratingColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"genreColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"composerColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"commentsColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"dateAddedColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"bitrateColumn" options:NSKeyValueObservingOptionNew context:nil];
	[defaults addObserver:self forKeyPath:@"sampleRateColumn" options:NSKeyValueObservingOptionNew context:nil];
}

- (IBAction)rerenderColumns:(id)sender
{
	if ([table columnWithIdentifier:@"name"] != -1)
		[table removeTableColumn:nameColumn];
	if ([table columnWithIdentifier:@"time"] != -1)
		[table removeTableColumn:timeColumn];
	if ([table columnWithIdentifier:@"artist"] != -1)
		[table removeTableColumn:artistColumn];
	if ([table columnWithIdentifier:@"album"] != -1)
		[table removeTableColumn:albumColumn];
	if ([table columnWithIdentifier:@"rating"] != -1)
		[table removeTableColumn:ratingColumn];
	if ([table columnWithIdentifier:@"genre"] != -1)
		[table removeTableColumn:genreColumn];
	if ([table columnWithIdentifier:@"composer"] != -1)
		[table removeTableColumn:composerColumn];
	if ([table columnWithIdentifier:@"comments"] != -1)
		[table removeTableColumn:commentsColumn];
	if ([table columnWithIdentifier:@"dateAdded"] != -1)
		[table removeTableColumn:dateAddedColumn];
	if ([table columnWithIdentifier:@"bitrate"] != -1)
		[table removeTableColumn:bitrateColumn];
	if ([table columnWithIdentifier:@"sampleRate"] != -1)
		[table removeTableColumn:sampleRateColumn];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if ([defaults boolForKey:@"nameColumn"])
		[table addTableColumn:nameColumn];
	if ([defaults boolForKey:@"timeColumn"])
		[table addTableColumn:timeColumn];
	if ([defaults boolForKey:@"artistColumn"])
		[table addTableColumn:artistColumn];
	if ([defaults boolForKey:@"albumColumn"])
		[table addTableColumn:albumColumn];
	if ([defaults boolForKey:@"ratingColumn"])
		[table addTableColumn:ratingColumn];
	if ([defaults boolForKey:@"genreColumn"])
		[table addTableColumn:genreColumn];
	if ([defaults boolForKey:@"composerColumn"])
		[table addTableColumn:composerColumn];
	if ([defaults boolForKey:@"commentsColumn"])
		[table addTableColumn:commentsColumn];
	if ([defaults boolForKey:@"dateAddedColumn"])
		[table addTableColumn:dateAddedColumn];
	if ([defaults boolForKey:@"bitrateColumn"])
		[table addTableColumn:bitrateColumn];
	if ([defaults boolForKey:@"sampleRateColumn"])
		[table addTableColumn:sampleRateColumn];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object isEqual:[NSUserDefaults standardUserDefaults]])
		[self rerenderColumns:object];
}

- (void)dealloc
{
	[columns release];
	[super dealloc];
}

@end
