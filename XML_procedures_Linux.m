//
//  XML procedures Linux.m
//  Hernix
//
//  Created by Timothy Larkin on 8/8/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#if __linux__

#import "XML_procedures.h"
#import "HMLevel.h"
#import "HMOutput.h"
#import "Instantiator.h"
#import "HMClock.h"
#import "AppController.h"


@implementation AppController (XML)

- (NSMutableArray*)getSteppers:(GSXPathNodeSet*)stepperxml
{
	NSMutableArray *someSteppers = [NSMutableArray array];
	GSXMLNode *init;
	float start, step, stop;
	int i;
	for(i = 0; i < [stepperxml count]; i++) {
		init = [stepperxml nodeAtIndex:i];
		NSMutableDictionary *properties = [NSMutableDictionary dictionary];
		GSXMLNode *child = [init firstChildElement];
		while (child) {
			[properties setValue:[child content] forKey:[child name]];
			child = [child nextElement];
		}
		NSString *value = [properties valueForKey:@"PortPath"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Port Path in Stepper declaration"];
		}
		NSString *pathName = value;
		
		value = [properties valueForKey:@"Start"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Start value in Stepper declaration"];
		}
		start = [value floatValue];
		
		value = [properties valueForKey:@"Step"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Step value in Stepper declaration"];
		}
		step = [value floatValue];
		
		value = [properties valueForKey:@"Stop"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Start value in Stepper declaration"];
		}
		stop = [value floatValue];
		
		
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
								format:[NSString stringWithFormat:@"Couldn't find stepper port \"%@\"", pathName]];
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

- (void)getRunParameters:(NSString*)setupPath
{
  //	NSError *error;
	GSXMLParser *parser = [GSXMLParser parserWithContentsOfFile:setupPath];
	BOOL parsed;
	parsed = [parser parse];
	if (!parsed) {
		[NSException raise:@"Simulation terminated" 
					format:@"Error opening XML document %@", setupPath];
	}
	
	GSXMLDocument *d = [parser document];
	//	GSXMLNode *root = [d root];
	GSXPathContext *c = [[GSXPathContext alloc] initWithDocument:d];
	
	GSXPathNodeSet *tmp = (GSXPathNodeSet *)[c evaluateExpression:@"ModelPath"];
	if ([tmp count] != 1) {
		[NSException raise:@"Simulation terminated" 
					format:@"Duplicate or missing ModelPath, found %d entries", [tmp count]];
	}
	GSXMLNode *modelPath = [tmp nodeAtIndex:0];
	NSArray *dictionaries = XMLtoDictionaries([modelPath content]);
	
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"Dimensions"];
	if ([tmp count] != 1) {
		[NSException raise:@"Simulation terminated" 
					format:@"Duplicate or missing dimensions"];
	}
	
	NSPoint dimensions = NSPointFromString([[tmp nodeAtIndex:0] content]);
	
	[self setSpace:buildMatrix(dictionaries, dimensions.x, dimensions.y)];
	
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"Dt"];
	if ([tmp count] == 1) {
		[self setDt:[[[tmp nodeAtIndex:0] content] doubleValue]];
	}
	
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"StepsPerDay"];
	if ([tmp count] == 1) {
		[self setDt: 1.0 / [[[tmp nodeAtIndex:0] content] doubleValue]];
	}
	
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"Steppers"];
	[self setSteppers:[self getSteppers:tmp]];
	
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"Initialization"];
	[self doInitializations:tmp];

