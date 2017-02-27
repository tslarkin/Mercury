//
//  HexMap.h
//  Mercury
//
//  Created by Timothy Larkin on 1/19/17.
//
//

#import <Foundation/Foundation.h>

@class HMLevel;

@interface Hex: NSObject
@property (assign) NSInteger r, q, s;
@property (strong) NSNumber *hashValue;
-(Hex*)initWithQ:(NSInteger)q andR:(NSInteger)r;
// Initialize with offset coordinates
-(Hex*)initWithX:(NSInteger) x andY:(NSInteger)y;
-(Hex*)neighbor:(NSInteger)direction;
@end

@interface HexTile : NSObject
@property (strong) Hex *hex;
@property (assign) HMLevel *model;

-(HexTile*)initWithHex:(Hex*)hex andModel:(HMLevel*)model;

@end

//@interface HexMap : NSObject
//
//@end
