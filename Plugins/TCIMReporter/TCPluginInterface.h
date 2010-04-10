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
+ (NSEnumerator *)pluginsFor:(id)anObject;
- (NSView *)prefView;
- (NSString *)prefViewName;

@end