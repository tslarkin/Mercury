//
//  AppController.m
//  Hernix
//
//  Created by Timothy Larkin on 3/2/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "AppController.h"
#import "HMLevel.h"
#import "HMOutput.h"
#import "Instantiator.h"
#import "XML_procedures.h"
#import "HMStepper.h"
#import "HexMap.h"

float dT;
BOOL useGCD;
extern HMOutput *gTime;
NSDictionary *gCellListDict = nil;

@implementation AppController

-(id)init
{
	self = [super init];
	[self setDt:0.1];
	[self setWriters:[NSMutableArray array]];
	[self setOpenFiles:[NSMutableArray array]];
	gCellListDict = nil;
#if __APPLE__
	NSBundle *bund = [NSBundle mainBundle];
	NSString *cellListPath = [bund pathForResource:@"Parts" 
											ofType: @"plist"];
	gCellListDict = [NSDictionary dictionaryWithContentsOfFile:cellListPath];
	[gCellListDict retain];
#endif
	return self;
}

- (int)reportStep
{
	return reportStep;
}

//=========================================================== 
//  startDay 
//=========================================================== 
- (NSDate*)startDay
{
    return startDay;
}
- (void)setStartDay:(NSDate*)aStartDay
{
    startDay = aStartDay;
}


//=========================================================== 
//  dt 
//=========================================================== 
- (double)dt
{
    return dt;
}
- (void)setDt:(double)aDt
{
    dt = aDt;
	dT = dt;
}

//===========================================================
//  space 
//=========================================================== 
- (NSDictionary *)space
{
    return space; 
}
- (void)setSpace:(NSDictionary *)aSpace
{
    if (space != aSpace) {
        [aSpace retain];
        [space release];
        space = aSpace;
    }
}


//=========================================================== 
//  steppers 
//=========================================================== 
- (NSMutableArray *)steppers
{
    return steppers; 
}
- (void)setSteppers:(NSMutableArray *)aSteppers
{
    if (steppers != aSteppers) {
        [aSteppers retain];
        [steppers release];
        steppers = aSteppers;
    }
}


//=========================================================== 
//  writers 
//=========================================================== 
- (NSMutableArray *)writers
{
    return writers; 
}
- (void)setWriters:(NSMutableArray *)aWriters
{
    if (writers != aWriters) {
        [aWriters retain];
        [writers release];
        writers = aWriters;
    }
}

//=========================================================== 
//  openFiles 
//=========================================================== 
- (NSMutableArray *)openFiles
{
    return openFiles; 
}
- (void)setOpenFiles:(NSMutableArray *)anOpenFiles
{
    if (openFiles != anOpenFiles) {
        [anOpenFiles retain];
        [openFiles release];
        openFiles = anOpenFiles;
    }
}

- (void)addOpenFile:(id)anOpenFile
{
    [[self openFiles] addObject:anOpenFile];
}
- (void)removeOpenFile:(id)anOpenFile
{
    [[self openFiles] removeObject:anOpenFile];
}

