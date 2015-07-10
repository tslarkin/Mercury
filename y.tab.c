#ifndef lint
static const char yysccsid[] = "@(#)yaccpar	1.9 (Berkeley) 02/21/93";
#endif

#include <stdlib.h>

#define YYBYACC 1
#define YYMAJOR 1
#define YYMINOR 9
#define YYPATCH 20070509

#define YYEMPTY (-1)
#define yyclearin    (yychar = YYEMPTY)
#define yyerrok      (yyerrflag = 0)
#define YYRECOVERING (yyerrflag != 0)

extern int yyparse(void);

static int yygrowstack(void);
#define YYPREFIX "yy"
#line 2 "parse.y"
  /*#include <libc.h>*/
#include <math.h>
#include "Value.h"

Value *v;

int n, n1, n2;
int N, N1, N2;
float d;
float *d1;
float **d2;

#define YYDEBUG 1
	int yyerror(char *s);
#line 20 "parse.y"
typedef union
{
	float dval;
	float *aval;
	float **mval;
	char* sval;
} YYSTYPE;
#line 45 "y.tab.c"
#define LBRACE 257
#define RBRACE 258
#define COMMA 259
#define NUMBER 260
#define PATH 261
#define YYERRCODE 256
short yylhs[] = {                                        -1,
    0,    0,    0,    0,    3,    3,    1,    5,    5,    2,
    4,
};
short yylen[] = {                                         2,
    1,    1,    1,    1,    1,    3,    1,    1,    2,    3,
    3,
};
short yydefred[] = {                                      0,
    0,    1,    4,    0,    2,    3,    0,    7,    5,    8,
    0,    0,   10,    0,   11,    9,    6,
};
short yydgoto[] = {                                       4,
    9,    5,   11,    6,   12,
};
short yysindex[] = {                                   -256,
 -254,    0,    0,    0,    0,    0, -258,    0,    0,    0,
 -251, -248,    0, -258,    0,    0,    0,
};
short yyrindex[] = {                                      0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,
};
short yygindex[] = {                                      0,
   -2,   -1,    0,    0,    0,
};
#define YYTABLESIZE 12
short yytable[] = {                                      10,
    1,    8,    7,    2,    3,    8,   13,   14,    7,   15,
   16,   17,
};
short yycheck[] = {                                       1,
  257,  260,  257,  260,  261,  260,  258,  259,  257,  258,
   12,   14,
};
#define YYFINAL 4
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
#define YYMAXTOKEN 261
#if YYDEBUG
char *yyname[] = {
"end-of-file",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"LBRACE","RBRACE","COMMA",
"NUMBER","PATH",
};
char *yyrule[] = {
"$accept : value",
"value : NUMBER",
"value : array",
"value : matrix",
"value : PATH",
"numbers : number",
"numbers : numbers COMMA number",
"number : NUMBER",
"arrays : array",
"arrays : arrays array",
"array : LBRACE numbers RBRACE",
"matrix : LBRACE arrays RBRACE",
};
#endif
#if YYDEBUG
#include <stdio.h>
#endif

/* define the initial stack-sizes */
#ifdef YYSTACKSIZE
#undef YYMAXDEPTH
#define YYMAXDEPTH  YYSTACKSIZE
#else
#ifdef YYMAXDEPTH
#define YYSTACKSIZE YYMAXDEPTH
#else
#define YYSTACKSIZE 500
#define YYMAXDEPTH  500
#endif
#endif

#define YYINITSTACKSIZE 500

int      yydebug;
int      yynerrs;
int      yyerrflag;
int      yychar;
short   *yyssp;
YYSTYPE *yyvsp;
YYSTYPE  yyval;
YYSTYPE  yylval;

/* variables for the parser stack */
static short   *yyss;
static short   *yysslim;
static YYSTYPE *yyvs;
static int      yystacksize;
#line 114 "parse.y"
 /* beginning of functions section */

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
#line 186 "y.tab.c"
/* allocate initial stack or double stack size, up to YYMAXDEPTH */
static int yygrowstack(void)
{
    int newsize, i;
    short *newss;
    YYSTYPE *newvs;

    if ((newsize = yystacksize) == 0)
        newsize = YYINITSTACKSIZE;
    else if (newsize >= YYMAXDEPTH)
        return -1;
    else if ((newsize *= 2) > YYMAXDEPTH)
        newsize = YYMAXDEPTH;

    i = yyssp - yyss;
    newss = (yyss != 0)
          ? (short *)realloc(yyss, newsize * sizeof(*newss))
          : (short *)malloc(newsize * sizeof(*newss));
    if (newss == 0)
        return -1;

    yyss  = newss;
    yyssp = newss + i;
    newvs = (yyvs != 0)
          ? (YYSTYPE *)realloc(yyvs, newsize * sizeof(*newvs))
          : (YYSTYPE *)malloc(newsize * sizeof(*newvs));
    if (newvs == 0)
        return -1;

    yyvs = newvs;
    yyvsp = newvs + i;
    yystacksize = newsize;
    yysslim = yyss + newsize - 1;
    return 0;
}

