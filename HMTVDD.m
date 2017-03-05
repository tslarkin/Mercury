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
#import "Instantiator.h"

long random(void);

// This enum indexes the ports of the input list.
enum{tv1_ratein, tv1_k, tv1_lossrate,tv1_initialstate,tv1_delaytime, tv1_dispersion,
		tv1_inseep, tv1_outseepcoef};

// This enum indexes the ports of the output list.
enum{tv1_rateout,tv1_store,tv1_innerstates,tv1_innerrates,
	   tv1_translatedout,tv1_lossrates, tv1_outputsize};

// dT is the size (in days) of the simulation time step.
extern float dT;
// The current time in seconds since the reference date.
extern HMOutput *gTime;


@implementation HMTVDD
@synthesize position;
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
        edges = anEdges.mutableCopy;
    }
}

// Free the memory allocated by calloc.
- (void)freeMemory
{
	if (dispersion) {
		free(dispersion);
	}
	int i;
    // Free emigration and the memory blocks it points to.
	if (emigration) {
		for (i = 0; i < nDirections; i++) {
			free(emigration[i]);
		}
		free(emigration);
	}
    // Free immigration, but not the memory blocks it points to,
    // since those are the emigration rates belonging to other TVDDs.
	if (immigration) {
		free(immigration);
	}
    // Free the memory used internally.
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
    // We call initialize every time a simulation is run. Simulations may be run
    // many times in a single call to Mercury because of steppers.
	[self freeMemory];
    
    edges = [NSMutableIndexSet indexSet];

	int k = intValue([self finalInputValueAt:tv1_k]);
	// Sanity check on k.
	if (k <= 0) {
		[NSException raise:@"Simulation terminated" 
					format:@"k for %@ was not greater than zero", [self fullPath]];
	}
	
	// Allocate space for innerStates, innerRates, and lossRates.
	float *tmp = calloc(k, sizeof(float));
	setArrayValue([self outputValue:tv1_innerstates], tmp, k);
	tmp = calloc(k, sizeof(float));
	setArrayValue([self outputValue:tv1_innerrates], tmp, k);
	tmp = calloc(k, sizeof(float));
	setArrayValue([self outputValue:tv1_lossrates], tmp, k);
	tmp = calloc(k, sizeof(float));
    Value *val;
	setArrayValue([self outputValue:tv1_translatedout], tmp, k);
    // I'm not sure why I felt the need to do this check.
    val = [self outputValue:tv1_translatedout];
    NSAssert(val->length1 == k, @"Seep out incorrectly initialized");
    // If the inseep is an internal constant, set it to an array of zeros.
    HMInput *input = [self input:tv1_inseep];
    if (input == [input finalSource]) {
        setZeroArrayValue([self inputValue:tv1_inseep], k);
    }
	setFloatValue([self outputValue:tv1_rateout], 0);
	
	dispersion = calloc(k, sizeof(float));
	immigration = calloc(6, sizeof(float*));
	emigration = calloc(6, sizeof(float*));
	int i;
	for (i = 0; i < 6; i++) {
		float *tmp = calloc(k, sizeof(float));
		emigration[i] = tmp;
	}
	
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
extern int gStep;

// Update states based on the differentials computed during updateRates.
- (void)updateStates
{
    int negativeStateError = 0;
    // Load the values required for the update.
	int k = intValue([self finalInputValueAt:tv1_k]);
	float ratein = floatValue([self finalInputValueAt:tv1_ratein]);
    Value *tmp = [self finalInputValueAt:tv1_inseep];
    NSAssert(tmp->length1 == k, @"Length of seep-in vector (%d) for %@ not equal to k (%d).", tmp->length1, [self fullPath], k);
	float *seepin = arrayValue(tmp);
	float *states = arrayValue([self outputValue:tv1_innerstates]);
	float *rates = arrayValue([self outputValue:tv1_innerrates]);
	float *loss = arrayValue([self outputValue:tv1_lossrates]);
	float *seepout = arrayValue([self outputValue:tv1_translatedout]);
	float store = 0.0;
    float factor;
    // Iterate over the state array, updating each element.
	for (int i = 0; i < k; i++) {
        float immigrating = 0.0, emigrating = 0.0;
        // Sum the total emigration in six directions for this index of the state array.
        // Currently the edges set contains all edges.
        for (int j = 0; j < 6; j++) {
			if ([edges containsIndex:j]) {
				immigrating += immigration[j][i];
			}
			emigrating += emigration[j][i];
		}
        // The negative differerential for state[i] is the sum of the development to state[i+1],
        // plus the background loss, the outseep, and emigration.
        // totalLoss is a rate constant.
        float totalLoss = rates[i] + loss[i] + seepout[i] + emigrating;
        if (totalLoss < 0.000001) {
            totalLoss = 0.0;
        }
        // factor is the total differential, the development from state[i-1], the inseep,
        // and the immigration, minus the totalLoss.
		factor = ratein + seepin[i] + immigrating - totalLoss;
        float s = states[i] + dT * factor;
        
        // Do funky things if an underflow is detected.
        NSAssert(!isnan(states[i]), @"State is NAN");
        if (s < 0.0) {
            // Is the total storage very low? If so, we set every element to zero,
            // and continue without comment.
            float sum = 0.0;
            for (int j = 0; j < k; j++) {
                sum += states[j];
            }
            if (sum < 0.0001) {
                for (int j = 0; j < k; j++) {
                    states[j] = 0.0;
                }
                setFloatValue([self outputValue:tv1_store], 0.0);
                return;
            } else {
                states[i] = 0.0;
                negativeStateError = 1;
            }
            
        } else {
            states[i] = s;
        }
//		NSAssert3 ((states[i] >= -1.0e-4) && states[i] < 1.0e10,
//				   @"Error: Negative or infinite state\nComponent:%@, Value: %f\nTime: %@",
//				   [self path], states[i], stringValue([gTime value]));
		ratein = rates[i];
		store += states[i];
	}
    if (negativeStateError) {
        recordUnderflow(self);
//        NSLog(@"Error: Negative state\nComponent:%@, \nTime: %@",
//              [self path], stringValue([gTime value]));
    }
    // Update the total storage.
	setFloatValue([self outputValue:tv1_store], store);
}

// The next two functions are used by DFSVisit during dependency analysis.
// Return if i is one of the indices in set, which
// are the inputs that have to updated before we can call updateRate.
-(BOOL)isRatePhaseInput:(Fixed)i
{
    static int set[] = {tv1_k, tv1_lossrate,tv1_delaytime,
        tv1_outseepcoef};
	int j;
    for(j = 0;j<4;j++)
        if(i == set[j])return YES;
    return NO;
}

// Return if i is not one of the indices in set, which are the
// outputs that are updated during updateState.
-(BOOL)isRatePhaseOutput:(Fixed)i
{
    static int set[] = {tv1_store,tv1_innerstates};
    int j;
    for(j = 0;j<2;j++)
        if(i == set[j])return NO;
    return YES;
}

// All differentials are computed here during the updateRates phase.
// All rates in the model are updated before any states are updated.
- (void)updateRates
{
    // Load the values needed for updating from the output ports.
	int k = intValue([self finalInputValueAt:tv1_k]);
	int i;
	float *states = arrayValue([self outputValue:tv1_innerstates]);
	float *rates = arrayValue([self outputValue:tv1_innerrates]);
	float *loss = arrayValue([self outputValue:tv1_lossrates]);
    // Check that the value of tv1_translatedout is the proper length.
    Value *val = [self outputValue:tv1_translatedout];
    NSAssert(val->length1 == k, @"Wrong size for seep out vector, should be %d, really is %d", k, val->length1);
    // If it is, then get the seepout vector.
	float *seepout = arrayValue([self outputValue:tv1_translatedout]);
	float delaytime = floatValue([self finalInputValueAt:tv1_delaytime]);
	if (!(delaytime > 0)) {
		HMPart *source = [[[self input:tv1_delaytime] finalSource] part];
		NSLog(@"Error: Non-positive delaytime\nIn:%@\nFrom:%@\nValue: %f\nTime: %f", 
				   [self path], [source path], delaytime, floatValue([gTime value]));
	}
    // Compute development rate (dr); load loss rate (lr), and seepout rate (sr)
	float dr = k / delaytime;
	float lr = floatValue([self finalInputValueAt:tv1_lossrate]);
	float sr = floatValue([self finalInputValueAt:tv1_outseepcoef]);
	float state;
    // Update the state array.
	for (i = 0; i < k; i++) {
		state = states[i];
        // compute differential for development and loss rates.
		rates[i] = state * dr;
		loss[i] = state * lr;
        NSAssert(!isnan(loss[i]), @"Loss is NAN in %@.", [self fullPath]);
        // compute differential for loss rate.
		seepout[i] = state * sr;
        NSAssert(!isnan(seepout[i]), @"Seepout is NAN in %@.", [self fullPath]);

		NSAssert3 ((state >= -1.0e-10) && state < 1.0e10,
				   @"Error: Negative or infinite state\nComponent:%@, Value: %f\nTime: %@", 
				   [self path], state, stringValue([gTime value]));
	}
    // The rate out is the last element of the development rate array.
	setFloatValue([self outputValue:tv1_rateout], rates[k - 1]);
	
    // In previous versions of Hermes, tv1_dispersion was a float. It is now an
    // array of six value. Fortunately, no one used the old style dispersion, so
    // we only need to deal with the case that it is a zero float or an array.
    // Initialize the dispersionRate array to null.
    float *dispersionRate = 0;
    val = [self finalInputValueAt:tv1_dispersion];
    // Consider tv1_dispersion. If it is a array of length 6, then use it as
    // dispersionRate. Otherwise dispersionRate is null.
    if (val->utype == arraytype) {
        if (val->length1 != 6) {
            [NSException raise:@"Simulation terminated"
                        format:@"Movement vector for %@ not of length 6.", self.fullPath];
        }
        dispersionRate = arrayValue(val);
    }
    // Compute the dispersions in each of the six directions.
	for(int i = 0; i < 6; i++) {
        float rate = dispersionRate == 0 ? 0.0 : dispersionRate[i];
        // Use rate (a rate constant) to compute k differentials for edge i.
		for (int j = 0; j < k; j++) {
            float flux;
            flux = states[j] * rate;
//			if ([edges containsIndex:i]) {
//				flux = states[j] * rate;
//			} else {
//				flux = 0.0;
//			}
			emigration[i][j] = flux;
		}
	}
}

// A function that could be use for attractions, if there were any, which currently
// there are not.
/*
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
*/

- (float*)emigrationInDirection:(NSUInteger) direction
{
	return emigration[direction];
}

- (float*)imigrationFromDirection:(NSUInteger) direction
{
	return immigration[direction];
}

- (void)setImmigration:(float*)anImigration fromDirection:(NSUInteger)direction
{
    [edges addIndex: direction];
	immigration[direction] = anImigration;
}



@end
