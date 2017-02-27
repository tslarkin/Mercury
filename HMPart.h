//
//  HMPart.h
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMNode.h"
#import "Value.h"

@class HMPort;
@class HMInput;
@class HMOutput;

typedef enum{kwhite,kblack,kgray}Color;

@interface HMPart : HMNode {
	HMNode *parent;
	NSArray *inputs;
	NSArray *outputs;
	float attraction;
	NSDictionary *map;
	NSArray *finalInputValues;
	Color color;
	unsigned begin;
	unsigned end;
}
- (Color)color;
- (void)setColor:(Color)aColor;
- (unsigned)begin;
- (void)setBegin:(unsigned)aBegin;
- (unsigned)end;
- (void)setEnd:(unsigned)anEnd;

- (NSString*)path;

- (NSArray *)finalInputValues;
- (void)setFinalInputValues:(NSArray *)aFinalValues;
- (Value*)finalInputValueAt:(int)index;

- (BOOL)hasAttraction;

- (HMPort*)portWithName:(NSString*)name;
- (HMPart*)partWithName:(NSString*)name;
- (HMPart*)partWithNodeID:(NSString*)nodeID;

- (HMNode *)parent;
- (void)setParent:(HMNode *)aParent;

- (NSArray *)inputs;
- (void)setInputs:(NSArray *)anInput;
- (NSArray *)otherDependencies;

- (Value*)inputValue:(int)index;
- (Value*)outputValue:(int)index;
- (HMInput*)input:(int)index;
- (HMOutput*)output:(int)index;

- (NSArray *)outputs;
- (void)setOutputs:(NSArray *)anOutput;

- (void)initialize;
- (void)updateStates;
- (void)updateRates;
-(NSTimeInterval)findLatestStartTime:(NSTimeInterval)start;

- (float)attraction;
- (void)setAttraction:(float)anAttraction;
- (void)computeEmigrationFromAttractions;

- (void)setInitialValue:(NSString*)valueString forPort:(NSString*)portName;

- (NSDictionary *)map;
- (void)setMap:(NSDictionary *)aMap;


-(BOOL)isRatePhaseInput:(Fixed)i;
-(BOOL)isRatePhaseOutput:(Fixed)i;

- (void)collectRecorders:(NSMutableArray*)collection;

- (HMPort*)recursiveSearchOnPath:(NSArray*)path forPortIn:(NSString*)portSet;

- (void)awake;

@end
