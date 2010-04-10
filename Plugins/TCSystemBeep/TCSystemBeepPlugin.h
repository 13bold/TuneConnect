//
//  TCSystemBeepPlugin.h
//  TCSystemBeep
//
//  Created by Matt Patenaude on 2/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPluginInterface.h"

@interface TCSystemBeepPlugin : NSObject<TCPlugin> {

}

- (void)trackChanged:(NSNotification *)aNotification;

@end
