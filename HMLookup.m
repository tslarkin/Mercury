//
//  HMLookup.m
//  Hernix
//
//  Created by Timothy Larkin on 4/2/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMLookup.h"

enum extensionType{lk_extrapolate,lk_pin,lk_constant};
enum{lk_belowactionoption,lk_belowactionvalue,lk_aboveactionoption,
	   lk_aboveactionvalue, lk_arg,lk_lookup,lk_inputsize};
enum{lk_output,lk_outputsize};


@implementation HMLookup

- (void)updateStates
{
	
}

- (void)updateRates
{
	float x = floatValue([self finalInputValueAt:lk_arg]);
	float **lookup = lookupValue([self finalInputValueAt:lk_lookup]);
	int size = [self finalInputValueAt:lk_lookup]->length1;
	int size1 = size - 1;
	int size2 = size1 - 1; 
	float minx = lookup[0][0];
	float maxx = lookup[size1][0];
	float y;
	
	if (x == minx) {
		y = lookup[0][1];
	}
	else if (x == maxx) {
		y = lookup[size1][1];
	} else if (x < minx) {
		int belowOption = intValue([self finalInputValueAt:lk_belowactionoption]);
		float belowValue = floatValue([self finalInputValueAt:lk_belowactionvalue]);
		switch (belowOption) {
			case lk_extrapolate:
				y = lookup[0][1] + (minx - x) * (lookup[1][1] - lookup[0][1]) / (lookup[1][0] - minx);
				break;
			case lk_pin:
				y = lookup[0][1];
				break;
			case lk_constant:
				y = belowValue;
			default:
				break;
		}
	} else if (x > maxx) {
		int aboveOption = intValue([self finalInputValueAt:lk_aboveactionoption]);
		float aboveValue = floatValue([self finalInputValueAt:lk_aboveactionvalue]);
		switch (aboveOption) {
			case lk_extrapolate:
				y = lookup[size1][1] + (x - maxx) * (lookup[size1][1] - lookup[size2][1]) / (lookup[size2][0] - maxx);
				break;
			case lk_pin:
				y = lookup[size1][1];
				break;
			case lk_constant:
				y = aboveValue;
			default:
				break;
		}
		
	}
	else {
		int i;
		for (i = 1; i < size; i++) {
			if (x <= lookup[i][0]) {
				break;
			}
		}
		y = lookup[i-1][1] + (x - lookup[i-1][0]) * (lookup[i][1] - lookup[i-1][1]) / (lookup[i][0] - lookup[i-1][0]);
	}
	setFloatValue([self outputValue:lk_output], y);
}

- (void)initialize
{
	[super initialize];
}

@end
