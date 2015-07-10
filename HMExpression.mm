//
//  HMExpression.m
//  Hernix
//
//  Created by Timothy Larkin on 3/26/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "HMExpression.h"

#import <string.h>
#import "fiercommon.h" 
#import "Tparser.h"
#import "Value.h"

#import "HMOutput.h"


@implementation HMExpression

extern ErrorInfo *gErrors;
extern int currentLineNumber;
extern TSymtab *globalSymtab;

/*
	Deletion & Destruction:
		deleting TSymtab: 
			1) deletes the vector of pointers to the symbol table nodes.
			2) deletes the root TSymtabNode. By recursion, this deletes
				all the other symbol table nodes.
		deleting TSymtabNode:
			1) deletes the left and right branches.
			2) deletes the name.
			3) deletes the defn structure.
		deleting defn structure:
			1) if this is a rcDeclared procedure, then deletes the
				procedure's symbol table.
			2) deletes the icode object.
*/

- (id)init
{
  if (self = [super init]) {
	pProgramId = (TSymtabNode*)nil;
	mvpSymtabs = (TSymtab**)nil;
	mTimeCell = [[Cell alloc] init];
	mDTCell = [[Cell alloc] init];
	mJulianCell = [[Cell alloc] init];
	mNSymtabs = 0;
	inputNames = outputNames = nil;
	inputList = [[NSString alloc] init];
	outputList = [[NSString alloc] init];
  }
  return self;
}

///=========================================================== 
//  programstring 
//=========================================================== 
- (NSString *)programstring
{
    return programstring; 
}
- (void)setProgramstring:(NSString *)aProgramstring
{
    if (programstring != aProgramstring) {
		NSMutableString *tmp = [NSMutableString stringWithString:aProgramstring];
		[tmp replaceOccurrencesOfString:@"\%gt;" withString:@">"
								options:0 range:NSMakeRange(0, [tmp length])];
		[tmp replaceOccurrencesOfString:@"\%lt;" withString:@"<"
								options:0 range:NSMakeRange(0, [tmp length])];
        [tmp retain];
        [programstring release];
        programstring = tmp;
    }
}

//=========================================================== 
//  inputCells 
//=========================================================== 
- (NSMutableArray *)inputCells
{
    return inputCells; 
}
- (void)setInputCells:(NSMutableArray *)anInputCells
{
    if (inputCells != anInputCells) {
        [anInputCells retain];
        [inputCells release];
        inputCells = anInputCells;
    }
}

//=========================================================== 
//  outputCells 
//=========================================================== 
- (NSMutableArray *)outputCells
{
    return outputCells; 
}
- (void)setOutputCells:(NSMutableArray *)anOutputCells
{
    if (outputCells != anOutputCells) {
        [anOutputCells retain];
        [outputCells release];
        outputCells = anOutputCells;
    }
}

- (void) dealloc;
{
	delete pProgramId;
    [self setProgramstring:nil];
	[self setInputCells:nil];
	[self setOutputCells:nil];
    [self setInputNames:nil];
    [self setOutputNames:nil];
    [self setInputList:nil];
    [self setOutputList:nil];
	[mTimeCell release];
	[mDTCell release];
	[mJulianCell release];
	// for(i = 0; i < mNSymtabs; i++) delete mvpSymtabs[i];
	// delete [] mvpSymtabs;
	delete mExec;
	[super dealloc];
}

