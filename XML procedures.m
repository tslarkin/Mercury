//
//  XML procedures.m
//  Hernix
//
//  Created by Timothy Larkin on 8/8/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#if __APPLE__

#import "XML_procedures.h"
#import "HMLevel.h"
#import "HMOutput.h"
#import "Instantiator.h"
#import "HMStepper.h"
#import "HMClock.h"

@implementation AppController (XML)

- (void)getRunParameters:(NSString*)setupPath
{
	
	NSError *error;
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:setupPath]
															  options:0 
																error:&error];
	if (error) {
		[NSException raise:@"Simulation terminated" 
					format:@"Error opening XML document %@", setupPath];
	}
	
	NSXMLElement *root = [doc rootElement];
	// Clang suggests
	[doc autorelease];
	NSArray *tmp = [root elementsForName:@"ModelPath"];
	if ([tmp count] != 1) {
		[NSException raise:@"Simulation terminated" 
					format:@"Duplicate or missing ModelPath, found %ld entries", (unsigned long)[tmp count]];
	}
	NSXMLElement *modelPath = [tmp objectAtIndex:0];
	NSArray *dictionaries = XMLtoDictionaries([modelPath stringValue]);
	if (!dictionaries) {
		[NSException raise:@"Simulation terminated" 
					format:@"Model XML from \"%@\" failed to produce any dictionaries.", modelPath];
	}
	
    extern BOOL useGCD;
    tmp = [root elementsForName:@"GCD"];
	if ([tmp count] == 1) {
		useGCD = [[[tmp objectAtIndex:0] stringValue] boolValue];
	} else {
        useGCD = NO;
    }

	tmp = [root elementsForName:@"Dimensions"];
	if ([tmp count] != 1) {
		[NSException raise:@"Simulation terminated" 
					format:@"Duplicate or missing dimensions"];
	}
	
	
	NSPoint dimensions = NSPointFromString([[tmp objectAtIndex:0] stringValue]);
	
	[self setSpace:buildMatrix(dictionaries, dimensions.x, dimensions.y)];
	
	tmp = [root elementsForName:@"Dt"];
	if ([tmp count] == 1) {
		[self setDt:[[[tmp objectAtIndex:0] stringValue] doubleValue]];
	}
	
	tmp = [root elementsForName:@"StepsPerDay"];
	if ([tmp count] == 1) {
		[self setDt: 1.0 / [[[tmp objectAtIndex:0] stringValue] doubleValue]];
	}	
	
	tmp = [root elementsForName:@"Initialization"];
	[self doInitializations:tmp];
	
	tmp = [root elementsForName:@"Steppers"];
	[self setSteppers:[self getSteppers:tmp]];
	
	iterations = 0;
	tmp = [root elementsForName:@"Iterations"];
	if ([tmp count] == 1) {
		iterations = [[[tmp objectAtIndex:0] stringValue] intValue];
	}
	
	NSDate *date; // = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:0];
	tmp = [root elementsForName:@"StartDay"];
	if ([tmp count] == 1) {
//        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        NSString *format = [NSDateFormatter dateFormatFromTemplate:@"yyyy-MM-dd HH:mm:ss XX"
                                                                         options:0
                                                                          locale:nil];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = format;
		date = [dateFormatter dateFromString:[[tmp objectAtIndex:0] stringValue]];
        NSAssert(date, @"Couldn't derive date object from \"%@\"", [[tmp objectAtIndex:0] stringValue]);
		[self setStartDay:date];
	}
	
	float runLength = 0;
	tmp = [root elementsForName:@"RunLength"];
	if ([tmp count] == 1) {
		runLength = [[[tmp objectAtIndex:0] stringValue] floatValue];
		iterations = runLength / dt;
	}
    
	HMClock *clock = [[HMClock alloc] initWithStart:0
											   step:dt
											andStop:runLength];
	[clock setAppController:self];
	[clock setName:@"time"];
	[steppers addObject:clock];
	[clock release];
	
	if (([space count] == 1) && ([[space objectAtIndex:0] count] == 1)) {
		NSString *pathName = [self defaultOutputPath];
		[self setupOutputsFromRecordersUsingPath:pathName];
	}
	else {
		tmp = [root elementsForName:@"Output"];
		[self setupOutputsFromXML:tmp];
	}
	
	
					  
//	if((runLength == 0) && (iterations == 0)) {
//		[NSException raise:@"Simulation terminated" 
//					format:@"RunLength or Iterations must be specified."];
//	}
	
	reportStep = 1;
	tmp = [root elementsForName:@"ReportStep"];
	if ([tmp count] == 1) {
		reportStep = [[[tmp objectAtIndex:0] stringValue] intValue];
	}
}

