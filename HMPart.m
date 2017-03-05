//
//  HMPart.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMPart.h"
#import "HMInput.h"
#import "HMOutput.h"
#import "Parsing.h"
#import "HMPort.h"


@implementation HMPart

-(id)init
{
	self = [super init];
	attraction = 0;
	parent = nil;
	return self;
}

#pragma mark Getters & Setters
//=========================================================== 
//  parent 
//=========================================================== 
- (HMNode *)parent
{
    return parent; 
}
- (void)setParent:(HMNode *)aParent
{
    if (parent != aParent) {
        [aParent retain];
        [parent release];
        parent = aParent;
    }
}

- (HMNode*)superior
{
	return (HMNode*)[self parent];
}



//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
	[self setMap:nil];
    [self setInputs:nil];
    [self setOutputs:nil];
    [self setParent:nil];
    [self setFinalInputValues:nil];
    [super dealloc];
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
		HMInput *input;
		NSEnumerator *e = [inputs objectEnumerator];
		while (input = [e nextObject]) {
			[input value]->port = input;
		}
    }
}

-(NSArray*)otherDependencies
{
    return nil;
}

//=========================================================== 
//  outputs 
//=========================================================== 
- (NSArray *)outputs
{
    return outputs; 
}
- (void)setOutputs:(NSArray *)anOutputs
{
    if (outputs != anOutputs) {
        [anOutputs retain];
        [outputs release];
        outputs = anOutputs;
		NSEnumerator *e = [outputs objectEnumerator];
		HMOutput *output;
		while (output = [e nextObject]) {
			[output value]->port = output;
		}
    }
}

- (void)awake 
{
	
}

// This is called at model initialization to determine the date for the
// start of the simulation. This default method simply returns the suggested date.
-(NSTimeInterval)findLatestStartTime:(NSTimeInterval)start
{
    return start;
}

// This is where the part is initialized.
- (void)initialize
{
	NSEnumerator *e = [inputs objectEnumerator];
	HMInput *input;
    // Iterate the inputs.
	while ((input = [e nextObject])) {
        // The input may be connected to an ouput. Then referenceP returns true.
		if (![input referenceP]) {
            // If it's not connected to an output, then it must define a
            // constant. Use valueParse to convert the string representation of
            // the constant to a Value.
			NSString *s = [input stringvalue];
			if (s) {
				char error[256];
				valueParse([[input stringvalue] cStringUsingEncoding:NSMacOSRomanStringEncoding], [input value], error);
				NSAssert([input value]->utype != 0, @"Couldn't initialize input");
			}
		}
	}
	Value *val;
	NSMutableArray *tmp = [NSMutableArray array];
	e = [inputs objectEnumerator];
    // Now go through all the inputs and collect the Values that feed them.
	while ((input = [e nextObject])) {
		val = [input finalValue];
		[tmp addObject:[NSValue valueWithPointer:val]];
	}
	[self setFinalInputValues:tmp];
}

// The default updateStates and updateRates do nothing.
- (void)updateStates
{
	
}

- (void)updateRates
{
	
}

- (void)computeEmigrationFromAttractions
{
	
}

//=========================================================== 
//  doesWork 
//===========================================================
// Attraction is currently unused.
- (BOOL)hasAttraction
{
    return YES;
}

// This method is used during XML initialization to find the port referenced by
// a stepper. This is called recursively from the top of the graph. This is the
// terminal method. The path will consist of two components, the part name
// and the port name.
- (HMPort*)recursiveSearchOnPath:(NSArray*)path forPortIn:(NSString*)portSet
{
	if ([path count] != 2
		|| ![[self name] isEqualToString:[path objectAtIndex:0]]) {
		return nil;
	}
	NSString *portName = [path objectAtIndex:1];
    // portSet is either "inputs" or "outputs".
	NSEnumerator *e = [[self valueForKey:portSet] objectEnumerator];
	HMPort *port;
	while (port = [e nextObject]) {
		if ([[port name] isEqualToString:portName]) {
			break;
		}
	}
	return port;
}

