//
//  TCPluginServiceProvider.h
//  TuneConnect
//
//  Created by Matt Patenaude on 2/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl-WithInstaller/GrowlApplicationBridge.h>


@interface TCPluginServiceProvider : NSObject {
	id app;
	id appController;
	id playerStatus;
	id musicTree;
	id interface;
}

+ (TCPluginServiceProvider *)sharedServiceProvider;

- (void)setAppController:(id)newController;

- (id)app;
- (id)playerStatus;
- (id)musicTree;
- (id)interface;
- (id)visualizations;
- (id)equalizer;
- (id)server;
- (bool)connected;

- (void)sendGrowlNotification:(NSString *)notification withTitle:(NSString *)title imageData:(NSData *)image;

- (void)replyToApplicationShouldTerminate:(bool)theReply sender:(id)plugin;

@end
