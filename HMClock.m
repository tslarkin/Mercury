//
//  HMClock.m
//  Hernix
//
//  Created by Timothy Larkin on 12/1/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMOutput.h"
#import "HMClock.h"
#import "AppController.h"
#import "HMHTL.h"
#if __linux__
double round(double x);
#endif

extern HMOutput *gTime;

NSDate *gCurrentDate;

@implementation HMClock

- (void)startWithPath:(NSString*)path andInferiors:(NSArray*)inferiors;
{
    NSTimeInterval referenceTime;
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
	NSDate *startDate = [appController startDay];
	float setting = [currentCalendar  ordinalityOfUnit:NSCalendarUnitDay
                                               inUnit:NSCalendarUnitYear
                                              forDate:startDate];
	referenceTime = [startDate timeIntervalSinceReferenceDate];
	gCurrentDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:referenceTime];
	int delta = [self step] * 86400;
	int stepsPerDay = round(1.0 / [self step]);
	int end = [self stop] * stepsPerDay;
	int reportStep = [appController reportStep];
	int i = 0;
	[appController initializeModel];
	NSString *coordinates = nil;
	Value *julianday, *dt, *time;
	julianday = [HMHTL sharedVariableWithName:@"julianday"]->value;
	dt = [HMHTL sharedVariableWithName:@"dt"]->value;
	time = [HMHTL sharedVariableWithName:@"time"]->value;
	
	do {
		setFloatValue([gTime value], referenceTime);
		setFloatValue(time, setting);
		setFloatValue(dt, [appController dt]);
        setFloatValue(julianday, [currentCalendar  ordinalityOfUnit:NSCalendarUnitDay
                                                             inUnit:NSCalendarUnitYear
                                                            forDate:gCurrentDate]);
		
		if(i % reportStep == 0) {
//			coordinates = [path stringByAppendingFormat:@"%f\t%f", setting,
//						   [gCurrentDate timeIntervalSinceReferenceDate]];
			coordinates = [[NSString alloc] initWithFormat:@"%@%f\t%f", path, setting, referenceTime];
		}
		[appController runOneSimulationStep:i atCoordinates:coordinates];
		// Clang suggests
		[coordinates release];
		coordinates = nil;
		
		setting += [self step];
		referenceTime+= delta;
		[gCurrentDate release];
		gCurrentDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:referenceTime];
		i++;
	} while (i < end);
}

//=========================================================== 
//  appController 
//=========================================================== 
- (AppController *)appController
{
    return appController; 
}
- (void)setAppController:(AppController *)anAppController
{
    if (appController != anAppController) {
        [anAppController retain];
        [appController release];
        appController = anAppController;
    }
}


//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setAppController:nil];
    [super dealloc];
}

@end
