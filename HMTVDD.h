//
//  HMTVDD.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMPart.h"
#import "HexMap.h"

// These were the directions used in the old rectangular Hermes space.
// These have been superceded by hexagonal directions.
typedef enum {
	north, east, south, west, nDirections
} Direction;

@interface HMTVDD : HMPart {
    // A pointer to a set of six pointers to arrays of length k,
    // which record the age-distributed emigration rates.
	float **emigration;
    // A pointer to six pointers to emigration variables from
    // neighboring hexagons.
	float **immigration;
    // dispersion is no longer used. This is not to be confused
    // with the input tv1_dispersion.
	float *dispersion;
    // Edges where immigration can occur.
	NSMutableIndexSet *edges;
}
// The Hex giving the coordinates of this component's model in Hermes space.
@property (strong) Hex *position;

- (float*)emigrationInDirection:(NSUInteger) direction;
- (float*)imigrationFromDirection:(NSUInteger) direction;
- (void)setImmigration:(float*)immigration fromDirection:(NSUInteger)direction;
- (NSIndexSet *)edges;
- (void)setEdges:(NSIndexSet *)anEdges;
- (Hex*)position;
- (void)setPosition:(Hex*)aPosition;

@end
