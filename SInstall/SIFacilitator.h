//
//  SIFacilitator.h
//  SInstall
//
//  Created by Matt Patenaude on 3/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SIFacilitator : NSObject {
	IBOutlet NSProgressIndicator *prog;
	IBOutlet NSTextField *statusMessage;
}

- (void)delayedQuit;

@end
