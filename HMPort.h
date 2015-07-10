//
//  HMPort.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMNode.h"
#import "Value.h"

@class HMPart;

@interface HMPort : HMNode {
	Value value;
	HMPart *part;
	HMPort *next;
	HMPort *previous;
	int varid;
	NSString *stringvalue;
//	NSNumber *record;
}

- (Value*)value;
- (Value*)finalValue;
- (HMPort*)finalSource;

- (HMPart *)part;
- (void)setPart:(HMPart *)value;

- (HMPort *)next;
- (void)setNext:(HMPort *)value;

- (HMPort *)previous;
- (void)setPrevious:(HMPort *)value;

- (NSString *)stringvalue;
- (void)setStringvalue:(NSString*)s;

- (void)recordValue:(FILE*)file;

- (HMPort*)reference;
- (BOOL) referenceP;
- (HMPort*) ifReference;

- (int)varid;

@end

BOOL isGlobal(NSString *symbol);
