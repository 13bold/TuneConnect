//
//  HotkeyController.h
//  TuneConnect
//
//  Created by Matt Patenaude on 2/22/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SRRecorderControl.h"
#import "PTHotKey.h"
#import "PTHotKeyCenter.h"


@interface HotkeyController : NSObject {
	IBOutlet id appController;
	
	IBOutlet SRRecorderControl *playPause;
	IBOutlet SRRecorderControl *nextTrack;
	IBOutlet SRRecorderControl *prevTrack;
	IBOutlet SRRecorderControl *muteUnmute;
	
	PTHotKey *playPauseKey;
	PTHotKey *nextTrackKey;
	PTHotKey *prevTrackKey;
	PTHotKey *muteUnmuteKey;
}

- (void)updateHotkeysFromDefaults;
- (void)hotKeyFired:(PTHotKey *)hotKey;

@end
