//
//  TCConnectionManager.h
//  Tunage
//
//  Created by Matt Patenaude on 2/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDictionary+TCAdditions.h"
#import "TCServerWrapper.h"
#import "TCServer.h"


@interface TCConnectionManager : NSObject {
	NSMutableDictionary *servers;
	NSMutableDictionary *wrappers;
}

+ (TCConnectionManager *)sharedManager;

- (TCServer *)serverForAddress:(NSString *)address andPort:(int)port;
- (TCServerWrapper *)interfaceForAddress:(NSString *)address andPort:(int)port;

@end