// Isn't this redundant with code after setting clocks?
//	if (([space count] == 1) && ([[space objectAtIndex:0] count] == 1)) {
//		[self setupOutputsFromRecorders];
//	}
//	else {
//		tmp = (GSXPathNodeSet *)[c evaluateExpression:@"Output"];
//		[self setupOutputsFromXML:tmp];
//	}
//		
	iterations = 0;
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"Iterations"];
	if ([tmp count] == 1) {
		iterations = [[[tmp nodeAtIndex:0] content] intValue];
	}
	
	NSCalendarDate *date = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:0];
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"StartDay"];
	if ([tmp count] == 1) {
		date = [NSCalendarDate dateWithString:[[tmp nodeAtIndex:0] content]];
		[self setStartDay:date];
	}
	
	float runLength = 0;
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"RunLength"];
	if ([tmp count] == 1) {
		runLength = [[[tmp nodeAtIndex:0] content] floatValue];
		iterations = runLength / dt;
	}
	
	if((runLength == 0) && (iterations == 0)) {
		[NSException raise:@"Simulation terminated" 
					format:@"RunLength or Iterations must be specified."];
	}
	
	HMClock *clock = [[HMClock alloc] initWithStart:0
											   step:dt
											andStop:runLength];
	[clock setAppController:self];
	[clock setName:@"time"];
	[steppers addObject:clock];
	[clock release];
	
	if (([space count] == 1) && ([[space objectAtIndex:0] count] == 1)) {
		NSString *pathName;
		tmp = (GSXPathNodeSet *)[c evaluateExpression:@"OutputPath"];
		if ([tmp count] == 1) {
			pathName = [[[tmp nodeAtIndex:0] content] stringByExpandingTildeInPath];
		} else {
			pathName = [self defaultOutputPath];
		}
		
		[self setupOutputsFromRecordersUsingPath:pathName];
	}
	else {
		tmp = (GSXPathNodeSet *)[c evaluateExpression:@"Output"];
		[self setupOutputsFromXML:tmp];
	}
	
	reportStep = 1;
	tmp = (GSXPathNodeSet *)[c evaluateExpression:@"ReportStep"];
	if ([tmp count] == 1) {
		reportStep = [[[tmp nodeAtIndex:0] content] intValue];
	}	
}

- (void)setupOutputsFromXML:(GSXPathNodeSet*)outputs
{
	GSXMLNode *output;
	FILE *file = 0;
	int i;
	for(i = 0; i < [outputs count]; i++) {
		output = [outputs nodeAtIndex:i];
		NSMutableDictionary *properties = [NSMutableDictionary dictionary];
		GSXMLNode *child = [output firstChildElement];
		while (child) {
			[properties setValue:[child content] forKey:[child name]];
			child = [child nextElement];
		}
		NSString *value = [properties valueForKey:@"PartName"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Part Name in initialization"];
		}
		NSString *partName = value;
		
		value = [properties valueForKey:@"PortName"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Port Name in initialization"];
		}
		NSString *portName = value;
		
		value = [properties valueForKey:@"OutputPathName"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Output Path Name in initialization"];
		}
		
		NSString *pathName = value;
		pathName = [pathName stringByExpandingTildeInPath];
		BOOL success = [@"" writeToFile:pathName atomically:NO];
		if (!success) {
			[NSException raise:@"Simulation terminated" 
						format:@"Error opening file: %@", pathName];
		}
		
		const char *cPathName = [pathName cStringUsingEncoding:NSMacOSRomanStringEncoding];
		file = fopen(cPathName, "w");
		if (file == 0) {
			[NSException raise:@"Simulation terminated" 
						format:@"Error %d: Couldn't open file %@", errno, pathName];
		}
		[self setOutputFile:file ofPort:portName ofPart:partName];
	}
}

- (void)doInitializations:(GSXPathNodeSet*)inits
{
	GSXMLNode *init;
	int i;
	for(i = 0; i < [inits count]; i++) {
		init = [inits nodeAtIndex:i];
		NSMutableDictionary *properties = [NSMutableDictionary dictionary];
		GSXMLNode *child = [init firstChildElement];
		while (child) {
			[properties setValue:[child content] forKey:[child name]];
			child = [child nextElement];
		}
		
		NSString *value = [properties valueForKey:@"PartName"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Part Name in initialization"];
		}
		NSString *partName = value;
		
		value = [properties valueForKey:@"PortName"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Port Name in initialization"];
		}
		NSString *portName = value;
		
		value = [properties valueForKey:@"Value"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Value in initialization"];
		}
		
		NSString *val = value;
		
		value = [properties valueForKey:@"Coordinates"];
		if (!value) {
			[NSException raise:@"Simulation terminated" 
						format:@"Missing Coordinates in initialization"];
		}
		
		NSPoint coordinates = NSPointFromString(value);
		
		HMLevel *model = [[space objectAtIndex:coordinates.y] objectAtIndex:coordinates.x];
		HMPart *part = [model partWithName:partName];
		[part setInitialValue:val forPort:portName];
	}
}


@end
#endif
