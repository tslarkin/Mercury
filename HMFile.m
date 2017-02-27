//
//  HMFile.m
//  Hernix
//
//  Created by Timothy Larkin on 4/5/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMFile.h"
#import "Parsing.h"
#import "AppController.h"
#include <stdlib.h>

float strtof(const char *start, char **end);

@implementation HMFile

-(void)dealloc
{
	fclose(file);
	[super dealloc];
}

- (void)updateStates
{
}

- (void)reportEOF
{
	eof = YES;
	NSValue *v = [[self finalInputValues] objectAtIndex:0];
	Value *val = (Value*)[v pointerValue];
	char *path = pathValue(val);
	NSException *e = [NSException exceptionWithName:@"Simulation forced to end"
											 reason:[NSString stringWithFormat:@"End of file reached in file %s", path]
										   userInfo:nil];
	[e raise];
}

- (void)updateRates
{
	if (eof) {
		setFloatValue([self outputValue:0], 0.0);
		return;
	}
	char s[128];
	char *pend;
	BOOL found = NO;
	float x;
	int result;
	do {
		result = fscanf(file, "%s", s);
		if ((result == EOF) || (result == 0)) {
//			x = 0;
			[self reportEOF];
		}
		x = strtof(s, &pend);
		if (pend != s) {
			found = YES;
		}
	} while ((!found) && (!eof));
	char c;
	if (!eof) {
		do {
			result = fscanf(file, "%c", &c);
			if (result == EOF) {
				[self reportEOF];
			}
		} while ((c != '\n') && (c != '\r') && (!eof));
	}
	setFloatValue([self outputValue:0], x);
}

- (void)initialize
{
	[super initialize];
	NSValue *v = [[self finalInputValues] objectAtIndex:0];
	Value *val = (Value*)[v pointerValue];
	const char *path = pathValue(val);
	file = fopen(path, "r");
    if (!file) {
        NSString *nspath = [NSString stringWithCString:path encoding:NSUTF8StringEncoding];
        NSString *filename = [nspath lastPathComponent];
        extern NSString *defaultDirectory;
        NSString *otherPath = [NSString stringWithFormat:@"%@/%@", defaultDirectory, filename];
        path = otherPath.UTF8String;
        file = fopen(path, "r");
    }
	if (!file) {
		NSException *e = [NSException exceptionWithName:@"Simulation aborted"
												 reason:[NSString stringWithFormat:@"Could not open file %s in part %@", 
														 path, [self fullPath]]
											   userInfo:nil];
		[e raise];
		
	}
	eof = NO;
}

-(BOOL)isExternalRateVariable:(Fixed) i
{
	return NO;
}

@end
