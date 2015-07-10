//
//  HMLevel.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMPart.h"
@class HMPort;

@interface HMLevel : HMPart {
	NSArray *sublevels;
	NSArray *children;
	NSArray *flattened, *concurrencies;
}

- (NSArray *)sublevels;
- (void)setSublevels:(NSArray *)aSublevels;

- (HMPart*)partWithName:(NSString*)name;
- (HMPort*)portWithName:(NSString*)portName ofPart:(NSString*)partName;
- (HMPort*)outputPortFromPath:(NSString*)path;
- (HMPort*)inputPortFromPath:(NSString*)path;

- (NSArray *)children;
- (void)setChildren:(NSArray *)aChildren;

- (NSArray *)flattened;
- (void)setFlattened:(NSArray *)aFlattened;

-(NSArray*)concurrencies;
-(void)setConcurrencies:(NSArray*)concurrencies;
@end
