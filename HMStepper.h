//
//  HMStepper.h
//  Hernix
//
//  Created by Timothy Larkin on 12/1/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HMInput;

@interface HMStepper : NSObject {
	float start;
	float step;
	float stop;
	NSArray *inputs;
	NSString *name;
}

- (NSString *)name;
- (void)setName:(NSString *)aName;


- (NSArray *)inputs;
- (void)setInputs:(NSArray *)anInputs;
- (float)start;
- (void)setStart:(float)aStart;
- (float)step;
- (void)setStep:(float)aStep;
- (float)stop;
- (void)setStop:(float)aStop;

- (id)initWithStart:(float)start step:(float)step andStop:(float)stop;
- (void)startWithPath:(NSString*)path andInferiors:(NSArray*)inferiors;

@end
