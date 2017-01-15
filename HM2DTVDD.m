//
//  HM2DTVDD.m
//  Hernix
//
//  Created by Timothy Larkin on 2/14/08.
//  Copyright 2008 Abstract Tools. All rights reserved.
//

#import "HM2DTVDD.h"
#import "Value.h"
#import "HMInput.h"
#import "HMOutput.h"
#import "HMLevel.h"
#include <math.h>
#import "Instantiator.h"

enum{
	tv2_delaytime1,
	tv2_delaytime2,
	tv2_k1,
	tv2_k2,
	tv2_lossrate,
	tv2_ratein1,
	tv2_ratein2,
	tv2_initialvalue,
	tv2_inputsize
};

enum{
	tv2_innerrates1,
	tv2_innerrates2,
	tv2_store,
	tv2_lost,
	tv2_rateout1,
	tv2_rateout2,
	tv2_innerstates,
	tv2_totaldead,
	tv2_outputsize
};

extern float dT;
extern HMOutput *gTime;
NSString *stringValue(Value *val);

@implementation HM2DTVDD

- (void)freeMemory
{
	freeValue([self outputValue:tv2_innerstates]);
    freeValue([self outputValue:tv2_innerrates1]);
    freeValue([self outputValue:tv2_innerrates2]);
    freeValue([self outputValue:tv2_lost]);
    freeValue([self outputValue:tv2_rateout1]);
    freeValue([self outputValue:tv2_rateout2]);
}

- (void)dealloc
{
	[self freeMemory];
	[super dealloc];
}

-(void)initialize
{
	[super initialize];
//	[self freeMemory];
	int k1 = floatValue([self finalInputValueAt:tv2_k1]);
	int k2 = floatValue([self finalInputValueAt:tv2_k2]);
	
	if (k1 <= 0) {
		[NSException raise:@"Simulation terminated" 
					format:@"k1 for %@ was not greater than zero", [self fullPath]];
	}
	
	
	if (k2 <= 0) {
		[NSException raise:@"Simulation terminated" 
					format:@"k2 for %@ was not greater than zero", [self fullPath]];
	}
	
	
	setZeroMatrixValue([self outputValue:tv2_innerrates1], k1, k2);
	setZeroMatrixValue([self outputValue:tv2_innerrates2], k1, k2); 
	setZeroMatrixValue([self outputValue:tv2_innerstates], k1, k2);
	setZeroMatrixValue([self outputValue:tv2_lost], k1, k2);
	setZeroArrayValue([self outputValue:tv2_rateout1], k2);
	setZeroArrayValue([self outputValue:tv2_rateout2], k1);
    HMInput *input = [self input:tv2_ratein2];
    if (input == [input finalSource]) {
        setZeroArrayValue([self inputValue:tv2_ratein2], k1);
    }
    input = [self input:tv2_ratein1];
    if (input == [input finalSource]) {
        setZeroArrayValue([self inputValue:tv2_ratein1], k2);
    }
	Value *tmp = [self outputValue:tv2_innerstates];
	matrixValue(tmp)[0][0] = 
		floatValue([self finalInputValueAt:tv2_initialvalue]);
	setFloatValue([self outputValue:tv2_store], floatValue([self finalInputValueAt:tv2_initialvalue]));
	
//	prevTau1 = prevTau2 = NAN;
}

-(void)updateRateInternalWithStates:(float**)state
							  rates:(float**)rate
						coefficient:(float) coef
								 k1:(int) k1
								 k2:(int) k2
{
    float*r,*s;
	int i, j;
    for(i = 0;i<k2;i++){
        r = rate[i];
        s = state[i];
        for(j = 0;j<k1;j++)
            r[j] = s[j]*coef;
    }
}

-(BOOL)isRatePhaseInput:(Fixed)i
{
    static int set[] = {
        tv2_delaytime1,
        tv2_delaytime2,
        tv2_k1,
        tv2_k2,
        tv2_lossrate
    };
	int j;
    for(j = 0;j<5;j++)
        if(i == set[j])return YES;
    return NO;
}

-(BOOL)isRatePhaseOutput:(Fixed)i
{
    static int set[] = {
        tv2_store,
        tv2_innerstates,
    };
    int j;
    for(j = 0;j<2;j++)
        if(i == set[j])return NO;
    return YES;
}


