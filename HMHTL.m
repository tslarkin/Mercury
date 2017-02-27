//
//  HMHTL.m Hernix
//
//  Created by Timothy Larkin on 7/26/08.
//  Copyright 2008 Abstract Tools. All rights reserved.
//

#import "HMHTL.h"
#import <math.h>

#import <Foundation/Foundation.h>
#include "HMOutput.h"

NSString *stringValue(Value *val);
unsigned int pStore;
const int storeSize = 10000;
Value *store;

float *scanArray(const char *s, char **end, int *n)
{
	NSString *string = [NSString stringWithCString:s
										   encoding:NSMacOSRomanStringEncoding];
	string = [string substringWithRange:NSMakeRange(1, [string length] - 1)];
	NSArray *numbers = [string componentsSeparatedByString:@","];
	*n = [numbers count];
	float *array = nil;
	if (*n > 0) {
		array = malloc(*n * sizeof(float));
		float *p = array;
		for(int i = 0; i < *n; i++) {
			float x = [[numbers objectAtIndex:i] floatValue];
			*p++ = x;
		}
	}
	return array;
}

void readArrayFromString(Value *v, char *s)
{
	int n;
	char *end;
	float *d = scanArray(s, &end, &n);
	setArrayValue(v, d, n);
}

void readMatrixFromString(Value *v, char *s)
{
	char *p = s, *end;
	int n;
	long N = LONG_MAX;
	NSMutableArray *arrays = [NSMutableArray array];
	while (*p) {
		float *z = scanArray(p, &end, &n);
		p = end;
		if (n == 0) {
		}
		else {
			if (n < N) {
				N = n;
			}
			[arrays addObject:[NSValue valueWithPointer:z]];
		}
	}
	float **d = malloc([arrays count] * sizeof(float*));
	NSValue *val;
	for(int i = 0; i < [arrays count]; i++) {
		val = [arrays objectAtIndex:i];
		d[i++] = (float*)[val pointerValue];
	}
	setMatrixValue(v, d, N, [arrays count]);
}

Value *next()
{
	  Value *v = store + pStore;
	  freeValue(v);
	  v->utype = undefined;
	  pStore = (pStore + 1) % storeSize;
	  return v;
}

Value *newFloat()
{
	Value *v = next();
	v->utype = floattype;
	v->u.dval = 0.0;
	return v;
}

Value *newArray(int count)
{
	Value *v = next();
	setZeroArrayValue(v, count);
	return v;
}

Value *newMatrix(int columns, int rows)
{
	Value *v = next();
	setZeroMatrixValue(v, columns, rows);
	return v;
}

double absf(double a)
{
	return fabs(a);
}

double ln(double a)
{
	return log(a);
}

double frac(double a)
{
	return a - floor(a);
}

double mod(double a, double b)
{
	return frac(a / b);
}

double sqr(double a)
{
	return a * a;
}

double add(double a, double b)
{
	
	return a + b;
}

double sub(double a, double b)
{
	
	return a - b;
}

double mult(double a, double b)
{
	return a * b;
}

double divide(double a, double b)
{
	return a / b;
}

double minus(double a)
{
	return -a;
}

double eq(double a, double b)
{
	return a == b;
}

double lt(double a, double b)
{
	return a < b;
}

double gt(double a, double b)
{
	return a > b;
}

double lteq(double a, double b)
{
	return a <= b;
}

double gteq(double a, double b)
{
	return a >= b;
}

double and(double a, double b)
{
	return a && b;
}

double or(double a, double b)
{
	return a || b;
}

double not(double a)
{
	return !a;
}

Value *sum(Value *v)
{
	Value *u = next();
	switch (v->utype) {
		case floattype:
			setFloatValue(u, floatValue(v));
			break;
		case arraytype:
		{
			float x = 0;
			float *d = arrayValue(v);
			for (int i = 0; i < v->length1; i++) {
				x+= d[i];
			}
			setFloatValue(u, x);
		}
			break;
		case matrixtype:
		{
			int rowsv = v->length1, columnsv = v->length2;
            float x = 0;
			float **d = matrixValue(v);
			for (int i = 0; i < columnsv; i++) {
				for (int j = 0; j < rowsv; j++) {
                    float z = d[i][j];
					x += z;
				}
			}
            setFloatValue(u, x);
		}
		default:
			break;
	}
	return u;
}

