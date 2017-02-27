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

typedef enum {
	north, east, south, west, nDirections
} Direction;

@interface HMTVDD : HMPart {
	float **emigration;
	float **immigration;
	float *dispersion;
	NSMutableIndexSet *edges;
}
@property (strong) Hex *position;

- (float*)emigrationInDirection:(NSUInteger) direction;
- (float*)imigrationFromDirection:(NSUInteger) direction;
- (void)setImmigration:(float*)immigration fromDirection:(NSUInteger)direction;
- (NSIndexSet *)edges;
- (void)setEdges:(NSIndexSet *)anEdges;
- (Hex*)position;
- (void)setPosition:(Hex*)aPosition;

@end