// A part searches inputs and outputs for a port with a name matching aName.
- (HMPort*)portWithName:(NSString*)aName
{
	NSEnumerator *e = [[[self inputs] arrayByAddingObjectsFromArray:[self outputs]] objectEnumerator];
	HMPort *port;
	while((port = [e nextObject])) {
		if([[port name] compare:aName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			break;
		}
	}
	return port;
}

// Return self if self's name is aName.
- (HMPart*)partWithName:(NSString*)aName
{
	if ([[self name] isEqualToString:aName]) {
		return self;
	}
	else {
		return nil;
	}
}

// Return self if self's nodeID matches aNodeID
- (HMPart*)partWithNodeID:(NSString*)aNodeID
{
	if ([[self nodeID] isEqualToString:aNodeID]) {
		return self;
	}
	else {
		return nil;
	}
}

// Initialize the string value of port portName to valueString, the
// string representation of a Value.
- (void)setInitialValue:(NSString*)valueString forPort:(NSString*)portName
{
	HMPort *port = [self portWithName:portName];
	[port setStringvalue:valueString];
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return nil;
}

- (HMInput*)input:(int)index
{
	return (HMInput*)[[self inputs] objectAtIndex:index];
	
}

- (HMOutput*)output:(int)index
{
	return (HMOutput*)[[self outputs] objectAtIndex:index];	
}

- (Value*)inputValue:(int)index
{
	return [[self input:index] value];
}

- (Value*)outputValue:(int)index
{
	return [[self output:index] value];
}

//=========================================================== 
//  finalValues 
//=========================================================== 
- (NSArray *)finalInputValues
{
    return finalInputValues; 
}
- (void)setFinalInputValues:(NSArray *)aFinalValues
{
    if (finalInputValues != aFinalValues) {
        [aFinalValues retain];
        [finalInputValues release];
        finalInputValues = aFinalValues;
    }
}

- (Value*)finalInputValueAt:(int)index
{
	return [[finalInputValues objectAtIndex:index] pointerValue];
}

//=========================================================== 
//  attraction
//=========================================================== 
- (float)attraction
{
    return attraction;
}
- (void)setAttraction:(float)anAttraction
{
    attraction = anAttraction;
}

//=========================================================== 
//  map 
//=========================================================== 
- (NSDictionary *)map
{
    return map; 
}
- (void)setMap:(NSDictionary *)aMap
{
    if (map != aMap) {
        [aMap retain];
        [map release];
        map = aMap;
    }
}

//=========================================================== 
// - color
//=========================================================== 
- (Color)color {
    return color;
}
//=========================================================== 
// - setColor:
//=========================================================== 
- (void)setColor:(Color)aColor {
    color = aColor;
}

//=========================================================== 
//  begin 
//=========================================================== 
- (unsigned)begin
{
    return begin;
}
- (void)setBegin:(unsigned)aBegin
{
    begin = aBegin;
}

//=========================================================== 
//  end 
//=========================================================== 
- (unsigned)end
{
    return end;
}
- (void)setEnd:(unsigned)anEnd
{
    end = anEnd;
}

// Recursively construct the full path to a part. This is redundant with fullPath.
- (NSString*)path
{
	NSString *parentPath = @"";
	if ([self parent] != nil) {
		parentPath = [(HMPart*)[self parent] path];
	}
	NSString *myname = [self name];
	if (!myname) {
		myname = [self className];
	}
	NSString *path = [NSString stringWithFormat:@"%@/%@", parentPath, myname];
	return path;
}

// These two methods are used to determine whether a port at index i
// creates a dependency.
-(BOOL)isRatePhaseInput:(Fixed)i
{
    return YES;
}

-(BOOL)isRatePhaseOutput:(Fixed)i
{
    return YES;
}

// Collect the outputs that are marked to record their values.
- (void)collectRecorders:(NSMutableArray*)collection
{
	NSEnumerator *e = [[self valueForKey:@"outputs"] objectEnumerator];
	HMOutput *output;
	while (output = [e nextObject]) {
		if ([output recordP]) {
			[collection addObject:output];
		}
	}
}

@end
