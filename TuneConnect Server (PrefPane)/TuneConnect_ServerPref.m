//
//  TuneConnect_ServerPref.m
//  TuneConnect Server
//
//  Created by Matt Patenaude on 9/1/07.
//  Copyright (c) 2007 __MyCompanyName__. All rights reserved.
//

#import "TuneConnect_ServerPref.h"


@implementation TuneConnect_ServerPref

- (void) mainViewDidLoad
{
	if (serverSettings)
	{
		[serverSettings release];
	}
	
	if (!settingsFile)
	{
		settingsFile = [[[[[NSBundle bundleWithIdentifier:@"net.tuneconnect.ServerConfig"] infoDictionary] valueForKey:@"TCServerSettingsPath"] stringByExpandingTildeInPath] retain];
	}
	
	if (pathToApp)
	{
		[pathToApp release];
		pathToApp = nil;
	}
	
	NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
	pathToApp = [[resourcePath stringByAppendingPathComponent:@"tc-server.app"] retain];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:settingsFile])
	{
		serverSettings = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:86400], @"libraryExpiryTime",
			@"", @"password",
			[NSNumber numberWithInt:4242], @"port",
			[NSNumber numberWithBool:YES], @"useLibraryFile",
			nil] retain];
			
		[self writeChangesToFile];
	}
	else
		serverSettings = [[NSMutableDictionary dictionaryWithContentsOfFile:settingsFile] retain];
	
	[self updateStatusForProperty:TCPropLibraryCache];
	[self updateStatusForProperty:TCPropPassword];
	[self updateStatusForProperty:TCPropExpiryTime];
	[self updateStatusForProperty:TCPropPort];
	[self updateStatusForProperty:TCPropAutostart];
	
	/*NSDictionary *prefs = [[NSUserDefaults standardUserDefaults]
			persistentDomainForName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
	*/
	//[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
	//		@"4242",	@"port",
	//		@"YES",		@"startAtLogin",
	//		@"YES",		@"webAccess",
	//		@"YES",		@"checkForUpdates",
	//		nil]];
	
	if (!centerRegistered)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(serverLaunched:) 
				name:NSTaskDidTerminateNotification 
				object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
				selector:@selector(saveChanges:)
				name:NSApplicationWillTerminateNotification
				object:nil];
				
		centerRegistered = YES;
	}
	
	server = nil; // This is a good time to initialize the pointer
	
	oldPort = @"4242";
	
	autoUpdate = YES;
	[self checkIfServerRunningAfterCommand:@"tc.status"];	
}

- (void) checkIfServerRunningAfterCommand:(NSString *)command
{
	[self processRequestWithCommand:command];
}

- (IBAction) startStopServer:(id)sender
{
	if ([sender intValue] == 0 && serverRunning == YES)
	{
		// stop the server
		autoUpdate = YES;
		[self checkIfServerRunningAfterCommand:@"tc.shutdownNow"];
	}
	else if ([sender intValue] == 1 && serverRunning == NO)
	{
		// start the server... a bit trickier :P
		server = [[NSTask alloc] init];
		[server setLaunchPath:@"/usr/bin/open"];
		
		serverArguments = [NSArray arrayWithObject:pathToApp];
		/*
		unsetenv("TC_PORT");
		unsetenv("TC_PASSWORD");
		
		if (![[[serverPort stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
		{
			setenv("TC_PORT", [[[serverPort stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] cStringUsingEncoding:NSUTF8StringEncoding], 1);
			oldPort = [[serverPort stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		}
		
		if ([usePassword state] == NSOnState)
		{
			setenv("TC_PASSWORD", [[serverPassword stringValue] cStringUsingEncoding:NSUTF8StringEncoding], 1);
		}
		*/
		
		[server setArguments:serverArguments];
		[server launch];
	}
	
}

- (IBAction)openSheet:(id)sender
{
	TCExpiryTime expiry;
	switch ([sender tag])
	{
		case 1:
			// Change Port
			currentSheet = portPanel;
			[portField setStringValue:[[serverSettings valueForKey:@"port"] stringValue]];
			[NSApp beginSheet:portPanel
				modalForWindow:[[self mainView] window]
				modalDelegate:self
				didEndSelector:@selector(processPortFrom:returnCode:contextInfo:)
				contextInfo:nil];
				
			break;
			
		case 2:
			// Set Password
			currentSheet = passwordPanel;
			[NSApp beginSheet:passwordPanel
				modalForWindow:[[self mainView] window]
				modalDelegate:self
				didEndSelector:@selector(processPasswordFrom:returnCode:contextInfo:)
				contextInfo:nil];
			
			break;
			
		case 3:
			// Change Expiry Time
			currentSheet = expiryPanel;
			expiry = [self expiryTimeForSeconds:[[serverSettings valueForKey:@"libraryExpiryTime"] intValue]];
			[expiryTimeField setIntValue:expiry.value];
			[expiryTimeStepper setIntValue:expiry.value];
			[units selectItemWithTag:expiry.unitOffset];
			[NSApp beginSheet:expiryPanel
				modalForWindow:[[self mainView] window]
				modalDelegate:self
				didEndSelector:@selector(processExpiryFrom:returnCode:contextInfo:)
				contextInfo:nil];
			break;
			
		default:
			NSLog(@"Err..");
			break;
	}
}