#define YYABORT goto yyabort
#define YYREJECT goto yyabort
#define YYACCEPT goto yyaccept
#define YYERROR goto yyerrlab
int
yyparse(void)
{
    register int yym, yyn, yystate;
#if YYDEBUG
    register const char *yys;

    if ((yys = getenv("YYDEBUG")) != 0)
    {
        yyn = *yys;
        if (yyn >= '0' && yyn <= '9')
            yydebug = yyn - '0';
    }
#endif

    yynerrs = 0;
    yyerrflag = 0;
    yychar = YYEMPTY;

    if (yyss == NULL && yygrowstack()) goto yyoverflow;
    yyssp = yyss;
    yyvsp = yyvs;
    *yyssp = yystate = 0;

yyloop:
    if ((yyn = yydefred[yystate]) != 0) goto yyreduce;
    if (yychar < 0)
    {
        if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, reading %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
    }
    if ((yyn = yysindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: state %d, shifting to state %d\n",
                    YYPREFIX, yystate, yytable[yyn]);
#endif
        if (yyssp >= yysslim && yygrowstack())
        {
            goto yyoverflow;
        }
        *++yyssp = yystate = yytable[yyn];
        *++yyvsp = yylval;
        yychar = YYEMPTY;
        if (yyerrflag > 0)  --yyerrflag;
        goto yyloop;
    }
    if ((yyn = yyrindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
        yyn = yytable[yyn];
        goto yyreduce;
    }
    if (yyerrflag) goto yyinrecovery;

    yyerror("syntax error");

#ifdef lint
    goto yyerrlab;
#endif

yyerrlab:
    ++yynerrs;

yyinrecovery:
    if (yyerrflag < 3)
    {
        yyerrflag = 3;
        for (;;)
        {
            if ((yyn = yysindex[*yyssp]) && (yyn += YYERRCODE) >= 0 &&
                    yyn <= YYTABLESIZE && yycheck[yyn] == YYERRCODE)
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: state %d, error recovery shifting\
 to state %d\n", YYPREFIX, *yyssp, yytable[yyn]);
#endif
                if (yyssp >= yysslim && yygrowstack())
                {
                    goto yyoverflow;
                }
                *++yyssp = yystate = yytable[yyn];
                *++yyvsp = yylval;
                goto yyloop;
            }
            else
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: error recovery discarding state %d\n",
                            YYPREFIX, *yyssp);
#endif
                if (yyssp <= yyss) goto yyabort;
                --yyssp;
                --yyvsp;
            }
        }
    }
    else
    {
        if (yychar == 0) goto yyabort;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, error recovery discards token %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
        yychar = YYEMPTY;
        goto yyloop;
    }

yyreduce:
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: state %d, reducing by rule %d (%s)\n",
                YYPREFIX, yystate, yyn, yyrule[yyn]);
#endif
    yym = yylen[yyn];
    yyval = yyvsp[1-yym];
    switch (yyn)
    {
case 1:
#line 39 "parse.y"
{
	v->utype = floattype;
	v->u.dval = yyvsp[0].dval;
}
break;
case 2:
#line 44 "parse.y"
{
	v->utype = arraytype;
	v->length1 = n;
	v->u.aval = yyvsp[0].aval;
}
break;
case 3:
#line 50 "parse.y"
{
	v->utype = matrixtype;
	v->length1 = n2;
	v->length2 = n1;
	v->u.mval = yyvsp[0].mval;
}
break;
case 4:
#line 57 "parse.y"
{
	setPathValue(v, yyvsp[0].sval);	
}
break;
case 5:
#line 61 "parse.y"
{
	n = 1;
	N = 10;
	d1 = malloc(10 * sizeof(float));
	d1[0] = yyvsp[0].dval;
	yyval.aval = d1;
}
break;
case 6:
#line 69 "parse.y"
{
	n++;
	if (n > N) {
		N = N * 2;
		d1 = realloc(d1, N * sizeof(float));
	}
	d1[n - 1] = yyvsp[0].dval;
	yyval.aval = d1;
}
break;
case 7:
#line 79 "parse.y"
{
	yyval.dval = yyvsp[0].dval;
}
break;
case 8:
#line 83 "parse.y"
{
	n2 = 1;
	n1 = n;
	N2 = 10;
	d2 = malloc(N2 * sizeof(float*));
	d2[0] = yyvsp[0].aval;
	yyval.mval = d2;
}
break;
case 9:
#line 92 "parse.y"
{
	if ((n1 > 0) && (n < n1)) {
		n1 = n;
	}	
	n2++;
	if (n2 > N2) {
		N2 = N2 * 2;
		d2 = realloc(d2, N2 * sizeof(float*));
	}
	d2[n2 - 1] = yyvsp[0].aval;
	yyval.mval = d2;
}
break;
case 10:
#line 105 "parse.y"
{
	yyval.aval = yyvsp[-1].aval;
}
break;
case 11:
#line 109 "parse.y"
{
	yyval.mval = yyvsp[-1].mval;
}
break;
#line 460 "y.tab.c"
    }
    yyssp -= yym;
    yystate = *yyssp;
    yyvsp -= yym;
    yym = yylhs[yyn];
    if (yystate == 0 && yym == 0)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: after reduction, shifting from state 0 to\
 state %d\n", YYPREFIX, YYFINAL);
#endif
        yystate = YYFINAL;
        *++yyssp = YYFINAL;
        *++yyvsp = yyval;
        if (yychar < 0)
        {
            if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
            if (yydebug)
            {
                yys = 0;
                if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
                if (!yys) yys = "illegal-symbol";
                printf("%sdebug: state %d, reading %d (%s)\n",
                        YYPREFIX, YYFINAL, yychar, yys);
            }
#endif
        }
        if (yychar == 0) goto yyaccept;
        goto yyloop;
    }
    if ((yyn = yygindex[yym]) && (yyn += yystate) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yystate)
        yystate = yytable[yyn];
    else
        yystate = yydgoto[yym];
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: after reduction, shifting from state %d \
to state %d\n", YYPREFIX, *yyssp, yystate);
#endif
    if (yyssp >= yysslim && yygrowstack())
    {
        goto yyoverflow;
    }
    *++yyssp = yystate;
    *++yyvsp = yyval;
    goto yyloop;

yyoverflow:
    yyerror("yacc stack overflow");

yyabort:
    return (1);

yyaccept:
    return (0);
}
