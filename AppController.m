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

float dT;
BOOL useGCD;
extern HMOutput *gTime;
NSDictionary *gCellListDict = nil;

@implementation AppController

-(id)init
{
	[super init];
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
- (NSArray *)space
{
    return space; 
}
- (void)setSpace:(NSArray *)aSpace
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

- (void)setOutputFile:(FILE*)file forPath:(NSString*)path;
{
	[self addOpenFile:[NSValue valueWithPointer:file]];
	NSMutableArray *ports = [NSMutableArray array];
	[writers addObject:ports];
	NSEnumerator *e = [space objectEnumerator], *f;
	HMLevel *level;
	NSArray *tmp;
	HMPort *port;
	while (tmp = [e nextObject]) {
		f = [tmp objectEnumerator];
		while(level = [f nextObject]) {
			path = [path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /"]];
			path = [@"Model/" stringByAppendingString:path];
			NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
			port = [level recursiveSearchOnPath:pathComponents
											  forPortIn:@"outputs"];
			if (!port) {
				[NSException raise:@"Simulation terminated" 
							format:@"Couldn't find output port [%@]", path];
			}
			[ports addObject:port];
		}
	}
}

- (void)setOutputFile:(FILE*)file ofPort:(NSString*)portName ofPart:(NSString*)partName
{
	
	[self addOpenFile:[NSValue valueWithPointer:file]];
	NSMutableArray *ports = [NSMutableArray array];
	[writers addObject:ports];
	NSEnumerator *e = [space objectEnumerator], *f;
	HMLevel *level;
	NSArray *tmp;
	HMPort *port;
	while (tmp = [e nextObject]) {
		f = [tmp objectEnumerator];
		while(level = [f nextObject]) {
			port = [level portWithName:portName ofPart:partName];
			if (port) {
				[ports addObject:port];
			}
		}
	}
}

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
	HMLevel *model = [[space lastObject] lastObject];
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
	NSString *pathName = [NSString stringWithFormat:@"%@/Mercury.txt", temporaryDirectory];
	NSLog(@"Writing output to \"%@\"", pathName);
	return pathName;
}

- (void)awakeModel
{
	int m, n;
	int end1 = [space count], end2 = [[space objectAtIndex:0] count];
	NSArray *row;
	HMLevel *model;
	for (m = 0; m < end1; m++) {
		row = [space objectAtIndex:m];
		for (n = 0; n < end2; n++) {
			model = [row objectAtIndex:n];
			[model awake];
		}
	}
}

-(void)establishStartDate
{
    NSTimeInterval realStartDate = [self.startDay timeIntervalSinceReferenceDate];
    for (NSArray *row in space) {
        for (HMLevel *model in row) {
            realStartDate = [model findLatestStartTime:realStartDate];
        }
    }
    self.startDay = [NSDate dateWithTimeIntervalSinceReferenceDate:realStartDate];
}

- (void)initializeModel
{
	int m, n;
	int end1 = [space count], end2 = [[space objectAtIndex:0] count];
	NSArray *row;
	HMLevel *model;
	for (m = 0; m < end1; m++) {
		row = [space objectAtIndex:m];
		for (n = 0; n < end2; n++) {
			model = [row objectAtIndex:n];
			[model initialize];
			[model setMap:space];
		}
	}
	wireMatrix(space);	
}

-(void)runOneSimulationStep:(int)i  atCoordinates:(NSString*)coordinates
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSArray *row;
	HMLevel *model;
	HMPort *port;
	int m, n;
	int end1 = [space count], end2 = [[space objectAtIndex:0] count];
	
	for (m = 0; m < end1; m++) {
		row = [space objectAtIndex:m];
		for (n = 0; n < end2; n++) {
			model = [row objectAtIndex:n];
			[model updateRates];
			//				[model computeEmigrationFromAttractions];
		}
	}
	
	if ((i % reportStep) == 0) {
		int end1 = [writers count];
		for (m = 0; m < end1; m++) {
			row = [writers objectAtIndex:m];
			NSValue *value = [openFiles objectAtIndex:m];
			FILE *file = [value pointerValue];
			const char *s = [coordinates cStringUsingEncoding:NSMacOSRomanStringEncoding];
			int end2 = [row count];
			fprintf(file, "%s", s);
			for (n = 0; n < end2; n++) {
				port = [row objectAtIndex:n];
				fprintf(file, "\t");
				[port recordValue:file];
			}
			
			fprintf(file, " \n");		
		}
		
	}
	
	struct timeval tv1,tv2;
	
	gettimeofday(&tv1, 0);
	for (m = 0; m < end1; m++) {
			row = [space objectAtIndex:m];
			for (n = 0; n < end2; n++) {
				model = [row objectAtIndex:n];
				[model updateStates];
			}
		}
	gettimeofday(&tv2,0);
	long diff = ((tv2.tv_sec - tv1.tv_sec) * 1000000 + (tv2.tv_usec - tv1.tv_usec));
//	NSAssert(diff >= 0, @"Negative time interval");
	time += diff;
	[pool release];

}


- (void)runSimulation:(NSString*)setupPath
{
	
#if __APPLE__
	@try {
#endif

#if __linux__
	NS_DURING
#endif
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
	
		printf("%d microseconds\n", time);
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
