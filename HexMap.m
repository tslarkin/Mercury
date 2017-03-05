//
//  HexMap.m
//  Mercury
//
//  Created by Timothy Larkin on 1/19/17.
//
//

#import "HexMap.h"

// The hash function. So far, this is good enough to avoid
// collisions. It is based on the <reference needed> function.
// The orginal (hq << 6) has been changed to (hq << 8) to
// eliminate collisions.
NSNumber *hexHash(NSInteger r, NSInteger q)
{
    NSInteger hr = r;
    NSInteger hq = q;
    NSInteger hash = hq ^ (hr + 0x9e3779b9 + (hq << 8) + (hq >> 2));
    return [NSNumber numberWithLong:hash];
}

@class Hex;
Hex *makeHex(NSInteger r, NSInteger q);

NSArray *hexDirections;

@implementation Hex

-(void)dealloc
{
    [_hashValue release];
    [super dealloc];
}

// Initializer for r-q space.
-(Hex*)initWithQ:(NSInteger) q andR:(NSInteger)r
{
    self = [super init];
    self.q = q;
    self.r = r;
    self.s = -(r + q);
    self.hashValue = hexHash(r, q);
    return self;
}

// Initializer for x-y space.
-(Hex*)initWithX:(NSInteger)col andY:(NSInteger)row
{
    self = [super init];
    self.q = col - (row + (row & 1)) / 2;
    self.r = row;
    self.s = -(self.q + self.r);
    self.hashValue = hexHash(self.r, self.q);
    return self;
}

// Return an offset from the hex.
-(Hex*)add:(Hex*)h
{
    return [[[Hex alloc] initWithQ:self.q + h.q andR:self.r + h.r] autorelease];
}

// Get the hex neighbor in one of the six directions.
-(Hex*)neighbor:(NSInteger)direction
{
    if (hexDirections == nil) {
        hexDirections  = @[makeHex(1, 0), makeHex(1, -1), makeHex(0, -1), makeHex(-1, 0), makeHex(-1, 1), makeHex(0, 1)];
    }
    return [self add:hexDirections[direction]];
}


@end

Hex *makeHex(NSInteger q, NSInteger r)
{
    return [[[Hex alloc] initWithQ:q andR:r] autorelease];
}

@implementation HexTile

-(void)dealloc
{
    [_hex release];
    [super dealloc];
}

-(HexTile*)initWithHex:(Hex*)hex andModel:(HMLevel*)model
{
    self = [super init];
    self.hex = hex;
    self.model = model;
    return self;
}

@end

//@implementation HexMap
//
//@end
