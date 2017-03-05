//
//  Instantiator.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HMPart;
@class HMLevel;

// Read the Hermes document (XML) and produce an array of
// NSDictionary objects, each of which can be interpreted to
// produce an instance of a model component.
NSArray *XMLtoDictionaries(NSString *path);

// Given the array of dictionaries produced by the previous method,
// instantiate the objects.
HMLevel *partsFromDictionaries(NSArray *dictionaries);

// Create the simulation space, the set of model clones that
// cover the required space. (Currently this is not actually
// a matrix, it is a dictionary whose keys are the coordinates
// of the hexagons.
NSDictionary *buildMatrix(NSArray *dictionaries, int rows, int columns);

// Given this dictionary, connect each component to its corresponding
// copy in the neighboring hexagons.
void wireMatrix(NSDictionary *map);

// Record a time-varying distributed delay underflow event.
// (There's no particular reason that this scode appears in this file.)
void recordUnderflow(HMPart *part);

// Print the underflow events recorded above.
void printUnderflowRecords();