Value *rsum(Value *v)
{
    Value *u = next();
    switch (v->utype) {
        case floattype:
            setFloatValue(u, floatValue(v));
            break;
        case arraytype:
        {
            float x = 0;
            float *d = arrayValue(v);
            for (int i = 0; i < v->length1; i++) {
                x+= d[i];
            }
            setFloatValue(u, x);
        }
            break;
        case matrixtype:
        {
            int rowsv = v->length1, columnsv = v->length2;
            setZeroArrayValue(u, rowsv);
            float *c = arrayValue(u);
            float **d = matrixValue(v);
            for (int i = 0; i < rowsv; i++) {
                float x = 0;
                for (int j = 0; j < columnsv; j++) {
                    x += d[j][i];
                }
                c[i] = x;
            }
        }
        default:
            break;
    }
    return u;
}

Value *csum(Value *v)
{
    Value *u = next();
    switch (v->utype) {
        case floattype:
            setFloatValue(u, floatValue(v));
            break;
        case arraytype:
        {
            float x = 0;
            float *d = arrayValue(v);
            for (int i = 0; i < v->length1; i++) {
                x+= d[i];
            }
            setFloatValue(u, x);
        }
            break;
        case matrixtype:
        {
            int rowsv = v->length1, columnsv = v->length2;
            setZeroArrayValue(u, columnsv);
            float *c = arrayValue(u);
            float **d = matrixValue(v);
            for (int i = 0; i < columnsv; i++) {
                float x = 0;
                for (int j = 0; j < rowsv; j++) {
                    x += d[i][j];
                }
                c[i] = x;
            }
        }
        default:
            break;
    }
    return u;
}

float *applyArray(double(*func)(double, double), float *a, float *b, int max, int min)
{
	float *d = calloc(max, sizeof(float));
	for (int i = 0; i < min; i++) {
		d[i] = func(a[i], b[i]);
	}
	return d;
}

Value* apply2Array(double(*func)(double, double), Value* a, Value* b)
{
	Value *v = next();
	long min = fminl(columns(a), columns(b));
	long max = fmaxl(columns(a), columns(b));
	float *av = arrayValue(a);
	float *bv = arrayValue(b);
	float *d = applyArray(func, av, bv, max, min);
	setArrayValue(v, d, max);
	return v;
}

Value* apply2Matrix(double(*func)(double, double), Value* a, Value* b)
{
	Value *v = next();
	long minCols = fminl(columns(a), columns(b));
	long maxCols = fmaxl(columns(a), columns(b));
	long minRows = fminl(rows(a), rows(b));
	long maxRows = fmaxl(rows(a), rows(b));
	float **am = matrixValue(a);
	float **bm = matrixValue(b);
	float **d = malloc(maxCols * sizeof(float*));
	for (int i = 0; i < maxCols; i++) {
		if (i < minCols) {
			d[i] = applyArray(func, am[i], bm[i], maxRows, minRows);
		} else {
			d[i] = calloc(maxRows, sizeof(float));
		}
	}
	setMatrixValue(v, d, maxCols, maxRows);
	return v;	
}

Value* apply2(double(*func)(double, double), Value* a, Value* b)
{
        if(!func) return (Value*)nil;
	Value *v = nil, *tmp;
	switch (a->utype) {
		case floattype:
			switch (b->utype) {
				case floattype:
					v = next();
					setFloatValue(v, func(a->u.dval, b->u.dval));
					break;
				case arraytype: {
					v = next();
					int n = columns(b);
					float *d = calloc(n, sizeof(float));
					float *bArray = arrayValue(b);
					float x = floatValue(a);
					for (int i = 0; i < n; i++) {
						d[i] = func(x, bArray[i]);
					}
					setArrayValue(v, d, n);
					break;
				}
				case matrixtype: {
					tmp = next();
					promoteFloat(tmp, floatValue(a),columns(b));
					v = next();
					promoteArray(v, arrayValue(tmp), columns(b), rows(b));
					v = apply2Matrix(func, v, b);
				}
				default:
					break;
					[NSException raise:@"Simulation terminated" 
						format:@"Bad datatype in apply2"];
			}
			break;
		case arraytype:
			switch (b->utype) {
				case floattype:
					v = next();
					promoteFloat(v, floatValue(b), columns(a));
					v = apply2Array(func, a, v);
					break;
				case arraytype: {
					v = apply2Array(func, a, b);
					break;
				}
				case matrixtype: {
					v = next();
					promoteArray(v, arrayValue(a), columns(a), rows(b));
					v = apply2Matrix(func, v, b);
				}
				default:
					[NSException raise:@"Simulation terminated" 
						format:@"Bad datatype in apply2"];

					break;
			}
			break;
		case matrixtype:
			switch (b->utype) {
				case floattype:
					tmp = next();
					promoteFloat(tmp, floatValue(b),columns(a));
					v = next();
					promoteArray(v, arrayValue(tmp), columns(b), rows(a));
					v = apply2Matrix(func, a, v);
					break;
				case arraytype: {
					v = next();
					promoteArray(v, arrayValue(b), columns(b), rows(a));
					v = apply2Matrix(func, a, v);
					break;
				}
				case matrixtype: {
					v = apply2Matrix(func, a, b);
					break;
				}
				default:
					[NSException raise:@"Simulation terminated" 
								format:@"Bad datatype in apply2"];

					break;
			}
			break;
		default:
			[NSException raise:@"Simulation terminated" 
						format:@"Bad datatype in apply2"];

			break;
	}
	return v;
}

