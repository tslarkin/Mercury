//
//  HMTVDD.m
//  Hernix
//
//  Created by Timothy Larkin on 2/23/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMTVDD.h"
#import "Value.h"
#import "HMInput.h"
#import "HMOutput.h"
#import "HMLevel.h"
#include <math.h>

long random(void);

enum{tv1_ratein, tv1_k, tv1_lossrate,tv1_initialstate,tv1_delaytime, tv1_dispersion,
		tv1_inseep, tv1_outseepcoef};

enum{tv1_rateout,tv1_store,tv1_innerstates,tv1_innerrates,
	   tv1_translatedout,tv1_lossrates, tv1_outputsize};

extern float dT;
extern HMOutput *gTime;


@implementation HMTVDD

//=========================================================== 
//  edges 
//=========================================================== 
- (NSIndexSet *)edges
{
    return edges; 
}
- (void)setEdges:(NSIndexSet *)anEdges
{
    if (edges != anEdges) {
        [anEdges retain];
        [edges release];
        edges = anEdges;
    }
}

- (void)freeMemory
{
	if (dispersion) {
		free(dispersion);
	}
	int i;
	if (emigration) {
		for (i = 0; i < nDirections; i++) {
			free(emigration[i]);
		}
		free(emigration);
	}
	if (imigration) {
		free(imigration);
	}
	freeValue([self outputValue:tv1_innerstates]);
	freeValue([self outputValue:tv1_innerrates]);
	freeValue([self outputValue:tv1_lossrates]);
	freeValue([self outputValue:tv1_translatedout]);
}


//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setEdges:nil];
	[self freeMemory];
    [super dealloc];
}

- (void)initialize
{
	[super initialize];
	[self freeMemory];
	int k = intValue([self finalInputValueAt:tv1_k]);
	
	if (k <= 0) {
		[NSException raise:@"Simulation terminated" 
					format:@"k for %@ was not greater than zero", [self fullPath]];
	}
	
	
	float *tmp = calloc(k, sizeof(float));
	setArrayValue([self outputValue:tv1_innerstates], tmp, k);
	tmp = calloc(k, sizeof(float));
	setArrayValue([self outputValue:tv1_innerrates], tmp, k);
	tmp = calloc(k, sizeof(float));
	setArrayValue([self outputValue:tv1_lossrates], tmp, k);
	tmp = calloc(k, sizeof(float));
	setArrayValue([self outputValue:tv1_translatedout], tmp, k);
	Value *val;
	val = [self finalInputValueAt:tv1_inseep];
	//if (val->utype == undefined) {
		tmp = calloc(k, sizeof(float));
		setArrayValue(val, tmp, k);
	//}
	setFloatValue([self outputValue:tv1_rateout], 0);
	
//	dispersion = calloc(k, sizeof(float));
//	imigration = calloc(nDirections, sizeof(float*));
//	emigration = calloc(nDirections, sizeof(float*));
	int i;
//	for (i = 0; i < nDirections; i++) {
//		float *tmp = calloc(k, sizeof(float));
//		emigration[i] = tmp;
//	}
	
	HMInput *initialState = [inputs objectAtIndex:tv1_initialstate];
	val = [initialState value];
	float store = 0;
	tmp = arrayValue([self outputValue:tv1_innerstates]);
	if (val->utype == floattype) {
		tmp[0] = floatValue(val);
		store = floatValue(val);
	}
	else if (val->utype == arraytype) {
		int n = k;
		float *v = arrayValue(val);
		if(val->length1 < k) {
			n = val->length1;
		}
		memcpy(tmp, v, sizeof(float) * k);
		for (i = 0; i < n; i++) {
			store+= v[i];
		}
	}
	else {
		if (val->utype != arraytype) {
			[NSException raise:@"Simulation terminated" 
						format:@"Wrong type for value"];
		}
	}
	setFloatValue([self outputValue:tv1_store], store);
}

NSString *stringValue(Value *val);

- (void)updateStates
{
	int k = intValue([self finalInputValueAt:tv1_k]);
	float ratein = floatValue([self finalInputValueAt:tv1_ratein]);
	float *seepin = arrayValue([self finalInputValueAt:tv1_inseep]);
	float *states = arrayValue([self outputValue:tv1_innerstates]);
	float *rates = arrayValue([self outputValue:tv1_innerrates]);
	float *loss = arrayValue([self outputValue:tv1_lossrates]);
	float *seepout = arrayValue([self outputValue:tv1_translatedout]);
	float store = 0.0;
	int i;
	for (i = 0; i < k; i++) {
		float factor;
//		for (j = 0; j < nDirections; j++) {
//			if (imigration[j]) {
//				tmp2 += imigration[j][i];
//			}
//
//			tmp += emigration[j][i];
//		}
		
		factor = ratein + seepin[i] - (rates[i] + loss[i] + seepout[i]);
//		factor = ratein - (rates[i] + loss[i] - seepout[i]);
		states[i] += dT * factor;
        if (states[i] < 0.0 && states[i] > -1.0e-4) {
            states[i] = 0.0;
        }
		NSAssert3 ((states[i] >= -1.0e-4) && states[i] < 1.0e10,
				   @"Error: Negative or infitite state\nComponent:%@, Value: %f\nTime: %@",
				   [self path], states[i], stringValue([gTime value]));
		ratein = rates[i];
		store += states[i];
	}
	setFloatValue([self outputValue:tv1_store], store);
}