// New style outputs are specified by the full path.
- (void)setOutputFile:(FILE*)file forPath:(NSString*)path;
{
    NSMutableArray *names = [NSMutableArray array];
    for (HMStepper *stepper in steppers) {
        [names addObject:[stepper name]];
    }

    [names addObject:@"date"];
    NSString *stepperList = [names componentsJoinedByString:@"\t"];
    
    fprintf(file, "*%s", [stepperList cStringUsingEncoding:NSMacOSRomanStringEncoding]);
    
    [self addOpenFile:[NSValue valueWithPointer:file]];
	NSMutableArray *ports = [NSMutableArray array];
	[writers addObject:ports];
    path = [path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /"]];
    path = [@"Model/" stringByAppendingString:path];
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    for (HexTile *tile in [space allValues]) {
        HMLevel *level = tile.model;
        HMPort *port = [level recursiveSearchOnPath:pathComponents
                                  forPortIn:@"outputs"];
        if (!port) {
            [NSException raise:@"Simulation terminated"
                        format:@"Couldn't find output port [%@]", path];
        }
        [ports addObject:port];
        fprintf(file, "\t%ld,%ld", (long)tile.hex.q, (long)tile.hex.r);
    }
    fprintf(file, "\n");
}

// Old style outputs are specified by part and port name.
- (void)setOutputFile:(FILE*)file ofPort:(NSString*)portName ofPart:(NSString*)partName
{
	
	[self addOpenFile:[NSValue valueWithPointer:file]];
	NSMutableArray *ports = [NSMutableArray array];
	[writers addObject:ports];
    for (HexTile *tile in [space allValues]) {
        HMLevel *level = tile.model;
        HMPort *port = [level portWithName:portName ofPart:partName];
        if (port) {
            [ports addObject:port];
        }
    }
}

// This is the usual case. The outputs are all written to a single file,
// one column per output. The stepper valuse are inserted in each row between the date
// and the output.
- (void)setupOutputsFromRecordersUsingPath:(NSString*)pathName
{
	FILE *file = 0;
	
#if __APPLE__
	NSError *error = nil;
	//[@"" writeToFile:pathName atomically:NO encoding:NSMacOSRomanStringEncoding error:&error];
	if (error) {
		[NSException raise:@"Simulation terminated" 
					format:@"Error opening file: %@", error];
	}
#endif
#if __linux__
	//[@"" writeToFile:pathName atomically:NO];
#endif
	const char *cPathName = [pathName cStringUsingEncoding:NSMacOSRomanStringEncoding];
	file = fopen(cPathName, "w");
	if (file == 0) {
		[NSException raise:@"Simulation terminated" 
					format:@"Error %d: Couldn't open file %@", errno, pathName];
	}
	
	[self addOpenFile:[NSValue valueWithPointer:file]];
	
	NSMutableArray *recorders = [NSMutableArray array];
	HMLevel *model = ((HexTile*)([space allValues][0])).model;
	if (![model isMemberOfClass:[HMLevel class]]) {
		[NSException raise:@"Simulation terminated" 
					format:@"Model is not an HMLevel"];
	}
	
	[model collectRecorders:recorders];
	[writers addObject:recorders];
	
	NSEnumerator *e = [recorders objectEnumerator];
	HMOutput *output;
	NSMutableArray *names = [NSMutableArray array];
	while (output = [e nextObject]) {
		[names addObject:[output name]];
	}
	
	NSString *nameList = [names componentsJoinedByString:@"\t"];
	
	e = [steppers objectEnumerator];
	HMStepper *stepper;
	names = [NSMutableArray array];
	while (stepper = [e nextObject]) {
		[names addObject:[stepper name]];
	}
	[names addObject:@"date"];
	NSString *stepperList = [names componentsJoinedByString:@"\t"];
	
	fprintf(file, "*%s\t%s\n", [stepperList cStringUsingEncoding:NSMacOSRomanStringEncoding],
			[nameList cStringUsingEncoding:NSMacOSRomanStringEncoding]);	
}


- (NSString*)defaultOutputPath
{
	NSString *temporaryDirectory;
#if __APPLE__
	temporaryDirectory = NSTemporaryDirectory();
#endif
#if __linux__
	temporaryDirectory = @"~/tmp/";
	temporaryDirectory = [temporaryDirectory stringByExpandingTildeInPath];
#endif
	NSString *pathName = [NSString stringWithFormat:@"%@Mercury.txt", temporaryDirectory];
	NSLog(@"Writing output to \"%@\"", pathName);
	return pathName;
}

- (void)awakeModel
{
    for (HexTile *tile in space.allValues) {
        [tile.model awake];
    }
}

-(void)establishStartDate
{
    NSTimeInterval realStartDate = [self.startDay timeIntervalSinceReferenceDate];
    for (HexTile *tile in space.allValues) {
        realStartDate = [tile.model findLatestStartTime:realStartDate];
    }
    self.startDay = [NSDate dateWithTimeIntervalSinceReferenceDate:realStartDate];
}

- (void)initializeModel
{
    for (HexTile *tile in space.allValues) {
        HMLevel *model = tile.model;
        [model initialize];
        [model setMap:space];
    }
	wireMatrix(space);	
}

int gStep;

-(void)runOneSimulationStep:(int)i  atCoordinates:(NSString*)coordinates
{
    gStep = i;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSArray *tiles = space.allValues;
    for (HexTile *tile in tiles) {
        [tile.model updateRates];
        //				[model computeEmigrationFromAttractions];
    }
	
	if ((i % reportStep) == 0) {
        int m = 0;
        for (NSArray *row in writers) {
            NSValue *value = [openFiles objectAtIndex:m++];
            FILE *file = [value pointerValue];
            const char *s = [coordinates cStringUsingEncoding:NSMacOSRomanStringEncoding];
            fprintf(file, "%s", s);
            for (HMPort *port in row) {
                fprintf(file, "\t");
                [port recordValue:file];
            }
            fprintf(file, "\n");
        }
		
	}
	
	struct timeval tv1,tv2;
	
	gettimeofday(&tv1, 0);
    for (HexTile *tile in tiles) {
        [tile.model updateStates];
    }
	gettimeofday(&tv2,0);
	long diff = ((tv2.tv_sec - tv1.tv_sec) * 1000000 + (tv2.tv_usec - tv1.tv_usec));
//	NSAssert(diff >= 0, @"Negative time interval");
	time += diff;
	[pool release];

}

NSString *defaultDirectory;

- (void)runSimulation:(NSString*)setupPath
{
	
#if __APPLE__
	@try {
#endif

#if __linux__
	NS_DURING
#endif
        defaultDirectory = [setupPath stringByDeletingLastPathComponent];
        [defaultDirectory retain];
		[self getRunParameters:setupPath];
		[self awakeModel];
        [self establishStartDate];
		time = 0;
        if (useGCD) {
            NSLog(@"Begin GCD rates and states");
        } else {
            NSLog(@"Begin rates and states");
        }
		
		HMStepper *top = [steppers objectAtIndex:0];
		NSRange range = NSMakeRange(1, [steppers count] - 1);
		[top startWithPath:@"" andInferiors:[steppers subarrayWithRange:range]];
		
#if __linux__
	NS_HANDLER
	NSLog(@"%@: %@", [localException name], [localException reason]);
	NS_ENDHANDLER
#endif		
#if __APPLE__
	}
	@catch (NSException *e) {
		NSLog(@"%@: %@", [e name], [e reason]);
	}
	
	@finally {
#endif
	
		fprintf(stderr, "%d microseconds\n", time);
//		FILE* f = fopen("/Users/tslarkin/Desktop/time.txt", "a");
//		fprintf(f, "%d\n", time);
//		fclose(f);
	NSLog(@"End");
	NSValue *value;
	FILE *file;
	NSEnumerator *e = [[self openFiles] objectEnumerator];
	while (value = [e nextObject]) {
		file = [value pointerValue];
		fclose(file);
	}
#if __APPLE__
	}
#endif
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void)dealloc
{
    [self setSteppers:nil];
    [self setSpace:nil];
	[self setOpenFiles:nil];
	[self setWriters:nil];
    [super dealloc];
}

@end
