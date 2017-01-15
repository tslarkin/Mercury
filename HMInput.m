//
//  HMInput.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMInput.h"
#import "HMOutput.h"

extern NSArray *globals;

@implementation HMInput

//=========================================================== 
//  provider 
//=========================================================== 
- (HMOutput *)provider
{
    return provider; 
}
- (void)setProvider:(HMOutput *)aProvider
{
    if (provider != aProvider) {
        [aProvider retain];
        [provider release];
        provider = aProvider;
    }
}

- (HMPort*)finalSource
{
	if (isGlobal([self name])) {
		NSString *nomen = [self name];
		NSEnumerator *e = [globals objectEnumerator];
		HMOutput *source;
		while ((source = [e nextObject])) {
			if([[source name] isEqualToString:nomen]) {
				break;
			}
		}
		if (!source) {
			[NSException raise:@"Simulation terminated" 
						format: @"Couldn't find global for \"%@\"", nomen];
		}
		return source;
	}
	HMInput *link = self;
	HMPort *final = nil;
	while (YES) {
		if ([link provider]) {
			final = [[link provider] finalSource];
			break;
		}
		if (![link previous]) {
			final = link;
			break;
		}
		else {
			link = (HMInput*)[link previous];
		}
	}
	return final;
}

- (Value*)finalValue
{
	if (isGlobal([self name])) {
		NSString *nomen = [self name];
		NSEnumerator *e = [globals objectEnumerator];
		HMOutput *source;
		while ((source = [e nextObject])) {
			if([[source name] isEqualToString:nomen]) {
				break;
			}
		}
		if (!source) {
			[NSException raise:@"Simulation terminated" 
						format:@"Couldn't find global for \"%@\"", nomen];
		}
		return [source value];
	}
	HMInput *link = self;
	Value *val = (Value*)nil;
	while (YES) {
		if ([link provider]) {
			val = [[link provider] finalValue];
			break;
		} else if (![link previous]) {
			val = [link value];
			break;
		} else {
			link = (HMInput*)[link previous];
		}
	}
	HMPort *tmp = [self finalSource];
	NSAssert([tmp value] == val, @"Value of final source != final value");
	return val;
}

- (BOOL) referenceP 
{ 
	return [super referenceP]  || [self provider]; 
}



//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setProvider:nil];
    [super dealloc];
}

- (Value*)value
{
	if (provider) {
		return [provider value];
	} else 
		return &value; 
}

@end
