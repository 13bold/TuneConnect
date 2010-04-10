//
//  TCIMStatus.h
//  IM Status
//
//  Created by Matt Patenaude on 2/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCPluginInterface.h"


@interface TCIMStatus : NSObject<TCPlugin> {
	id app;
}

- (id)initWithServiceProvider:(id)serviceProvider;

@end
