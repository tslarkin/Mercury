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

@interface AppController : NSObject <NSApplicationDelegate> {
	double dt;
	NSDictionary *space;
    // The next two are parallel arrays. OpenFiles is an array of FILE* values, each
    // for one set of outputs. Writers is an array of arrays of outputs; all the outputs
    // in the second level array write to the same file.
    // In the usual case, openFiles contains one object, the standard output file, and
    // writers contains one object, an array of all the recorders in the model.
    // In the spatial case, each file is the target of a single response variable, and
    // writers contains an array for each response variable containing all the instances of that response
    // variable (one per model).
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

- (NSDictionary *)space;
- (void)setSpace:(NSDictionary *)aSpace;

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