- (IBAction)endSheet:(id)sender
{
	[NSApp endSheet:currentSheet returnCode:[sender tag]];
	[currentSheet close];
}

- (void)serverLaunched:(NSNotification *)aNotification
{
	serverRunning = YES;
}

- (void)processRequestWithCommand:(NSString *)command
{
	urlString = [NSString stringWithFormat:@"http://localhost:%@/%@", oldPort, command];
	// create the request
	
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
		
											  cachePolicy:NSURLRequestUseProtocolCachePolicy
		
										  timeoutInterval:60.0];
	
	// create the connection with the request
	// and start loading the data
	
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	
	if (theConnection) {
		// Create the NSMutableData that will hold
		// the received data
		// receivedData is declared as a method instance elsewhere
		
		receivedData=[[NSMutableData data] retain];
		
	} else {
		// inform the user that the download could not be made
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere

    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere

    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{

    // release the connection, and the data object
    [connection release];

    // receivedData is declared as a method instance elsewhere
    [receivedData release];

    // inform the user
    //NSLog(@"Connection failed! Error - %@ %@",
    //      [error localizedDescription],
    //      [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
	[onOffSwitch setIntValue:0];
	serverRunning = NO;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{

    // do something with the data
    // receivedData is declared as a method instance elsewhere

    //NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	
	NSString* dataAsString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
	
	if ([dataAsString isEqualToString:@"Server Running"])
	{
		if (autoUpdate)
		{
			[onOffSwitch setIntValue:1];
		}
		serverRunning = YES;
	}
	else
	{
		if (autoUpdate)
		{
			[onOffSwitch setIntValue:0];
		}
		serverRunning = NO;
	}
	

    // release the connection, and the data object

    [connection release];

    [receivedData release];

}

// Actions
- (IBAction)enableDisableLibraryFile:(id)sender
{
	if ([[serverSettings valueForKey:@"useLibraryFile"] boolValue])
	{
		// Disable
		[serverSettings setValue:[NSNumber numberWithBool:NO] forKey:@"useLibraryFile"];
		
	}
	else
	{
		// Enable
		[serverSettings setValue:[NSNumber numberWithBool:YES] forKey:@"useLibraryFile"];
	}
	
	[self writeChangesToFile];
	[self updateStatusForProperty:TCPropLibraryCache];
	[self updateStatusForProperty:TCPropExpiryTime];
}

- (IBAction)enableDisableAutostart:(id)sender
{
	int theIndex;
	if ((theIndex = [UKLoginItemRegistry indexForLoginItemWithPath:pathToApp]) == -1)
		[UKLoginItemRegistry addLoginItemWithPath:pathToApp hideIt:NO];
	else
		[UKLoginItemRegistry removeLoginItemAtIndex:theIndex];
	
	[self updateStatusForProperty:TCPropAutostart];
}

// Handlers
- (void)processPasswordFrom:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == 1)
	{
		if ([usePassword state])
		{
			if ([[password stringValue] isEqual:[passwordConfirm stringValue]])
				[serverSettings setValue:[[password stringValue] sha1HexHash] forKey:@"password"];
			else
			{
				[[NSAlert alertWithMessageText:@"Mismatched Passwords"
					defaultButton:nil
					alternateButton:nil
					otherButton:nil
					informativeTextWithFormat:@"The passwords you entered were not the same. Please try again."] runModal];
				//[self openSheet:passwordButton];
			}
		}
		else
			[serverSettings setValue:@"" forKey:@"password"];
	}
	
	[self updateStatusForProperty:TCPropPassword];
	[self writeChangesToFile];
}

- (void)processPortFrom:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == 1)
		[serverSettings setValue:[NSNumber numberWithInt:[portField intValue]] forKey:@"port"];
	
	[self updateStatusForProperty:TCPropPort];
	[self writeChangesToFile];
}