-(BOOL)isRatePhaseInput:(Fixed)i
{
    static int set[] = {tv1_k, tv1_lossrate,tv1_delaytime,
        tv1_outseepcoef};
	int j;
    for(j = 0;j<4;j++)
        if(i == set[j])return YES;
    return NO;
}

-(BOOL)isRatePhaseOutput:(Fixed)i
{
    static int set[] = {tv1_store,tv1_innerstates};
    int j;
    for(j = 0;j<2;j++)
        if(i == set[j])return NO;
    return YES;
}

- (void)updateRates
{
	int k = intValue([self finalInputValueAt:tv1_k]);
	int i;
	float *states = arrayValue([self outputValue:tv1_innerstates]);
	float *rates = arrayValue([self outputValue:tv1_innerrates]);
	float *loss = arrayValue([self outputValue:tv1_lossrates]);
	float *seepout = arrayValue([self outputValue:tv1_translatedout]);
	float delaytime = floatValue([self finalInputValueAt:tv1_delaytime]);
	if (!(delaytime > 0)) {
		HMPart *source = [[[self input:tv1_delaytime] finalSource] part];
		NSLog(@"Error: Non-positive delaytime\nIn:%@\nFrom:%@\nValue: %f\nTime: %f", 
				   [self path], [source path], delaytime, floatValue([gTime value]));
	}
	float dr = k / delaytime;
	float lr = floatValue([self finalInputValueAt:tv1_lossrate]);
	float sr = floatValue([self finalInputValueAt:tv1_outseepcoef]);
	float state;
	for (i = 0; i < k; i++) {
		state = states[i];
		rates[i] = state * dr;
		loss[i] = state * lr;
		seepout[i] = state * sr;

		NSAssert3 ((state >= -1.0e-10) && state < 1.0e10,
				   @"Error: Negative or infinite state\nComponent:%@, Value: %f\nTime: %@", 
				   [self path], state, stringValue([gTime value]));
	}
	setFloatValue([self outputValue:tv1_rateout], rates[k - 1]);
	
//	float dispersionRate = floatValue([(HMPort*)[inputs objectAtIndex:tv1_dispersion] value]);
//	dispersionRate = dispersionRate / nDirections;
//	for (i = 0; i < k; i++) {
//		state = states[i];
//		dispersion[i] = state * dispersionRate;
//	}
//	float flux;
//	for(i = 0; i < nDirections; i++) {
//		for (j = 0; j < k; j++) {
//			if ([edges containsIndex:i]) {
//				flux = dispersion[j];
//			} else {
//				flux = 0.0;
//			}
//			emigration[i][j] = flux;
//		}
//	}
}

- (void)computeEmigrationFromAttractions
{
	int k = intValue([self finalInputValueAt:tv1_k]);
//	NSEnumerator *e = [map objectEnumerator];
	NSArray *row;
	int iRow = 0;
	float *states = arrayValue([self outputValue:tv1_innerstates]);
	int j1, j2, j3, nRows = [map count], nCols = [[map objectAtIndex:0] count];
	for (j1 = 0; j1 < nRows; j1++) {
		row = [map objectAtIndex:j1];
//		NSEnumerator *f = [row objectEnumerator];
		HMLevel *model;
		int iCol = 0, i;
		float xAttraction = 0, yAttraction = 0;
		for (j2 = 0; j2 < nCols; j2++) {
			model = [row objectAtIndex:j2];
			NSArray *flatModel = [model flattened];
			float x = iCol - position.x;
			float y = iRow - position.y;
			if ((x == 0) && (y == 0)) {
				iCol++;
				continue;
			}
			float x2 = x * x, y2 = y * y;
			float distance = x2 + y2;
			if (distance < 2) {
				distance = 2;
			}
			float distanceFactor = distance;
//			NSEnumerator *g = [model objectEnumerator];
			int nParts = [flatModel count];
			HMPart *part;
			for(j3 = 0; j3 < nParts; j3++) {
				part = [flatModel objectAtIndex:j3];
				float partAttraction = [part attraction] / (distanceFactor);
				if (partAttraction < 0.001f) {
					continue;
				}
				xAttraction = yAttraction = 0;
				if (x2 > y2) {
					xAttraction = partAttraction;
				}
				else if (y2 > x2 ){
					yAttraction = partAttraction;
				} else {
					long int q = random();
					if ((q % 2) == 0) {
						xAttraction = partAttraction;
					}
					else {
						yAttraction = partAttraction;
					}
				}

				Direction xDirection, yDirection;
				float *tmp = 0;
				if (xAttraction > 0) {
					if (x > 0) {
						xDirection = east;
					}
					else {
						xDirection = west;
					}
					tmp = emigration[xDirection];
					for (i = 0; i < k; i++) {
						tmp[i] += states[i] * xAttraction;
					}
				} else if (yAttraction > 0) {
					if (y > 0) {
						yDirection = north;
					}
					else {
						yDirection = south;
					}
					tmp = emigration[yDirection];
					for (i = 0; i < k; i++) {
						tmp[i] += states[i] * yAttraction;
						
					}			
				}
			}
			iCol++;
		}
		iRow++;
	}
}

- (float*)emigrationInDirection:(Direction) direction
{
	return emigration[direction];
}

- (float*)imigrationFromDirection:(Direction) direction
{
	return imigration[direction];
}

- (void)setImigration:(float*)anImigration fromDirection:(Direction)direction
{
	imigration[direction] = anImigration;
}

//=========================================================== 
//  position 
//=========================================================== 
- (NSPoint)position
{
    return position;
}
- (void)setPosition:(NSPoint)aPosition
{
    position = aPosition;
}


@end