Value* apply1(double(*func)(double), Value* a)
{
	Value *v = next();
	float x, z;
	  switch (a->utype) {
			case floattype:
				  x = floatValue(a);
				  z = func(x);
				  setFloatValue(v, z);
				  break;
			case arraytype: {
				  setZeroArrayValue(v, columns(a));
				  float *d = arrayValue(v);
				  float *e = arrayValue(a);
				  for (int i = 0; i < columns(a); i++) {
						*d++ = func(*e++);
				  }
				  break;
			}
			case matrixtype: {
				  setZeroMatrixValue(v, a->length1, a->length2);
				  float **m = matrixValue(v);
				  float **n = matrixValue(a);
				  for (int i = 0; i < a->length2; i++) {
						float *mi = m[i];
						float *ni = n[i];
						for (int j = 0; j < a->length1; j++) {
							  mi[j] = func(ni[j]);
						}
				  }
				  break;
			}
				  
			default:
				  [NSException raise:@"Simulation terminated" 
									format:@"Bad datatype in apply2"];
				  
				  break;
	  }
	return v;
}

BOOL isFalse(Value* a)
{
	float x;
	BOOL zero = YES;
	switch (a->utype) {
		case floattype:
			x = floatValue(a);
			zero = x == 0.0;
			break;
		case arraytype: 
		{
			float *d = arrayValue(a);
			for (int i = 0; i < columns(a); i++) {
				if (*d++ != 0.0) {
					zero = NO;
					break;
				}
			}
		}
			break;
		case matrixtype:
		{
			int nrows = rows(a), ncolumns = columns(a);
			float **aMatrix = matrixValue(a);
			for (int i = 0; i < nrows; i++) {
				float *aArray = aMatrix[i];
				for (int j = 0; j < ncolumns; j++) {
					if (*aArray++ != 0.0) {
						zero = NO;
						break;
					}
				}
				if (!zero) {
					break;
				}
			}
			break;
			
		}
	}
	return zero;
}

instructionPtr makeFloat(symbolTableEntryPtr step)
{
	instructionPtr ip = calloc(1, sizeof(instruction));
	step->value->utype = floattype;
	step->value->u.dval = atof(step->symbol);
	ip->opcode = kPushValue;
	ip->data = (unsigned long)step;
	return ip;
}

instructionPtr makeMatrix(symbolTableEntryPtr step)
{
	instructionPtr ip = calloc(1, sizeof(instruction));
	readMatrixFromString(step->value, step->symbol);
	ip->opcode = kPushValue;
	ip->data = (unsigned long)step;
	return ip;
}

instructionPtr makeArray(symbolTableEntryPtr step)
{
	instructionPtr ip = calloc(1, sizeof(instruction));
	readArrayFromString(step->value, step->symbol);
	ip->opcode = kPushValue;
	ip->data = (unsigned long)step;
	return ip;
}

typedef struct {
	char *name;
	unsigned long address;
	unsigned char nArgs;
	int immediate;
} function, *functionPtr;

