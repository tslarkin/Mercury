//
//  AppController.h
//  Hernix
//
//  Created by Timothy Larkin on 3/2/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/time.h>

@class HMPart;

@interface AppController : NSObject {
	double dt;
	NSArray *space;
	NSMutableArray *openFiles;
	NSMutableArray *writers;
	int iterations, reportStep;
	NSDate *startDay;
	NSMutableArray *steppers;
	suseconds_t time;
}

- (int)reportStep;

- (double)dt;
- (void)setDt:(double)aDt;

- (NSDate*)startDay;
- (void)setStartDay:(NSDate*)aStartDay;

- (void)setOutputFile:(FILE*)file ofPort:(NSString*)portName ofPart:(NSString*)partName;
- (void)setOutputFile:(FILE*)file forPath:(NSString*)path;
- (NSString*)defaultOutputPath;
- (void)setupOutputsFromRecordersUsingPath:(NSString*)pathName;

- (NSArray *)space;
- (void)setSpace:(NSArray *)aSpace;

- (NSMutableArray *)openFiles;
- (void)setOpenFiles:(NSMutableArray *)anOpenFiles;
- (void)addOpenFile:(id)anOpenFile;
- (void)removeOpenFile:(id)anOpenFile;

- (void)runSimulation:(NSString*)setupPath;
-(void)runOneSimulationStep:(int)i atCoordinates:(NSString*)coordinates;

- (NSMutableArray *)writers;
- (void)setWriters:(NSMutableArray *)aWriters;

- (NSMutableArray *)steppers;
- (void)setSteppers:(NSMutableArray *)aSteppers;

- (void)initializeModel;
- (void)awakeModel;

@end
