//
//  TCPluginController.h
//  TuneConnect
//
//  Created by Matt Patenaude on 2/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPluginInterface.h"


@interface TCPluginController : NSObject {
	Class plugin;
	NSString *name;
	bool disabled;
}

+ (id)controllerForPlugin:(Class)thePlugin;

- (Class)plugin;
- (void)setPlugin:(Class)newPlugin;

- (NSString *)name;
- (void)setName:(NSString *)newName;

- (bool)disabled;
- (void)setDisabled:(bool)isDisabled;
- (void)setDisableValue:(bool)isDisabled;

@end