function functions[] = {
"abs", (unsigned long)fabs, 1, 0,
"acos", (unsigned long)acos, 1, 0,
"add", (unsigned long)add, 2, 0,
"and", (unsigned long)and, 2, 0,
"gt", (unsigned long)gt, 2, 0,
"asin", (unsigned long)asin, 1, 0,
"atan",  (unsigned long)atan, 1, 0,
"abs", (unsigned long)fabs, 1, 0,
"ceil", (unsigned long)ceil, 1, 0,
"cos", (unsigned long)cos, 1, 0,
"divide", (unsigned long)divide, 2, 0,
"eq", (unsigned long)eq, 2, 0,
"exp", (unsigned long)exp, 1, 0,
"frac", (unsigned long)frac, 1, 0,
"gt", (unsigned long)gt, 2, 0,
"gteq", (unsigned long)gteq, 2, 0,
"ln", (unsigned long)ln, 1, 0,
"lt", (unsigned long)lt, 2, 0,
"lteq", (unsigned long)lteq, 2, 0,
"makeArray", (unsigned long)makeArray, 1, 1,
"makeFloat", (unsigned long)makeFloat, 1, 1,
"makeMatrix", (unsigned long)makeMatrix, 1, 1,
"minus", (unsigned long)minus, 1, 0,
"mod", (unsigned long)mod, 2, 0,
"mult", (unsigned long)mult, 2, 0,
"or", (unsigned long)or, 2, 0,
"not", (unsigned long)not, 2, 0,
"power", (unsigned long)pow, 2, 0,
"round", (unsigned long)round, 1, 0,
"sin", (unsigned long)sin, 1, 0,
"sqr", (unsigned long)sqr, 1, 0,
"sqrt", (unsigned long)sqrt, 1, 0,
"sub", (unsigned long)sub, 2, 0,
"tan",  (unsigned long)tan, 1, 0,
"trunc", (unsigned long)trunc, 1, 0,
};

functionPtr functionSearch(const char* symbol)
{
	for (int i = 0; i < 35; i++) {
		if (strcmp(symbol, functions[i].name) == 0) {
			return &functions[i];
		}
	}
	return (functionPtr)nil;
}

symbolTableEntryPtr symbolTableEntrySearch(symbolTableEntry ste[], int length, const char*symbol)
{
	for (int i = 0; i < length; i++) {
		if (strcmp(symbol, ste[i].symbol) == 0) {
			return &ste[i];
		}
	}
	return (symbolTableEntryPtr)nil;
}

@implementation HMHTL

NSMutableDictionary *sharedVariables;

+(void)initialize
{
	  store = calloc(storeSize, sizeof(Value));
	  NSEnumerator *e = [[NSArray arrayWithObjects:@"dt", @"time", @"julianday", nil] objectEnumerator];
	  NSString *token;
	  symbolTableEntryPtr step;
	  sharedVariables = [[NSMutableDictionary alloc] init];
	  while (token = [e nextObject]) {
			char *symbol = malloc(([token length] + 1) * sizeof(char));
			strcpy(symbol, [token cStringUsingEncoding:NSMacOSRomanStringEncoding]);
			step = calloc(1, sizeof(symbolTableEntry));
			step->symbol = symbol;
			step->value = calloc(1, sizeof(Value));
			[sharedVariables setValue:[NSValue valueWithPointer:step] forKey:token];
	  }
}

+(NSSet*)reservedIDSet
{
	return [NSSet setWithObjects:@"dt", @"time", @"julianday", nil];
}

+(void)addSharedVariable:(NSString*)token withValue:(Value*)value
{
	if (![sharedVariables valueForKey:token]) {
		char *symbol = malloc(([token length] + 1) * sizeof(char));
		strcpy(symbol, [token cStringUsingEncoding:NSMacOSRomanStringEncoding]);
		symbolTableEntryPtr step = calloc(1, sizeof(symbolTableEntry));
		step->symbol = symbol;
		if (!value) {
			value = calloc(1, sizeof(Value));
		}
		step->value = value;
		[sharedVariables setValue:[NSValue valueWithPointer:step] forKey:token];	
	}
}

+(symbolTableEntryPtr)sharedVariableWithName:(NSString*)name
{
	NSValue *value = [sharedVariables valueForKey:name];
	if (value) {
		return (symbolTableEntryPtr)[value pointerValue];
	}
	else {
	  return (symbolTableEntryPtr)nil;
	}
}

+(Value*)finalValueForPort:(HMPort*)port
{
	symbolTableEntryPtr step = [self sharedVariableWithName:[port name]];
	if (step) {
		return step->value;
	} else {
		return [port finalValue];
	}
}

