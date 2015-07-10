//
//  HMInputSplitter.m
//  Hernix
//
//  Created by Timothy Larkin on 7/20/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMInputSplitter.h"
#import "Value.h"

@implementation HMInputSplitter

-(void)updateRates
{
	Value *input = [self finalInputValueAt:0];
	copyValue([self outputValue:0], input);
}

- (void)initialize
{
	[super initialize];
	[self updateRates];
}

@end
