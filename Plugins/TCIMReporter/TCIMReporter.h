//
//  TCIMReporter.h
//  TCIMReporter
//
//  Created by Matt Patenaude on 2/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPluginInterface.h"


@interface TCIMReporter : NSObject<TCPlugin> {
	IBOutlet NSView *prefView;
	id appController;
}

- (void)setController:(id)newController;
- (void)trackChanged:(NSNotification *)trackChange;

@end