-(void) updateRates
{
    float**innerstates = matrixValue([self outputValue:tv2_innerstates]);
    float**innerrates1 = matrixValue([self outputValue:tv2_innerrates1]);
    float**innerrates2 = matrixValue([self outputValue:tv2_innerrates2]);
    float**lost = matrixValue([self outputValue:tv2_lost]);
    float*rateout1 = arrayValue([self outputValue:tv2_rateout1]);
    float*rateout2 = arrayValue([self outputValue:tv2_rateout2]);
    int k1 = floatValue([self finalInputValueAt:tv2_k1]),
		k2 = floatValue([self finalInputValueAt:tv2_k2]);
    int i;
    float delay = floatValue([self finalInputValueAt:tv2_delaytime1]);
	float coef = k1/delay;
    [self updateRateInternalWithStates:innerstates
                                 rates:innerrates1
                           coefficient:coef
                                    k1:k1
                                    k2:k2];
    delay = floatValue([self finalInputValueAt:tv2_delaytime2]);
    coef = k2/delay;
    [self updateRateInternalWithStates:innerstates
                                 rates:innerrates2
                           coefficient:coef
                                    k1:k1
                                    k2:k2];
	coef = floatValue([self finalInputValueAt:tv2_lossrate]);
    [self updateRateInternalWithStates:innerstates
                                 rates:lost
                           coefficient:coef
                                    k1:k1
                                    k2:k2];
    float sum = 0.0;
    for(i = 0;i<k2;i++) {
        rateout1[i] = innerrates1[i][k1-1];
        sum+= rateout1[i];
    }
    for(i = 0;i<k1;i++){
        rateout2[i] = innerrates2[k2-1][i];
    }
    setFloatValue([self outputValue:tv2_totaldead], sum);
}

/*
-(long)idt:(float) dt
{
    float tau = [[self finalInputValueAt:tv2_delaytime1] float];
    float dTau = isnan(prevTau1)?0.0:fabs(tau-prevTau1)/dt;
    prevTau1 = tau;
    long k = [[self finalInputValueAt:tv2_k1] int];
    float T = (dTau+k)/tau;
    long alpha1 = (long)(1+dt*2*T);
    tau = [[self finalInputValueAt:tv2_delaytime2] float];
    dTau = isnan(prevTau2)?0.0:fabs(tau-prevTau2)/dt;
    prevTau2 = tau;
    k = [[self finalInputValueAt:tv2_k2] int];
    T = (dTau+k)/tau;
    long alpha2 = (long)(1+dt*2*T);
    long alpha = alpha1> alpha2?alpha1:alpha2;
    T = [[self finalInputValueAt:tv2_lossrate] float];
    long alpha3 = (long)(1+dt*2*T);
    if(alpha3> alpha)alpha = alpha3;
    return alpha;
}
*/

-(void)updateStates
{
    bool negativeStateError = false;
    int k2 = floatValue([self finalInputValueAt:tv2_k2]),
    k1 = floatValue([self finalInputValueAt:tv2_k1]);
	float**innerstates = matrixValue([self outputValue:tv2_innerstates]);
	float**innerrates1 = matrixValue([self outputValue:tv2_innerrates1]);
	float**innerrates2 = matrixValue([self outputValue:tv2_innerrates2]);
	float**lost = matrixValue([self outputValue:tv2_lost]);
    Value *tmp = [self finalInputValueAt:tv2_ratein1];
    NSAssert(tmp->length1 == k2, @"Length of ratin1 vector (%d) for %@ not equal to k2 (%d) at time %@.", tmp->length1, [self fullPath], k2, stringValue([gTime value]));
	float*ratein1 = arrayValue(tmp);
    tmp = [self finalInputValueAt:tv2_ratein2];
    NSAssert(tmp->length1 == k1, @"Length of ratin2 vector (%d) for %@ not equal to k1 (%d) at time %@.", tmp->length1, [self fullPath], k1, stringValue([gTime value]));
	float*ratein2 = arrayValue(tmp);
	float*intop;
	float rin2;
	int i,j;
	float sum = 0.0,y;
	unsigned nr1 = [self finalInputValueAt:tv2_ratein1]->length1,
		nr2 = [self finalInputValueAt:tv2_ratein2]->length1;
	for(i = 0,intop = ratein2; i<k2; intop = innerrates2[i],i++)
    {
		if (i < nr1) y = ratein1[i]; else y = 0.0;
		for(j = 0;j<k1;j++){
			if (i == 0) {
				if (j < nr2) rin2 = intop[j]; else rin2 = 0.0;
			}
			else rin2 = intop[j];
			innerstates[i][j]+= dT*(rin2+y-innerrates1[i][j]-innerrates2[i][j]
									-lost[i][j]);
            if (innerstates[i][j] < 0.0) {
                innerstates[i][j] = 0.0;
                negativeStateError = true;
            }
			sum+= innerstates[i][j];
			y = innerrates1[i][j];
		}
    }
    if (negativeStateError) {
        recordUnderflow(self);
    }
	setFloatValue([self outputValue:tv2_store], sum);
}

@end
