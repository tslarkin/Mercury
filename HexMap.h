//
//  HexMap.h
//  Mercury
//
//  Created by Timothy Larkin on 1/19/17.
//
//

#import <Foundation/Foundation.h>

// For a detailed discussion of hexagon tiling see
// http://www.redblobgames.com/grids/hexagons/
// Most of this code is taken directly from that article.

@class HMLevel;

// A Hex object is a hexagon.
@interface Hex: NSObject
// Each hexagon has three possible coordinates. However, a basis
// for the 2D space can be formed from any two of these. In
// this code, the basis is r (row) and q (a diagonal column).
// s is a dependent vector = -(r + q)
@property (assign) NSInteger r, q, s;

// The tiles (hexagons) are stored in a dictionary using
// the hashValue as a key.
@property (strong) NSNumber *hashValue;

// Initializer with "natural" (r, q) coordinates.
-(Hex*)initWithQ:(NSInteger)q andR:(NSInteger)r;

// Hexagons with r, q coordinates naturally form a parallelogram. To
// cover a rectangular space, we use offset coordinates, which form
// a space with orthogonal axes.
// Initialize with offset coordinates
-(Hex*)initWithX:(NSInteger) x andY:(NSInteger)y;

// Get the neighbor in one of the six directions.
-(Hex*)neighbor:(NSInteger)direction;
@end

// A HexTile is a hexagon with a model attached. Hermes space
// is tesselated with HexTiles.
@interface HexTile : NSObject
@property (strong) Hex *hex;
@property (assign) HMLevel *model;

-(HexTile*)initWithHex:(Hex*)hex andModel:(HMLevel*)model;

@end

//@interface HexMap : NSObject
//
//@end