- (void)processExpiryFrom:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == 1)
	{
		NSNumber *newValue = [NSNumber numberWithInt:([expiryTimeField intValue] * [[units selectedItem] tag])];
		[serverSettings setValue:newValue forKey:@"libraryExpiryTime"];
	}
	
	[self updateStatusForProperty:TCPropExpiryTime];
	[self writeChangesToFile];
}

// Save Prefs!
- (void) saveChanges:(NSNotification*)aNotification {
    /*NSDictionary *prefs;
    
    prefs=[[NSDictionary alloc] initWithObjectsAndKeys:
		   [website stringValue], 			@"website",
		   [NSNumber numberWithInt:selauthor],	@"author",
		   [NSNumber numberWithFloat:[rating floatValue]],	@"rating",
		   nil];
    
    [[NSUserDefaults standardUserDefaults]
	 removePersistentDomainForName:[[NSBundle bundleForClass:
									 [self class]] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:prefs
													   forName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
    
    [prefs release];*/
}

// Workers
- (void)writeChangesToFile
{
	[serverSettings writeToFile:settingsFile atomically:YES];
}

- (void)updateStatusForProperty:(TCProperty)property
{
	int seconds;
	switch (property)
	{
		case TCPropLibraryCache:
			if ([[serverSettings valueForKey:@"useLibraryFile"] boolValue])
			{
				[libraryStatus setStringValue:@"Yes"];
				[libraryButton setTitle:@"Disable"];
			}
			else
			{
				[libraryStatus setStringValue:@"No"];
				[libraryButton setTitle:@"Enable"];
			}
			break;
		
		case TCPropPassword:
			if ([[serverSettings valueForKey:@"password"] isEqual:@""])
				[passwordStatus setStringValue:@"Disabled"];
			else
				[passwordStatus setStringValue:@"Enabled"];
			break;
		
		case TCPropExpiryTime:
			seconds = [[serverSettings valueForKey:@"libraryExpiryTime"] intValue];
			int minutes = seconds / 60;
			int hours = minutes / 60;
			int days = hours / 24;
			
			NSString *timeString;
			
			if ([[serverSettings valueForKey:@"useLibraryFile"] boolValue] == NO)
				timeString = @"N/A";
			else
			{
				if (days >= 1)
				{
					timeString = [NSString stringWithFormat:@"%d day", days];
					if (days > 1) timeString = [timeString stringByAppendingString:@"s"];
				}
				else if (hours >= 22)
					timeString = @"About 1 day";
				else if (hours ==  12)
					timeString = @"Half a day";
				else if (hours > 0)
				{
					timeString = [NSString stringWithFormat:@"%d hour", hours];
					if (hours > 1) timeString = [timeString stringByAppendingString:@"s"];
				}
				else if (minutes >= 55)
					timeString = @"About 1 hour";
				else if (minutes == 30)
					timeString = @"Half an hour";
				else if (minutes > 0)
				{
					timeString = [NSString stringWithFormat:@"%d minute", minutes];
					if (minutes > 1) timeString = [timeString stringByAppendingString:@"s"];
				}
				else if (seconds >= 55)
					timeString = @"About 1 minute";
				else if (seconds == 30)
					timeString = @"Half a minute";
				else if (seconds > 0)
				{
					timeString = [NSString stringWithFormat:@"%d second", seconds];
					if (seconds > 1) timeString = [timeString stringByAppendingString:@"s"];
				}
				else
					timeString = @"0 seconds? Huh?";
			}
			
			[expiryTime setStringValue:timeString];
			
			break;
		
		case TCPropPort:
			[portStatus setStringValue:[[serverSettings valueForKey:@"port"] stringValue]];
			break;
		
		case TCPropAutostart:
			if ([UKLoginItemRegistry indexForLoginItemWithPath:pathToApp] != -1)
				[autostartButton setState:NSOnState];
			else
				[autostartButton setState:NSOffState];
			
			break;
		
		default:
			NSLog(@"Error!");
			break;
	}
}

// Miscellaneous
- (TCExpiryTime)expiryTimeForSeconds:(int)seconds
{
	TCExpiryTime expiryInfo;
	
	if (seconds % 86400 == 0)
	{
		expiryInfo.value = (seconds / 86400);
		expiryInfo.unitOffset = 86400;
	}
	else if (seconds % 3600 == 0)
	{
		expiryInfo.value = (seconds / 3600);
		expiryInfo.unitOffset = 3600;
	}
	else if (seconds % 60 == 0)
	{
		expiryInfo.value = (seconds / 60);
		expiryInfo.unitOffset = 60;
	}
	else
	{
		expiryInfo.value = seconds;
		expiryInfo.unitOffset = 1;
	}
	
	return expiryInfo;
}

@end