- (NSMutableArray*) getSymbolList:(NSString*) theText
{
	NSArray *tmp = [theText componentsSeparatedByString:@","];
	NSMutableArray *tmp2 = [NSMutableArray array];
	NSEnumerator *e = [tmp objectEnumerator];
	NSString *s;
	while (s = [e nextObject]) {
		s = [s lowercaseString];
		[tmp2 addObject:[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	}
	return tmp2;
}


NSMutableArray *updateCellList(NSArray *parameterNames,
					Class cellClass)
{
	NSMutableArray *newCells = [NSMutableArray array];
	Cell *theCell;
	NSString *name;
	NSEnumerator *e = [parameterNames objectEnumerator];
	while (name = [e nextObject]) {
		theCell= [[cellClass alloc] init];
		[theCell setBaseType:kwild];
		[theCell setName:name];
		[newCells addObject:theCell];
	}
	return newCells;
}

- (void) commitChanges
{
	extern int cntSymtabs;

	NSAssert(pProgramId != (TSymtabNode*)nil, @"nil program");
	
	// Flatten the symbol table
	mNSymtabs = cntSymtabs;
	delete mvpSymtabs;
	mvpSymtabs = new TSymtab *[cntSymtabs];
	mvpSymtabs[0] = globalSymtab;
	pProgramId->defn.routine.pSymtab->Convert(mvpSymtabs);
	
	[self setInputCells:updateCellList([self inputNames], [Cell class])];
	[self setOutputCells:updateCellList([self outputNames], [OutputCell class])];
	
}

- (TSymtabNode*) checkSyntax:(NSString*)text 
				  withInputs:(NSString*)theInputs
				  andOutputs:(NSString*)theOutputs;
{
	
	extern int cntSymtabs;
	currentLineNumber = 1;
	currentNestingLevel = 0;
	cntSymtabs = 0;
	TSymtabNode *program;
	
	TSourceBuffer *source = new TSourceBuffer([text cString],
											  [text cStringLength]);
	TParser *pParser = new TParser(source,
								   [self getSymbolList:theOutputs],
								   [self getSymbolList:theInputs]);
	program = pParser->Parse();
	
	delete pParser;
	return program;
}


//=========================================================== 
//  outputNames 
//=========================================================== 
- (NSArray *)outputNames
{
    return outputNames; 
}
- (void)setOutputNames:(NSArray *)anOutputNames
{
    if (outputNames != anOutputNames) {
        [anOutputNames retain];
        [outputNames release];
        outputNames = anOutputNames;
    }
}

//=========================================================== 
//  inputNames 
//=========================================================== 
- (NSArray *)inputNames
{
    return inputNames; 
}
- (void)setInputNames:(NSArray *)anInputNames
{
    if (inputNames != anInputNames) {
        [anInputNames retain];
        [inputNames release];
        inputNames = anInputNames;
    }
}

	
- (void)initialize
{
	[super initialize];
	NSEnumerator *e = [[self inputs] objectEnumerator];
	NSMutableArray *tmp = [NSMutableArray array];
	HMPort *port;
	while (port = [e nextObject]) {
		[tmp addObject:[port name]];
	}
	if ([tmp count] > 0) {
		[self setInputNames:tmp];
		[self setInputList:[inputNames componentsJoinedByString:@","]];
	}
	else {
		[self setInputNames:nil];
		[self setInputList:nil];
	}
	
	e = [[self outputs] objectEnumerator];
	tmp = [NSMutableArray array];
	while (port = [e nextObject]) {
		[tmp addObject:[port name]];
	}
	[self setOutputNames:tmp];
	[self setOutputList:[outputNames componentsJoinedByString:@","]];
	
	Cell *theCell;
	// temporary
	delete pProgramId;
	pProgramId = (TSymtabNode*)nil;
	pProgramId = [self checkSyntax:programstring
						withInputs:inputList
						andOutputs:outputList];
	
	if (pProgramId == (TSymtabNode*)nil) return;
	[self commitChanges];
	
	// Initialize the runtime stack
	delete mExec;
	mExec = new TExecutor;
	TRuntimeStack *theStack = mExec->GetRunStack();
    
	// Push the "global" variables.
	theStack->Push(mTimeCell);
	theStack->Push(mDTCell);
	theStack->Push(mJulianCell);
    
	// Push the stack frame for the expression
	Cell **newFrameBase = theStack->PushFrameHeader(0, 1);
	mBOS = newFrameBase + 1;
    
	// Push the value parameters
	e = [[self inputCells] objectEnumerator];
	while (theCell = [e nextObject]) {
		// the cell copy has a ref count of 1. this is incremented by Push,
		// and then decremented by release.
		theStack->Push(theCell);
		[theCell release];
	}
    
	// Push the var parameters.
	e = [[self outputCells] objectEnumerator];
	while (theCell = [e nextObject]) {
		[theCell setReal:0];
		theStack->Push(theCell);
	}
    
	// Activate the new context.
	theStack->ActivateFrame(newFrameBase);
	mExec->EnterRoutine(pProgramId);
}

- (void) updateRates
{
	extern HMOutput *gTime;
	extern NSCalendarDate *gCurrentDate;
	extern float dT;
	Cell *theCell;
	
	if (pProgramId == (TSymtabNode*)nil) return;
	
	pProgramId->defn.routine.pIcode->Reset();    
	currentNestingLevel= 1;
	
	if (!mTimeCell) {
		[NSException raise:@"Simulation terminated" 
					format:@"mTimeCell is nil"];
	}
	[mDTCell setReal:dT];
	[mTimeCell valueToCell:[gTime value]];
	[mJulianCell setReal:[gCurrentDate dayOfYear]];
	
	// Update the values of the Value parameters.
	// the cell objects were put on the stack by Initialize
	int i, n;
	NSValue *v;
	HMPort *port;
	n = [[self inputCells] count];
	for (i = 0; i < n; i++) {
		theCell = [[self inputCells] objectAtIndex:i];
		v = [[self finalInputValues] objectAtIndex:i];
		[theCell valueToCell:(Value*)[v pointerValue]];
	}
//	NSEnumerator *e = [[self inputCells] objectEnumerator];
//	NSEnumerator *f = [[self finalInputValues] objectEnumerator];
//	while (v = [f nextObject]) {
//		theCell = [e nextObject];
//		[theCell valueToCell:(Value*)[v pointerValue]];
//	}
	
	// Execute the program.
	vpSymtabs = mvpSymtabs;
#if __APPLE__
	@try {
#endif
#if __linux__
		NS_DURING
#endif
		
		mExec->ExecuteCompound();

#if __linux__
		NS_HANDLER
		NSLog(@"%@: %@", [localException name], [localException reason]);
		NS_ENDHANDLER
#endif		
#if __APPLE__
	}
	@catch (NSException *e) {
		NSLog(@"%@ of %@, at time: %f", [[e userInfo] valueForKey:@"detail"],
			  [self fullPath], [gTime value]->u.dval);
		@throw;
	}
	
	@finally {
#endif
	
		n = [[self outputs] count];
		for(i = 0; i < n; i++)  {
		port = [[self outputs] objectAtIndex:i];
		theCell = [[self outputCells] objectAtIndex:i];
		if ([theCell cellType] == kunassigned) {
			NSException *ex = [NSException exceptionWithName:@"Undefined Variable"
													  reason:[NSString stringWithFormat:@"Output \"%@\" is undefined after the evaluation of %@",
																			   [port name], [self fullPath]]
													userInfo:nil];
			[ex raise];
		}
		
		[theCell cellToValue:[port value]];
	}
#if __APPLE__
	}
#endif	
	
}

//=========================================================== 
//  inputList 
//=========================================================== 
- (NSString *)inputList
{
    return inputList; 
}
- (void)setInputList:(NSString *)anInputList
{
    if (inputList != anInputList) {
        [anInputList retain];
        [inputList release];
        inputList = anInputList;
    }
}

//=========================================================== 
//  outputList 
//=========================================================== 
- (NSString *)outputList
{
    return outputList; 
}
- (void)setOutputList:(NSString *)anOutputList
{
    if (outputList != anOutputList) {
        [anOutputList retain];
        [outputList release];
        outputList = anOutputList;
    }
}


- (void)cleanup
{
	if (pProgramId == (TSymtabNode*)nil) return;
	mExec->ExitRoutine(pProgramId);	
}

@end


