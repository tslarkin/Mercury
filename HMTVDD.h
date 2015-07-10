//
//  HMTVDD.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMPart.h"

typedef enum {
	north, east, south, west, nDirections
} Direction;

@interface HMTVDD : HMPart {
	float **emigration;
	float **imigration;
	float *dispersion;
	NSIndexSet *edges;
	NSPoint position;
}

- (float*)emigrationInDirection:(Direction) direction;
- (float*)imigrationFromDirection:(Direction) direction;
- (void)setImigration:(float*)imigration fromDirection:(Direction)direction;
- (NSIndexSet *)edges;
- (void)setEdges:(NSIndexSet *)anEdges;
- (NSPoint)position;
- (void)setPosition:(NSPoint)aPosition;

@end