- (void)setupOutputsFromXML:(NSArray*)outputs
{
	NSEnumerator *e = [outputs objectEnumerator];
	NSXMLElement *output;
	FILE *file = nil;
	while(output = [e nextObject]) {
		NSArray *tmp;
		NSString *portName = nil, *partName = nil, *pathName = nil;
		tmp = [output elementsForName:@"PartName"];
		if ([tmp count] == 1) {
			partName = [[tmp objectAtIndex:0] stringValue];
			tmp = [output elementsForName:@"PortName"];
			if ([tmp count] != 1) {
				[NSException raise:@"Simulation terminated" 
							format:@"Missing Port Name in initialization"];
			}
			portName = [[tmp objectAtIndex:0] stringValue];
		} else {
			tmp = [output elementsForName:@"PortPath"];
			if ([tmp count] != 1) {
				[NSException raise:@"Simulation terminated" 
							format:@"Missing Port Path in initialization"];
			}
			pathName = [[tmp lastObject] stringValue];
			if ([pathName characterAtIndex:0] != '/') {
				tmp = [pathName componentsSeparatedByString:@"/"];
				NSAssert([tmp count] == 2, @"Unrecognized output path");
				partName = [tmp objectAtIndex:0];
				portName = [tmp objectAtIndex:1];
				pathName = nil;
			}
		}
				
		tmp = [output elementsForName:@"OutputPathName"];
		if ([tmp count] != 1) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Output Path Name in initialization"];
		}
		
		pathName = [[tmp objectAtIndex:0] stringValue];
		pathName = [pathName stringByExpandingTildeInPath];
		NSError *error = nil;
		[@"" writeToFile:pathName atomically:NO encoding:NSMacOSRomanStringEncoding error:&error];
		if (error) {
			[NSException raise:@"Simulation terminated" 
						format:@"Error opening file: %@", pathName];
		}
		
		const char *cPathName = [pathName cStringUsingEncoding:NSMacOSRomanStringEncoding];
		file = fopen(cPathName, "w");
		if (file == nil) {
			[NSException raise:@"Simulation terminated" 
						format:@"Error %d: Couldn't open file %@", errno, pathName];
		}
		
		if (pathName) {
			[self setOutputFile:file forPath:pathName];
		}
		else {
			[self setOutputFile:file ofPort:portName ofPart:partName];
		}
	}
}

- (NSMutableArray*)getSteppers:(NSArray*)stepperxml
{
	NSMutableArray *someSteppers = [NSMutableArray array];
	NSEnumerator *e = [stepperxml objectEnumerator];
	NSXMLElement *init;
	float start, step, stop;
	while (init = [e nextObject]) {
		NSArray *tmp;
		tmp = [init elementsForName:@"PortPath"];
		if ([tmp count] != 1) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Port Path in initialization"];
		}
		NSString *pathName = [[tmp lastObject] stringValue];
		
		tmp = [init elementsForName:@"Start"];
		if ([tmp count] != 1) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Start value in initialization"];
		}
		start = [[[tmp objectAtIndex:0] stringValue] floatValue];
		
		tmp = [init elementsForName:@"Step"];
		if ([tmp count] != 1) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Step value in initialization"];
		}
		step = [[[tmp objectAtIndex:0] stringValue] floatValue];
		
		tmp = [init elementsForName:@"Stop"];
		if ([tmp count] != 1) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Start value in initialization"];
		}
		stop = [[[tmp objectAtIndex:0] stringValue] floatValue];
			

		HMStepper *stepper = [[HMStepper alloc] initWithStart:start
														 step:step
													  andStop:stop];
		[stepper setName:[pathName lastPathComponent]];
		NSMutableArray *inputs = [NSMutableArray array];
		NSEnumerator *f, *e = [space objectEnumerator];
		NSArray *row;
		HMLevel *model;
		while (row = [e nextObject]) {
			f = [row objectEnumerator];
			while (model = [f nextObject]) {
				pathName = [pathName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /"]];
				pathName = [@"Model/" stringByAppendingString:pathName];
				NSArray *pathComponents = [pathName componentsSeparatedByString:@"/"];
				HMPort *port = [model recursiveSearchOnPath:pathComponents
												  forPortIn:@"inputs"];
				if (!port) {
					[NSException raise:@"Simulation terminated" 
								format:@"Couldn't find stepper port \"%@\"", pathName];
				}
				[inputs addObject:port];
			}
		}
		[stepper setInputs:inputs];
		[someSteppers addObject:stepper];
		[stepper release];
	}
	
	return someSteppers;
}

- (void)doInitializations:(NSArray*)inits
{
	NSEnumerator *e = [inits objectEnumerator];
	NSXMLElement *init;
	BOOL oldStyle;
	while(init = [e nextObject]) {
		NSArray *tmp;
		
		tmp = [init elementsForName:@"Coordinates"];
		if ([tmp count] != 1) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Coordinates in initialization"];
		}
		NSPoint coordinates = NSPointFromString([[tmp objectAtIndex:0] stringValue]);
		
		NSString *portName, *partName, *pathName;
		tmp = [init elementsForName:@"PartName"];
		if ([tmp count] == 1) {
			oldStyle = YES;
			partName = [[tmp objectAtIndex:0] stringValue];
			tmp = [init elementsForName:@"PortName"];
			if ([tmp count] != 1) {
				[NSException raise:@"Simulation terminated" 
							format:@"Missing Port Name in initialization"];
			}
			portName = [[tmp objectAtIndex:0] stringValue];
		} else {
			oldStyle = NO;
			tmp = [init elementsForName:@"PortPath"];
			if ([tmp count] != 1) {
				[NSException raise:@"Simulation terminated" 
							format:@"Missing Port Path in initialization"];
			}
			pathName = [[tmp lastObject] stringValue];
		}
				
		tmp = [init elementsForName:@"Value"];
		if ([tmp count] != 1) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Value in initialization"];
		}
		NSString *value = [[tmp objectAtIndex:0] stringValue];
		HMLevel *model = [[space objectAtIndex:coordinates.y] objectAtIndex:coordinates.x];
		
		if (oldStyle) {
			HMPart *part = [model partWithName:partName];
			[part setInitialValue:value forPort:portName];
		} else {
			pathName = [pathName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /"]];
			pathName = [@"Model/" stringByAppendingString:pathName];
			NSArray *pathComponents = [pathName componentsSeparatedByString:@"/"];
			HMPort *port = [model recursiveSearchOnPath:pathComponents
											  forPortIn:@"inputs"];
			if (!port) {
				[NSException raise:@"Simulation terminated" 
							format:@"Couldn't find output port \"%@\"", pathName];
			}
			[port setStringvalue:value];
		}
	}
}

@end

#endif
