//
//  TCISODateFormatter.h
//  TuneConnect
//
//  Created by Matt Patenaude on 2/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TCISODateFormatter : NSValueTransformer {

}

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;

@end
