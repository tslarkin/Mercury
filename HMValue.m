//
//  HMValue.m
//  Hermes
//
//  Created by Timothy Larkin on 11/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "HMValue.h"


@implementation HMValue


- (NSManagedObject *)port 
{
    id tmpObject;
    
    [self willAccessValueForKey: @"port"];
    tmpObject = [self primitiveValueForKey: @"port"];
    [self didAccessValueForKey: @"port"];
    
    return tmpObject;
}

- (void)setPort:(NSManagedObject *)value 
{
    [self willChangeValueForKey: @"port"];
    [self setPrimitiveValue: value
                     forKey: @"port"];
    [self didChangeValueForKey: @"port"];
}


- (BOOL)validatePort: (id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

-(id)defaultValue
{
	return nil;
}

-(void)setValue:(id)value
{
	
}

-(id)value
{
	return nil;
}

- (BOOL)isRemoteValue
{
	return NO;
}

- (NSString*)transformedValue
{
	return nil;
}


- (void)reverseTransformValue:(NSString*)string
{
	
}

@end
