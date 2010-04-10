//
//  SUUtilities.h
//  Sparkle
//
//  Created by Andy Matuschak on 3/12/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

id SUInfoValueForKey(NSString *key);
id SUUnlocalizedInfoValueForKey(NSString *key);
NSString *SUHostAppName();
NSString *SUHostAppDisplayName();
NSString *SUHostAppVersion();
NSString *SUHostAppVersionString();
NSString *SUCurrentSystemVersionString();

/*!
 * @brief Compare two version strings
 *
 * If versionA is the possible new version and versionB is the reference version (current application version), the result will be NSOrderedDescending if
 * versionA is an update.
 *
 * @param versionA First version
 * @param versionB Second version
 *
 * @result NSOrderedDescending if versionA is newer than versionB. NSOrderedSame if they are the same version. NSOrderedAscending if versionA is older than versionB.
 */
NSComparisonResult SUStandardVersionComparison(NSString * versionA, NSString * versionB);

// If running make localizable-strings for genstrings, ignore the error on this line.
NSString *SULocalizedString(NSString *key, NSString *comment);
