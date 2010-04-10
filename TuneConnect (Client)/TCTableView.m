//
//  TCTableView.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCTableView.h"


@implementation TCTableView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	int row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	[self selectRow:row byExtendingSelection:YES];
	
	return [self menu];
}

@end
