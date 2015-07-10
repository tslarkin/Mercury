%{
  //#include <libc.h>
#include <math.h>
#include "Value.h"
#include <stdlib.h>
Value *v;
extern int yylex (void);
int n, n1, n2;
int N, N1, N2;
float d;
float *d1;
float **d2;

#define YYDEBUG 1
	int yyerror(char *s);
%}

%start value

%union
{
	float dval;
	float *aval;
	float **mval;
	char* sval;
}

%token LBRACE RBRACE COMMA NULLARRAY NULLMATRIX
%token <dval> NUMBER
%token <sval> PATH;
%type <dval> number;
%type <aval> array;
%type <aval> numbers;
%type <mval> matrix;
%type <mval> arrays;


%%
value: NUMBER {
	v->utype = floattype;
	v->u.dval = $1;
}

| array {
	v->utype = arraytype;
	v->length1 = n;
	v->u.aval = $1;
}

| matrix {
	v->utype = matrixtype;
	v->length1 = n2;
	v->length2 = n1;
	v->u.mval = $1;
}

| PATH {
	setPathValue(v, $1);	
}

numbers: number {
	n = 1;
	N = 10;
	d1 = malloc(10 * sizeof(float));
	d1[0] = $1;
	$$ = d1;
}

| numbers COMMA number {
	n++;
	if (n > N) {
		N = N * 2;
		d1 = realloc(d1, N * sizeof(float));
	}
	d1[n - 1] = $3;
	$$ = d1;
}

number: NUMBER {
	$$ = $1;
}

arrays: array {
	n2 = 1;
	n1 = n;
	N2 = 10;
	d2 = malloc(N2 * sizeof(float*));
	d2[0] = $1;
	$$ = d2;
}

| arrays array {
	if ((n1 > 0) && (n < n1)) {
		n1 = n;
	}	
	n2++;
	if (n2 > N2) {
		N2 = N2 * 2;
		d2 = realloc(d2, N2 * sizeof(float*));
	}
	d2[n2 - 1] = $2;
	$$ = d2;
}

array: LBRACE numbers RBRACE {
	$$ = $2;
}

| NULLARRAY {
	n = 0;
	$$ = 0;
}

matrix: LBRACE arrays RBRACE {
	$$ = $2;
}

| NULLMATRIX {
	n1 = n2 = 0;
	$$ = 0;
}


%% /* beginning of functions section */

char *parseError;
extern unsigned lineno;
extern char *yytext;
int error;
void setup(const char* buffer);
int end_parse();


int yyerror(char *s)
{
	snprintf(parseError, 255, "%s while parsing \"%s\"", s, yytext);
	error = 1;
	return error;
}

unsigned valueParse(const char *buf, Value *value, char *errorStr)
{
	n1 = n2 = n = 0;
	parseError = errorStr;
	errorStr = 0;
	int result = 0;
	error = 0;
	yydebug=0;
	v = value;
	setup(buf);
	result = yyparse();
	if (value->utype == pathtype) {
//		DebugStr("\ppath");
	}
	end_parse();
	return result;
}
