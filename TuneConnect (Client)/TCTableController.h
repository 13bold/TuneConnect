//
//  TCTableController.h
//  TuneConnect
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCTableController : NSObject {
	IBOutlet NSTableView *table;
	
	NSArray *columns;
	
	IBOutlet NSTableColumn *nameColumn;
	IBOutlet NSTableColumn *timeColumn;
	IBOutlet NSTableColumn *artistColumn;
	IBOutlet NSTableColumn *albumColumn;
	IBOutlet NSTableColumn *ratingColumn;
	IBOutlet NSTableColumn *genreColumn;
	IBOutlet NSTableColumn *composerColumn;
	IBOutlet NSTableColumn *commentsColumn;
	IBOutlet NSTableColumn *dateAddedColumn;
	IBOutlet NSTableColumn *bitrateColumn;
	IBOutlet NSTableColumn *sampleRateColumn;
}

- (IBAction)rerenderColumns:(id)sender;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
