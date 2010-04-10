//
//  Equalizations.m
//  TuneConnect
//
//  Created by Matt Patenaude on 1/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Equalizations.h"


@implementation Equalizations

- (id)init
{
	if (self = [super init])
	{
		EQOn = [[NSNumber alloc] initWithBool:YES];
		
		band1 = [[NSNumber alloc] initWithInt:0];
		band2 = [[NSNumber alloc] initWithInt:0];
		band3 = [[NSNumber alloc] initWithInt:0];
		band4 = [[NSNumber alloc] initWithInt:0];
		band5 = [[NSNumber alloc] initWithInt:0];
		band6 = [[NSNumber alloc] initWithInt:0];
		band7 = [[NSNumber alloc] initWithInt:0];
		band8 = [[NSNumber alloc] initWithInt:0];
		band9 = [[NSNumber alloc] initWithInt:0];
		band10 = [[NSNumber alloc] initWithInt:0];
		preamp = [[NSNumber alloc] initWithInt:0];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceChanged:) name:@"interfaceDidChange" object:nil];
	}
	return self;
}

- (void)interfaceChanged:(NSNotification *)aNotification
{
	if ([[[aNotification userInfo] valueForKey:@"mode"] intValue] == TCEqualizer)
	{
		if (!presets) presets = [[NSMutableArray alloc] init];
		[server doCommand:@"EQSettings" withParams:nil callingMethod:@selector(processEQSettings:) ofObject:self];
	}
}

- (void)setServer:(TCServer *)newServer
{
	server = newServer;
}
- (TCServer *)server
{
	return server;
}

- (NSDictionary *)currentPreset
{
	return currentPreset;
}
- (void)setCurrentPreset:(NSDictionary *)newPreset
{
	currentPreset = newPreset;
	[server doCommand:@"setEQPreset" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[[currentPreset valueForKey:@"id"] stringValue], @"preset", nil] callingMethod:@selector(doEQUpdate:) ofObject:self];
}

- (NSMutableArray *)presets
{
	if (!presets)
	{
		presets = [[NSMutableArray alloc] init];
		[server doCommand:@"EQSettings" withParams:nil callingMethod:@selector(processEQSettings:) ofObject:self];
	}
	return presets;
}

- (void)doEQUpdate:(NSDictionary *)response
{
	[server doCommand:@"EQSettings" withParams:nil callingMethod:@selector(updateBandValues:) ofObject:self];
}

- (void)processEQSettings:(NSDictionary *)response
{
	presetID = [[response objectForKey:@"id"] intValue];
	
	[self willChangeValueForKey:@"EQOn"];
	[EQOn release];
	EQOn = [response objectForKey:@"state"];
	[self didChangeValueForKey:@"EQOn"];
	
	[self updateBandValues:response];
	
	[server doCommand:@"EQPresets" withParams:nil callingMethod:@selector(populatePresets:) ofObject:self];
}

- (void)updateBandValues:(NSDictionary *)response
{
	[self willChangeValueForKey:@"band1"];
	[band1 release];
	band1 = [[response objectForKey:@"band1"] retain];
	[self didChangeValueForKey:@"band1"];
	
	[self willChangeValueForKey:@"band2"];
	[band2 release];
	band2 = [[response objectForKey:@"band2"] retain];
	[self didChangeValueForKey:@"band2"];
	
	[self willChangeValueForKey:@"band3"];
	[band3 release];
	band3 = [[response objectForKey:@"band3"] retain];
	[self didChangeValueForKey:@"band3"];
	
	[self willChangeValueForKey:@"band4"];
	[band4 release];
	band4 = [[response objectForKey:@"band4"] retain];
	[self didChangeValueForKey:@"band4"];
	
	[self willChangeValueForKey:@"band5"];
	[band5 release];
	band5 = [[response objectForKey:@"band5"] retain];
	[self didChangeValueForKey:@"band5"];
	
	[self willChangeValueForKey:@"band6"];
	[band6 release];
	band6 = [[response objectForKey:@"band6"] retain];
	[self didChangeValueForKey:@"band6"];
	
	[self willChangeValueForKey:@"band7"];
	[band7 release];
	band7 = [[response objectForKey:@"band7"] retain];
	[self didChangeValueForKey:@"band7"];
	
	[self willChangeValueForKey:@"band8"];
	[band8 release];
	band8 = [[response objectForKey:@"band8"] retain];
	[self didChangeValueForKey:@"band8"];
	
	[self willChangeValueForKey:@"band9"];
	[band9 release];
	band9 = [[response objectForKey:@"band9"] retain];
	[self didChangeValueForKey:@"band9"];
	
	[self willChangeValueForKey:@"band10"];
	[band10 release];
	band10 = [[response objectForKey:@"band10"] retain];
	[self didChangeValueForKey:@"band10"];
	
	[self willChangeValueForKey:@"preamp"];
	[preamp release];
	preamp = [[response objectForKey:@"preamp"] retain];
	[self didChangeValueForKey:@"preamp"];
}

- (void)populatePresets:(NSDictionary *)response
{
	NSEnumerator *enumerator = [[response objectForKey:@"presets"] objectEnumerator];
	
	id preset;
	
	[self willChangeValueForKey:@"currentPreset"];
	[self willChangeValueForKey:@"presets"];
	[presets removeAllObjects];
	while (preset = [enumerator nextObject])
	{
		[presets addObject:preset];
		
		if ([[preset objectForKey:@"id"] intValue] == presetID) currentPreset = preset;
	}
	[self didChangeValueForKey:@"presets"];
	[self didChangeValueForKey:@"currentPreset"];
}

- (void)setEQOn:(NSNumber *)eqState
{
	[EQOn release];
	EQOn = [eqState retain];
	
	NSString *state = ([eqState boolValue]) ? @"on" : @"off";
	
	[server doCommand:@"setEQState" withParams:[NSDictionary dictionaryWithObjectsAndKeys:state, @"state", nil]];
}

- (void)setBand1:(NSNumber *)newValue
{
	[band1 release];
	band1 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"1", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand2:(NSNumber *)newValue
{
	[band2 release];
	band2 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"2", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand3:(NSNumber *)newValue
{
	[band3 release];
	band3 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"3", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand4:(NSNumber *)newValue
{
	[band4 release];
	band4 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"4", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand5:(NSNumber *)newValue
{
	[band5 release];
	band5 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"5", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand6:(NSNumber *)newValue
{
	[band6 release];
	band6 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"6", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand7:(NSNumber *)newValue
{
	[band7 release];
	band7 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"7", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand8:(NSNumber *)newValue
{
	[band8 release];
	band8 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"8", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand9:(NSNumber *)newValue
{
	[band9 release];
	band9 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"9", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setBand10:(NSNumber *)newValue
{
	[band10 release];
	band10 = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"10", @"band", [newValue stringValue], @"value", nil]];
}
- (void)setPreamp:(NSNumber *)newValue
{
	[preamp release];
	preamp = [newValue retain];
	
	[server doCommand:@"setEQBand" withParams:[NSDictionary dictionaryWithObjectsAndKeys:@"preamp", @"band", [newValue stringValue], @"value", nil]];
}

@end