- (NSArray*)otherDependencies
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"\\[[A-Za-z][A-Za-z0-9]*\\]"
                                                                           options:NSRegularExpressionUseUnicodeWordBoundaries
                                                                             error:&error];
    NSString *program = [self valueForKey:@"programrpn"];
    NSArray *matches = [regex matchesInString:program
                                      options:0
                                        range:NSMakeRange(0, program.length)];
    if (matches.count == 0) {
        return nil;
    }
    NSMutableSet *globalNames = [NSMutableSet set];
    for (NSTextCheckingResult *result in matches) {
        NSString *gname = [program substringWithRange:result.range];
        [globalNames addObject:[gname lowercaseString]];
    }
    NSMutableSet *inputNames = [NSMutableSet set];
    for (HMInput *input in inputs) {
        [inputNames addObject:[[input name] lowercaseString]];
    }
    NSMutableSet *outputNames = [NSMutableSet set];
    for (HMInput *output in outputs) {
        [outputNames addObject:[[output name] lowercaseString]];
    }
    extern NSArray *globals;
    [globalNames minusSet:inputNames];
    [globalNames minusSet:outputNames];
    NSMutableArray *dependencies = [NSMutableArray array];
    for (NSString *gname in [globalNames allObjects]) {
        NSInteger index = [globals indexOfObjectPassingTest:^BOOL(HMOutput *obj, NSUInteger idx, BOOL *stop)
                             {
                                 return [gname isEqualToString:[[obj name] lowercaseString]];
                             }];
        NSAssert(index != NSNotFound, @"Couldn't find global %@", name);
        [dependencies addObject:globals[index]];
    }
    return dependencies;
}

- (void) disassemble
{
	for (int i = 0; i < instructionCount; i++) {
		instructionPtr instruction = instructions[i];
		symbolTableEntryPtr step = (symbolTableEntryPtr)instruction->data;
		switch (instruction->opcode) {
			case kPushValue:
				printf("%3d: psv\t%s\n", i, step->symbol);
				break;
			case kApply1:
				printf("%3d: ap1\n", i);
				break;
			case kApply2:
				printf("%3d: ap2\n", i);
				break;
			case kJump:
				printf("%3d: jmp\t%04lu\n", i, instruction->data);
				break;
			case kIf:
				printf("%3d: if\n", i);
				break;
			case kPushFunc:
			{
				functionPtr fp = (functionPtr)instruction->data;
				printf("%3d: psf\t%s\n", i, fp->name);
				
			}
				break;
			case kAssign:
				printf("%3d: sto\n", i);
				break;
				
			default:
				break;
		}
	}
}

-(void *)pop
{
	  return stack[--tos];
}

-(void) push:(void *)p
{
	  NSCAssert(p, @"Pushing null pointer");
	  stack[tos++] = p;
}

-(void*) peek
{
	  return stack[tos - 1];
}

-(void) assign
{
	  Value *a = (Value*)[self pop];
	  Value *b = (Value*)[self pop];
	  copyValue(a, b);
}

