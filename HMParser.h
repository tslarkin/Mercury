//typedef enum valueType {
//	undefined, errortype, floattype, arraytype, matrixtype, stringtype, endtype
//} ValueType;
//
ValueType VALParse(const char *buf);
NSString* HTLParse(const char *buf, NSMutableSet *idSet, int *error);
extern NSString *HTLProcedure, *HTLIdentifiers;