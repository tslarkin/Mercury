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

/*
 Ports are the places components (parts) connect.
*/
@interface HMPort : HMNode {
    // All output ports have values. Input ports have values if they are unconnected.
	Value value;
    // The part that owns the port.
	HMPart *part;
    // next is no longer used.
    HMPort *next;
    // The port that connects to this port.
	HMPort *previous;
    // The variable ID. This is an index into the list of inputs. This is used
    // instead of the name, since the user can change the name.
	int varid;
    // The ports Value as a string. This is what appears in the Hermes XML file.
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

// Does the port have a name that signals it is a global variable?
BOOL isGlobal(NSString *symbol);
