%{
#include "y.tab.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

	
unsigned lineno;
int yywrap();

int yywrap() { return 1; }

%}

char *buf;
YY_BUFFER_STATE *state = yy_scan_string(buf) ;

%%

'∞' { 
	yylval.dval = 1.0 / 0.0;
	return(NUMBER);
}

[+-]?[0-9]+("."[0-9]*("e"[-+][0-9]+)?)? { 
	yylval.dval = atof(yytext);
	return(NUMBER);
}

"."[0-9]+("e"[-+][0-9]+)? { 
	yylval.dval = atof(yytext);
	return(NUMBER);
}

"{}" return NULLARRAY;
"{{}}" return NULLMATRIX;

"{" return LBRACE;
"}" return RBRACE;
"," return COMMA;
[ \t] ;
[^{}\ \.\:+\,\-0-9][^\:]* {
	yylval.sval = strdup(yytext);
	return PATH;
}
<<EOF>> return EOF;
%%

YY_BUFFER_STATE buf_state;

int end_parse()
{
	yy_delete_buffer(buf_state);
	return 0;
}


void setup(const char* buffer)
{
	lineno = 0;
	buf_state = yy_scan_string(buffer);
}
