//
//  HMPort.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMPort.h"
#import "HMPart.h"
#import "Parsing.h"
#import <regex.h>

BOOL isGlobal (NSString *name)
{
	regmatch_t pmatch;
	regex_t preg;
	int error = 0;
	error = regcomp(&preg, "^\\[[A-Za-z][A-Za-z0-9]*\\]$", REG_EXTENDED);
	size_t nMatches = 1;
	const char *q = [name cStringUsingEncoding:NSMacOSRomanStringEncoding];
	error = regexec(&preg, q, nMatches, &pmatch, 0);
	regfree(&preg);	
	return !error;
}

@implementation HMPort

- (id)init
{
	[super init];
	return self;
}

- (HMNode*)superior
{
	return [self part];
}


- (int)varid
{
	return varid;
}

- (void)setVarid:(int)z
{
	varid = z;
}

//=========================================================== 
//  stringValue 
//=========================================================== 
- (NSString *)stringvalue
{
    return stringvalue; 
}
- (void)setStringvalue:(NSString *)aStringValue
{
    if (stringvalue != aStringValue) {
        [aStringValue retain];
        [stringvalue release];
        stringvalue = aStringValue;
		char error[256];
		valueParse([stringvalue cStringUsingEncoding:NSMacOSRomanStringEncoding], &value, error);
		if (value.utype == undefined) {
			[NSException raise:@"Bad constant value" format:@"%@", [NSString stringWithCString:error encoding:NSMacOSRomanStringEncoding]];
		}
    }
}


//=========================================================== 
//  value 
//=========================================================== 
- (Value*)value
{
	return &value; 
}

- (Value*)finalValue
{
	return (Value*)nil;
}

- (HMPort*)finalSource
{
	return nil;
}

-(void)recordValue:(FILE*)file
{
	NSString *stringValue(Value *val);
	NSString *val = stringValue([self finalValue]);
	fprintf(file, "%s", [val cStringUsingEncoding:NSMacOSRomanStringEncoding]);
}

- (BOOL) referenceP 
{ 
	return [self finalSource] != self; 
}

- (HMPort*)reference
{
	if(![self referenceP]) {
//		[TypeMismatch raiseException:self desiredType:kreference];
	}
	return [self finalSource];
}

- (HMPort*) ifReference 
{ 
	if([self referenceP]) return [self finalSource]; else return nil;
}


//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setStringvalue:nil];
    [self setPart:nil];
    [self setNext:nil];
    [self setPrevious:nil];
	freeValue(&value);
    [super dealloc];
}


//=========================================================== 
//  part 
//=========================================================== 
- (HMPart *)part
{
    return part; 
}
- (void)setPart:(HMPart *)aPart
{
    if (part != aPart) {
        [aPart retain];
        [part release];
        part = aPart;
    }
}

//=========================================================== 
//  next 
//=========================================================== 
- (HMPort *)next
{
    return next; 
}
- (void)setNext:(HMPort *)aNext
{
    if (next != aNext) {
        [aNext retain];
        [next release];
        next = aNext;
    }
}

//=========================================================== 
//  previous 
//=========================================================== 
- (HMPort *)previous
{
    return previous; 
}
- (void)setPrevious:(HMPort *)aPrevious
{
    if (previous != aPrevious) {
        [aPrevious retain];
        [previous release];
        previous = aPrevious;
    }
}

@end
