/*
 *  TCPluginInterface.h
 *  TuneConnect
 *
 *  Created by Matt Patenaude on 2/3/08.
 *  Copyright 2008 Matt Patenaude. All rights reserved.
 *
 */

@protocol TCPlugin

+ (BOOL)initializeClass:(NSBundle *)theBundle;
+ (void)terminateClass;
+ (NSEnumerator *)pluginsFor:(id)serviceProvider;
+ (NSString *)pluginName;
- (NSMenu *)menu;
- (NSView *)prefView;
- (NSString *)prefViewName;

@end

@interface NSObject (TCPluginOptionalMethods)

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification;

@end