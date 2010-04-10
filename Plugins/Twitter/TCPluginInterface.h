/*
 *  TCPluginInterface.h
 *  TuneConnect
 *
 *  Created by Matt Patenaude on 2/3/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
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
- (void)doCleanup;

@end
