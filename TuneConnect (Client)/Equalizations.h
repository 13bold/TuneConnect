//
//  Equalizations.h
//  TuneConnect
//
//  Created by Matt Patenaude on 1/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Tunage/TCServer.h>
#import "InterfaceController.h"


@interface Equalizations : NSObject {
	NSMutableArray *presets;
	NSDictionary *currentPreset;
	
	int presetID;
	
	TCServer *server;
	
	NSNumber *EQOn;
	
	NSNumber *band1;
	NSNumber *band2;
	NSNumber *band3;
	NSNumber *band4;
	NSNumber *band5;
	NSNumber *band6;
	NSNumber *band7;
	NSNumber *band8;
	NSNumber *band9;
	NSNumber *band10;
	NSNumber *preamp;
}

- (void)setServer:(TCServer *)newServer;
- (TCServer *)server;

- (NSDictionary *)currentPreset;
- (void)setCurrentPreset:(NSDictionary *)newPreset;

- (NSMutableArray *)presets;
- (void)doEQUpdate:(NSDictionary *)response;
- (void)processEQSettings:(NSDictionary *)response;
- (void)updateBandValues:(NSDictionary *)response;
- (void)populatePresets:(NSDictionary *)response;

- (void)setEQOn:(NSNumber *)eqState;

- (void)setBand1:(NSNumber *)newValue;
- (void)setBand2:(NSNumber *)newValue;
- (void)setBand3:(NSNumber *)newValue;
- (void)setBand4:(NSNumber *)newValue;
- (void)setBand5:(NSNumber *)newValue;
- (void)setBand6:(NSNumber *)newValue;
- (void)setBand7:(NSNumber *)newValue;
- (void)setBand8:(NSNumber *)newValue;
- (void)setBand9:(NSNumber *)newValue;
- (void)setBand10:(NSNumber *)newValue;
- (void)setPreamp:(NSNumber *)newValue;

@end
