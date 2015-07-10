/*
 *  Value.c
 *  Hermes
 *
 *  Created by Timothy Larkin on 11/24/06.
 *  Copyright 2006 Abstract Tools. All rights reserved.
 *
 */

#import "Value.h"
#import <Foundation/Foundation.h>

#import "HMPort.h"
unsigned int columns(Value *val)
{
	return val->length1;
}
static NSArray *typeNames = nil;

unsigned int rows(Value *val)
{
	return val->length2;
}

NSString *stringValue(Value *val)
{
	
	NSString *result;
	
	switch (val->utype) {
		case undefined:
			result = @"undefined";
			break;
		case floattype:
			result = [NSString stringWithFormat:@"%f", val->u.dval];
			break;
		case arraytype: {
			NSMutableArray *array = [NSMutableArray array];
			int i;
			for (i = 0; i < val->length1; i++) {
				NSString *x = [NSString stringWithFormat:@"%f", val->u.aval[i]];
				[array addObject:x];
			}
			result = [NSString stringWithFormat:@"{%@}", [array componentsJoinedByString:@", "]];
			break;
		}
		case lookuptype:
		case matrixtype: {
			NSMutableArray *rows = [NSMutableArray array];
			int i, j;
			for (j = 0; j < val->length2; j++) {
				NSMutableArray *array = [NSMutableArray array];
				for (i = 0; i < val->length1; i++) {
					NSString *x = [NSString stringWithFormat:@"%f", val->u.mval[j][i]];
					[array addObject:x];
				}
				[rows addObject: [NSString stringWithFormat:@"{%@}", [array componentsJoinedByString:@", "]]];
			}
			result= [NSString stringWithFormat:@"{%@}", [rows componentsJoinedByString:@", "]];
			break;
		}
		case pathtype:
			result = [NSString stringWithFormat:@"%s", val->u.sval];
			break;

		default: {
			result = @"error";
			break;
		}
	}
	return result;
}

void freeValue(Value *val)
{
	int i;
	switch (val->utype) {
		case undefined:
			break;
		case arraytype:
			free(val->u.aval);
            val->u.aval = nil;
			break;
		case lookuptype:
		case matrixtype:
		{
			for (i = 0; i < val->length2; i++) {
				free(val->u.mval[i]);
                val->u.mval[i] = nil;
			}
			free(val->u.mval);
            val->u.mval = nil;
			break;
		}
		case pathtype:
			free(val->u.sval);
            val->u.sval = nil;
			break;
	}	
	val->length1 = val->length2 = 0;
	val->u.dval = 0.0;
}

void checkDataType(Value *val, ValueType type)
{
	HMPort *thePort = (HMPort*)val->port;
	if (!typeNames) {
		typeNames = [NSArray arrayWithObjects: @"undefined", @"error", @"float", @"array", 
					 @"matrix", @"path", @"lookup", nil];
	}
	if (val->utype != type) {
		HMPort *source;
		source = [thePort finalSource];
		[NSException raise:@"Variable type error" 
					format:@"The input %@ expected to be assigned a value "
							"of type %@, but instead it received a value "
							"of type %@ from %@",
							[thePort fullPath], 
							[typeNames objectAtIndex:type],
							[typeNames objectAtIndex:[source value]->utype],
							[source fullPath]];
	}
}

void setIntValue(Value *val, int d)
{
	freeValue(val);
	val->utype = floattype;
	val->u.dval = d;
}

void setFloatValue(Value *val, float d)
{
	freeValue(val);
	val->utype = floattype;
	val->u.dval = d;
}

void setZeroArrayValue(Value *val, int n)
{
	freeValue(val);
	val->length1 = n;
	val->utype = arraytype;
	val->u.aval = calloc(n, sizeof(float));
}

void setArrayValue(Value *val, float *d, int n)
{
	freeValue(val);
	val->length1 = n;
	val->utype = arraytype;
	val->u.aval = d;
}

void setZeroMatrixValue(Value *val, int n1, int n2)
{
	freeValue(val);
	val->length1 = n1;
	val->length2 = n2;
	val->utype = matrixtype;
	float **m;
	m = calloc(n2, sizeof(float*));
	int i;
	for (i = 0; i < n2; i++) {
		m[i] = calloc(n1, sizeof(float));
	}
	val->u.mval = m;
}

void setMatrixValue(Value *val, float **d, int n1, int n2)
{
	freeValue(val);
	val->length1 = n1;
	val->length2 = n2;
	val->utype = matrixtype;
	val->u.mval = d;
}

void setLookupValue(Value *val, float **d, int n1, int n2)
{
	setMatrixValue(val, d, n1, n2);
}

char *pathValue(Value *val)
{
	checkDataType(val, pathtype);
	return val->u.sval;
}

void setPathValue(Value *val, char *s)
{
	freeValue(val);
	int n = strlen(s) + 1;
	val->u.sval = (char*)malloc(n * sizeof(char));
	val->utype = pathtype;
	strncpy(val->u.sval, s, n);
}


void setUndefined(Value *val)
{
	freeValue(val);
	val->utype = undefined;
}

int intValue(Value *val)
{
	int i = floatValue(val);
	return i;
}


float floatValue(Value *val)
{
	checkDataType(val, floattype);
	return val->u.dval;
}

float *arrayValue(Value *val)
{
	checkDataType(val, arraytype);
	return val->u.aval;
}


float **matrixValue(Value *val)
{
	checkDataType(val, matrixtype);
	return val->u.mval;
}

float **lookupValue(Value *val)
{
	ValueType type = val->utype;
	if (type == matrixtype) {
		checkDataType(val, matrixtype);
	}
	else {
		checkDataType(val, lookuptype);
	}
	return val->u.mval;
}


void promoteFloat(Value *v, float x, int count)
{
	setZeroArrayValue(v, count);int i;
	for(i = 0; i < count; i++) {
		v->u.aval[i] = x;
	}
}

void promoteArray(Value *v, float *x, int columns, int rows)
{
	setZeroMatrixValue(v, columns, rows);int i;
	for (i = 0; i < rows; i++) {
		memcpy(v->u.mval[i], x, columns * sizeof(float));
	}
}

void copyValue(Value *target, Value *source)
{
	switch (source->utype) {
		case floattype:
			setFloatValue(target, floatValue(source));
			break;
		case arraytype:
		{
			int n = source->length1;
			float *z = malloc(n * sizeof(float));
			memcpy(z, source->u.aval, n * sizeof(float));
			setArrayValue(target, z, n);
		}
			break;
		case lookuptype:
		case matrixtype:
		{
			int n1 = source->length1, n2 = source->length2;
			float **z = malloc(n2 * sizeof(float*));
			int i;
			for (i = 0; i < n2; i++) {
				float *zi = malloc(n1 * sizeof(float));
				memcpy(zi, source->u.mval[i], n1 * sizeof(float));
				z[i] = zi;
			}
			setMatrixValue(target, z, n1, n2);			
		}
			break;
		case pathtype:
			setPathValue(target, pathValue(source));
			break;
		default:
			break;
	}
}
