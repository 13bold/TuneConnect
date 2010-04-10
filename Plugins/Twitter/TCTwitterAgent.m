//
//  TCTwitterAgent.m
//  Twitter
//
//  Created by Matt Patenaude on 2/17/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TCTwitterAgent.h"


@implementation TCTwitterAgent

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	[[challenge sender] useCredential:[NSURLCredential credentialWithUser:@"mattpat" password:@"codexrosie" persistence:NSURLCredentialPersistenceNone] forAuthenticationChallenge:challenge];
}

@end