- (void)awake
{
	  [super initialize];
	  NSSet *idSet = [NSSet setWithArray:[identifiers componentsSeparatedByString:@","]];
	  NSMutableDictionary *portDictionary = [NSMutableDictionary dictionary];
	  NSEnumerator *e = [[[self inputs] arrayByAddingObjectsFromArray:[self outputs]]
						 objectEnumerator];
	  HMPort *port;
	  while (port = [e nextObject]) {
			[portDictionary setValue:port forKey:[[port name] lowercaseString]];
	  }
	  NSArray *tokens = [programrpn componentsSeparatedByString:@" "];
	  
	  localVariables = [NSMutableArray array];
	  e = [idSet objectEnumerator];
	  NSString *token;
	  steLength = [idSet count];
	  ste = calloc(steLength, sizeof(symbolTableEntry));
	  symbolTableEntry *step = ste;
	  while (token = [e nextObject]) {
			char *symbol = malloc(([token length] + 1) * sizeof(char));
			strcpy(symbol, [token cStringUsingEncoding:NSMacOSRomanStringEncoding]);
			step->symbol = symbol;
			symbolTableEntryPtr globalSymbol = [HMHTL sharedVariableWithName:token];
			if (globalSymbol) {
				  step->value = globalSymbol->value;
			} else {
				  port = [portDictionary valueForKey:[token lowercaseString]];
				  if (port) {
						step->value = [HMHTL finalValueForPort:port];
				  }
				  else {
						step->value = calloc(1, sizeof(Value));
						[localVariables addObject:[NSValue valueWithPointer:step]];
				  }
			}
			step++;
	  }
	  
	  NSMutableArray *instructions1 = [NSMutableArray array];
	  
	  e = [tokens objectEnumerator];
	  while (token = [e nextObject]) {
			functionPtr func;
			symbolTableEntryPtr step;
			const char *cToken = [token cStringUsingEncoding:NSMacOSRomanStringEncoding];
			instructionPtr ip;
			if ([token isEqualToString:@"assign"]) {
				  ip = calloc(1, sizeof(instruction));
				  ip->opcode = kAssign;
				  [instructions1 addObject:[NSValue valueWithPointer:ip]];
			} else if ([token isEqualToString:@"sum"]) {
				  ip = calloc(1, sizeof(instruction));
				  ip->opcode = kSum;
				  [instructions1 addObject:[NSValue valueWithPointer:ip]];
            } else if ([token isEqualToString:@"csum"]) {
                ip = calloc(1, sizeof(instruction));
                ip->opcode = kCSum;
                [instructions1 addObject:[NSValue valueWithPointer:ip]];
            } else if ([token isEqualToString:@"rsum"]) {
                ip = calloc(1, sizeof(instruction));
                ip->opcode = kRSum;
                [instructions1 addObject:[NSValue valueWithPointer:ip]];
            } else if ((func = functionSearch(cToken))) {
				  if (func->immediate) {
						instructionPtr(*f)(symbolTableEntryPtr) = (void*)func->address;
						ip = f((symbolTableEntryPtr)[self pop]);
						[instructions1 addObject:[NSValue valueWithPointer:ip]];
				  } else {
						ip = calloc(1, sizeof(instruction));
						ip->data = (unsigned long)func;
						ip->opcode = kPushFunc;
						[instructions1 addObject:[NSValue valueWithPointer:ip]];
						ip = calloc(1, sizeof(instruction));
						ip->opcode = func->nArgs;
						[instructions1 addObject:[NSValue valueWithPointer:ip]];
				  }
			} else if ((step = symbolTableEntrySearch(ste, steLength, cToken))) {
				  ip = calloc(1, sizeof(instruction));
				  [instructions1 addObject:[NSValue valueWithPointer:ip]];
				  ip->opcode = kPushValue;
				  ip->data = (unsigned long)step;
				  
			} else if ([token isEqualToString:@"if"]) {
				  ip = calloc(1, sizeof(instruction));
				  [instructions1 addObject:[NSValue valueWithPointer:ip]];
				  ip->opcode = kIf;
				  ip = calloc(1, sizeof(instruction));
				  [instructions1 addObject:[NSValue valueWithPointer:ip]];
				  ip->opcode = kJump;
				  [self push:ip];
				  
			} else if ([token isEqualToString:@"else"]) {
				  ip = [self pop];
				  ip->data = [instructions1 count] + 1;
				  ip = calloc(1, sizeof(instruction));
				  [instructions1 addObject:[NSValue valueWithPointer:ip]];
				  ip->opcode = kJump;
				  [self push:ip];
				  
			} else if ([token isEqualToString:@"endif"]) {
				  ip = [self pop];
				  ip->data = [instructions1 count];
				  
			} else {
				  symbolTableEntryPtr step = calloc(1, sizeof(symbolTableEntry));
				  char *symbol = calloc(([token length] + 1), sizeof(char));
				  memcpy(symbol, [token cStringUsingEncoding:NSMacOSRomanStringEncoding], [token length]);
				  step->symbol = symbol;
				  step->value = calloc(1, sizeof(Value));
				  [self push:step];
			}
	  }
	  instructionCount = [instructions1 count];
	  instructions = calloc(instructionCount, sizeof(instructionPtr));
	  instructionPtr *pInstruction = instructions;
	  e = [instructions1 objectEnumerator];
	  NSValue *value;
	  instructionPtr instr;
	  while (value = [e nextObject]) {
			instr = [value pointerValue];
			*pInstruction++ = instr;
	  }
	  tos = 0;
}

- (void)initialize
{
	  tos = 0;
	  NSEnumerator *e = [localVariables objectEnumerator];
	  symbolTableEntryPtr step;
	  NSValue *value;
	  while (value = [e nextObject]) {
			step = [value pointerValue];
			setFloatValue(step->value, 0.0);
	  }
	  
	  e = [outputs objectEnumerator];
	  HMOutput *output;
	  while (output = [e nextObject]) {
			Value *val = [output value];
			setFloatValue(val, -10.0);
	  }
}

