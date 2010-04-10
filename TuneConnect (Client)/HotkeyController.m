//
//  HotkeyController.m
//  TuneConnect
//
//  Created by Matt Patenaude on 2/22/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HotkeyController.h"


@implementation HotkeyController

- (void)awakeFromNib
{
	[playPause setTag:1];
	[nextTrack setTag:2];
	[prevTrack setTag:3];
	[muteUnmute setTag:4];
	
	[playPause setDelegate:self];
	[nextTrack setDelegate:self];
	[prevTrack setDelegate:self];
	[muteUnmute setDelegate:self];
}

- (void)updateHotkeysFromDefaults
{
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	KeyCombo playPauseCombo;
	playPauseCombo.flags = [def integerForKey:@"playPauseHotkeyMod"];
	playPauseCombo.code = [def integerForKey:@"playPauseHotkey"];
	
	KeyCombo nextTrackCombo;
	nextTrackCombo.flags = [def integerForKey:@"nextTrackHotkeyMod"];
	nextTrackCombo.code = [def integerForKey:@"nextTrackHotkey"];
	
	KeyCombo prevTrackCombo;
	prevTrackCombo.flags = [def integerForKey:@"prevTrackHotkeyMod"];
	prevTrackCombo.code = [def integerForKey:@"prevTrackHotkey"];
	
	KeyCombo muteUnmuteCombo;
	muteUnmuteCombo.flags = [def integerForKey:@"muteHotkeyMod"];
	muteUnmuteCombo.code = [def integerForKey:@"muteHotkey"];
	
	[playPause setKeyCombo:playPauseCombo];
	[nextTrack setKeyCombo:nextTrackCombo];
	[prevTrack setKeyCombo:prevTrackCombo];
	[muteUnmute setKeyCombo:muteUnmuteCombo];
}

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	NSString *identifier;
	switch ([recorder tag])
	{
		case 1:
			// Play/pause hotkey
			identifier = @"playPause";
			if (playPauseKey)
			{
				[[PTHotKeyCenter sharedCenter] unregisterHotKey:playPauseKey];
				[playPauseKey release];
				playPauseKey = nil;
			}
			break;
		
		case 2:
			// Next track hotkey
			identifier = @"nextTrack";
			if (nextTrackKey)
			{
				[[PTHotKeyCenter sharedCenter] unregisterHotKey:nextTrackKey];
				[nextTrackKey release];
				nextTrackKey = nil;
			}
			break;
		
		case 3:
			// Previous track hotkey
			identifier = @"prevTrack";
			if (prevTrackKey)
			{
				[[PTHotKeyCenter sharedCenter] unregisterHotKey:prevTrackKey];
				[prevTrackKey release];
				prevTrackKey = nil;
			}
			break;
		
		case 4:
			// Mute/unmute hotkey
			identifier = @"muteUnmute";
			if (muteUnmuteKey)
			{
				[[PTHotKeyCenter sharedCenter] unregisterHotKey:muteUnmuteKey];
				[muteUnmuteKey release];
				muteUnmuteKey = nil;
			}
			break;
		
		default:
			// Huh?
			NSLog(@"How on earth do you keep doing this??");
			break;
	}
	PTHotKey *hotKey = [[PTHotKey alloc] initWithIdentifier:identifier
								keyCombo:[PTKeyCombo keyComboWithKeyCode:newKeyCombo.code modifiers:[recorder cocoaToCarbonFlags:newKeyCombo.flags]]];
	
	[hotKey setTarget:self];
	[hotKey setAction:@selector(hotKeyFired:)];
	[[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
	
	switch ([recorder tag])
	{
		case 1:
			// Play/pause hotkey
			playPauseKey = hotKey;
			[def setValue:[NSNumber numberWithInt:newKeyCombo.code] forKey:@"playPauseHotkey"];
			[def setValue:[NSNumber numberWithInt:newKeyCombo.flags] forKey:@"playPauseHotkeyMod"];
			break;
		
		case 2:
			// Next track hotkey
			nextTrackKey = hotKey;
			[def setValue:[NSNumber numberWithInt:newKeyCombo.code] forKey:@"nextTrackHotkey"];
			[def setValue:[NSNumber numberWithInt:newKeyCombo.flags] forKey:@"nextTrackHotkeyMod"];
			break;
		
		case 3:
			// Previous track hotkey
			prevTrackKey = hotKey;
			[def setValue:[NSNumber numberWithInt:newKeyCombo.code] forKey:@"prevTrackHotkey"];
			[def setValue:[NSNumber numberWithInt:newKeyCombo.flags] forKey:@"prevTrackHotkeyMod"];
			break;
		
		case 4:
			// Mute/unmute hotkey
			muteUnmuteKey = hotKey;
			[def setValue:[NSNumber numberWithInt:newKeyCombo.code] forKey:@"muteHotkey"];
			[def setValue:[NSNumber numberWithInt:newKeyCombo.flags] forKey:@"muteHotkeyMod"];
			break;
		
		default:
			// Huh?
			NSLog(@"How on earth do you keep doing this?? AGAIN!?");
			break;
	}
}

- (void)hotKeyFired:(PTHotKey *)hotKey
{
	NSString *ident = [hotKey identifier];
	
	if ([ident isEqual:@"playPause"])
		[appController playPause:self];
	else if ([ident isEqual:@"nextTrack"])
		[appController nextTrack:self];
	else if ([ident isEqual:@"prevTrack"])
		[appController prevTrack:self];
	else if ([ident isEqual:@"muteUnmute"])
		[appController muteUnmute:self];
}

@end
