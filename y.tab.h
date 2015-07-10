#define LBRACE 257
#define RBRACE 258
#define COMMA 259
#define NUMBER 260
#define PATH 261
typedef union
{
	float dval;
	float *aval;
	float **mval;
	char* sval;
} YYSTYPE;
extern YYSTYPE yylval;