NSString *stringValue(Value *val);

- (void)dumpSymbolTable
{
	int maxLength = 0, n;
	for (int i = 0; i < steLength; i++) {
		n = strlen(ste[i].symbol);
		if (n > maxLength) {
			maxLength = n;
		}
	}
	maxLength++;
	for (int i = 0; i < steLength; i++) {
		printf("%*s %s\n", maxLength, ste[i].symbol, 
			   [stringValue(ste[i].value) cStringUsingEncoding:NSMacOSRomanStringEncoding]);
	}
}

- (void)dumpStack
{
	if (tos == 0) {
		printf("Stack is empty\n");
		return;
	}
	for (int i = 0; i < tos; i++) {
		void *object = stack[i];
		int j;
		BOOL foundInFunctionTable = NO;
		for (j = 0; j < 36; j++) {
			if (object == (void*)functions[j].address) {
				foundInFunctionTable = YES;
				printf("%2d: %s()\n", i, functions[j].name);
			}
		}
		if (!foundInFunctionTable) {
			BOOL foundInSymbolTable = NO;
			for (j = 0; j < steLength; j++) {
				if (object == ste[j].value) {
					foundInSymbolTable = YES;
					printf("%2d: %s %s\n", i, ste[j].symbol, [stringValue(ste[j].value) cStringUsingEncoding:NSMacOSRomanStringEncoding]);
				}
			}
			if (!foundInSymbolTable) {
				printf("%2d: constant %s\n", i, [stringValue(object) cStringUsingEncoding:NSMacOSRomanStringEncoding]);
			}
		}
	}
}

- (void)updateRates
{
    pStore = 0;
    instructionPtr instr;
    symbolTableEntryPtr step;
    Value *v, *v1, *v2;
    double (*f1)(double);
    double (*f2)(double a, double b);
    
    //	if ([[self fullPath] isEqualToString:@"/Environmental Factors/Solar Radiation/Par/Solar Position/SolarTime/"]) {
    //		Debugger();
    //	}
    unsigned long pc = 0;
    NSCAssert(tos == 0, @"TOS is not zero before execution.");
    while (pc < instructionCount) {
        instr = instructions[pc];
        switch (instr->opcode) {
            case kPushValue:
                step = (symbolTableEntryPtr)(instr->data);
                /*
                 if (!(step->value->utype > errortype
                 && step->value->utype < endtype)) {
                 NSException *ex = [NSException
                 exceptionWithName:@"Undefined Variable"
                 reason:[NSString stringWithFormat:@"Variable \"%s\" is undefined"
                 " during the evaluation of %@",
                 step->symbol, [self fullPath]]
                 userInfo:nil];
                 [ex raise];
                 }
                 */
                [self push:(void*)(step->value) ];
                pc++;
                break;
            case kApply1:
                f1 = (void*)[self pop];
                v1 = (Value*)[self pop];
                v = apply1(f1, v1);
                [self push:v];
                pc++;
                break;
            case kApply2:
                f2 = (void*)[self pop];
                v2 = (Value*)[self pop];
                v1 = (Value*)[self pop];
                v = apply2(f2, v1, v2);
                [self push:v];
                pc++;
                break;
            case kJump:
                pc = instr->data;
                break;
            case kIf:
                v = (Value*)[self pop];
                if (isFalse(v)) {
                    pc++;
                } else {
                    pc += 2;
                }
                break;
            case kPushFunc:
            {
                functionPtr fp = (void*)instr->data;
                [self push:(void*)fp->address];
                pc++;
                break;
                
            }
            case kSum:
            {
                v1 = (Value*)[self pop];
                v = sum(v1);
                [self push:v];
                pc++;
                break;
            }
            case kCSum:
            {
                v1 = (Value*)[self pop];
                v = csum(v1);
                [self push:v];
                pc++;
                break;
            }
            case kRSum:
            {
                v1 = (Value*)[self pop];
                v = rsum(v1);
                [self push:v];
                pc++;
                break;
            }
            case kAssign:
                [self assign];
                NSCAssert(tos == 0, @"TOS is not zero after assignment.");
                pc++;
                break;
                
            default:
                break;
        }
    }
    NSCAssert(tos == 0, @"TOS is not zero after execution.");
}


@end

void disassemble(HMHTL *htl)
{
	[htl disassemble];
}
