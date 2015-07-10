//
//  HMStepper.m
//  Hernix
//
//  Created by Timothy Larkin on 12/1/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMStepper.h"
#import "HMInput.h"

@implementation HMStepper

- (id)initWithStart:(float)astart step:(float)astep andStop:(float)astop
{
	[super init];
	[self setStart:astart];
	[self setStep:astep];
	[self setStop:astop];
	return self;
}

- (void)startWithPath:(NSString*)path andInferiors:(NSArray*)inferiors;
{
	float setting = [self start];
	NSString *s;
	do {
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		s = [[NSString alloc] initWithFormat:@"%f", setting];
		NSEnumerator *e = [inputs objectEnumerator];
		HMInput *input;
		while (input = [e nextObject]) {
			[input setStringvalue:s];
		}
		[s release];
		HMStepper *inferior = [inferiors objectAtIndex:0];
		NSRange range = NSMakeRange(1, [inferiors count] - 1);
		s = [[NSString alloc] initWithFormat:@"%@%f\t", path, setting];
		[inferior startWithPath:s
				   andInferiors:[inferiors subarrayWithRange:range]];
		[s release];
		setting += [self step];
		[pool release];
	} while (setting <= [self stop]);
}

//=========================================================== 
//  name 
//=========================================================== 
- (NSString *)name
{
    return name; 
}
- (void)setName:(NSString *)aName
{
    if (name != aName) {
        [aName retain];
        [name release];
        name = aName;
    }
}


//=========================================================== 
//  inputs 
//=========================================================== 
- (NSArray *)inputs
{
    return inputs; 
}
- (void)setInputs:(NSArray *)anInputs
{
    if (inputs != anInputs) {
        [anInputs retain];
        [inputs release];
        inputs = anInputs;
    }
}


//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setName:nil];
    [self setInputs:nil];
    [super dealloc];
}

//=========================================================== 
//  start 
//=========================================================== 
- (float)start
{
    return start;
}
- (void)setStart:(float)aStart
{
    start = aStart;
}

//=========================================================== 
//  step 
//=========================================================== 
- (float)step
{
    return step;
}
- (void)setStep:(float)aStep
{
    step = aStep;
}

//=========================================================== 
//  stop 
//=========================================================== 
- (float)stop
{
    return stop;
}
- (void)setStop:(float)aStop
{
    stop = aStop;
}


@end
