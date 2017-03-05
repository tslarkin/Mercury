/*
 *  Value.h
 *  Hermes
 *
 *  Created by Timothy Larkin on 11/24/06.
 *  Copyright 2006 Abstract Tools. All rights reserved.
 *
 */
typedef struct {
	unsigned int utype; // the union tag
	unsigned int length1;  // the length of the vector if utype == arraytype,
                           // or the number of columns if utype == matrixtype.
	unsigned int length2;  // the number of rows if utype == matrixtype.
	void *port; // a pointer to the port this value belongs to.
	union {
		float dval;
		float *aval;
		float **mval;
		char *sval;
	} u;
} Value;

// The types of values. There are more types than representations
// since a value.u.mvalue , for instance, can be either a 2D delay
// matrixtype, or a lookuptype.
typedef enum valueType {
	undefined, errortype, floattype, arraytype, matrixtype, pathtype, lookuptype, endtype
} ValueType;

// free the memory allocated by calloc.
void freeValue(Value *val);
// Getters and setters for each valueType.
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
// Make the target have a copy of the value of the source.
void copyValue(Value *target, Value *source);
// Promotes a float to an array of length count initialized at each element with x.
void promoteFloat(Value *v, float x, int count);
// Promotes an array to a matrix with each row set to the value of x.
void promoteArray(Value *v, float *x, int columns, int rows);
// returns the number of value.length1 and value.length2.
// Note that these numbers will be garbage if the value is
// not an array or matrix, and length2 will be garbage if
// the value is not a matrix.
unsigned int columns(Value *val);
unsigned int rows(Value *val);
