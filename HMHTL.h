//
//  HMHTL.h
//  Hernix
//
//  Created by Timothy Larkin on 7/26/08.
//  Copyright 2008 Abstract Tools. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMPart.h"
#import "Value.h"

@class HMPort;

typedef enum {
	kPushValue, kApply1, kApply2, kJump, kIf, kPushFunc, kSum, kAssign
} opcodeType;

typedef struct {
	opcodeType opcode;
	unsigned long data;
} instruction, *instructionPtr;

typedef struct {
	char *symbol;
	Value *value;
} symbolTableEntry, *symbolTableEntryPtr;

@interface HMHTL : HMPart {
	  NSString *programrpn;
	  NSString *identifiers;
	  symbolTableEntry *ste;
	  int steLength;
	  instruction **instructions;
	  int instructionCount;
	  NSMutableArray *localVariables;
	  void *stack[32];
	  unsigned char tos;
}

+(void)addSharedVariable:(NSString*)token withValue:(Value*)value;
+(symbolTableEntryPtr)sharedVariableWithName:(NSString*)name;
+(Value*)finalValueForPort:(HMPort*)port;
@end
