/*
 *  Value.h
 *  Hermes
 *
 *  Created by Timothy Larkin on 11/24/06.
 *  Copyright 2006 Abstract Tools. All rights reserved.
 *
 */
typedef struct {
	unsigned int utype;
	unsigned int length1;
	unsigned int length2;
	void *port;
	union {
		float dval;
		float *aval;
		float **mval;
		char *sval;
	} u;
} Value;

typedef enum valueType {
	undefined, errortype, floattype, arraytype, matrixtype, pathtype, lookuptype, endtype
} ValueType;

void freeValue(Value *val);
char *pathValue(Value *val);
void setPathValue(Value *val, char *s);
void setFloatValue(Value *val, float d);
void setIntValue(Value *val, int d);
void setArrayValue(Value *val, float *d, int n);
void setZeroArrayValue(Value *val, int n);
void setMatrixValue(Value *val, float **d, int n1, int n2);
void setZeroMatrixValue(Value *val, int n1, int n2);
void setUndefined(Value *val);
int intValue(Value *val);
float floatValue(Value *val);
float *arrayValue(Value *val);
float **matrixValue(Value *val);
float **lookupValue(Value *val);
void copyValue(Value *target, Value *source);
void promoteFloat(Value *v, float x, int count);
void promoteArray(Value *v, float *x, int columns, int rows);
unsigned int columns(Value *val);
unsigned int rows(Value *val);
