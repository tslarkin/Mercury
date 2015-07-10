//
//  HMExpression.h
//  Hernix
//
//  Created by Timothy Larkin on 3/26/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "cell.h"
#import "error.h"
#import "exec.h"
#import "HMPart.h"

class TSymtab;
class TSymtabNode;

@interface HMExpression : HMPart {
  TExecutor *mExec;
  TSymtab**mvpSymtabs;
  TSymtabNode *pProgramId;
  Cell *mTimeCell, **mBOS, *mDTCell, *mJulianCell;
  long mNSymtabs;
  NSArray *inputNames;
  NSArray *outputNames;
  NSMutableArray *inputCells;
  NSMutableArray *outputCells;
  NSString *programstring;
  NSString *inputList;
  NSString *outputList;
}

- (NSMutableArray*) getSymbolList:(NSString*)text;
- (void) cleanup;
- (void) initialize;
- (void) updateRates;
- (NSArray *)outputNames;
- (void)setOutputNames:(NSArray *)anOutputNames;

- (NSArray *)inputNames;
- (void)setInputNames:(NSArray *)anInputNames;
- (NSArray *)outputNames;
- (void)setOutputNames:(NSArray *)anOutputNames;

- (NSString *)inputList;
- (void)setInputList:(NSString *)anInputList;
- (NSString *)outputList;
- (void)setOutputList:(NSString *)anOutputList;

- (NSMutableArray *)inputCells;
- (void)setInputCells:(NSMutableArray *)anInputCells;

- (NSMutableArray *)outputCells;
- (void)setOutputCells:(NSMutableArray *)anOutputCells;

- (NSString *)programstring;
- (void)setProgramstring:(NSString *)aProgramstring;


//- (void) setProgramText:(NSString*)text 
//		  withInputList:(NSString*)inList
//		  andOutputList:(NSString*)outList;
//- (NSString*)programText;
//- (NSString*)inputList;
//- (NSString*)outputList;

@end
