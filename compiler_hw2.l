 /* Definition section */
%{
#include "y.tab.h"	/* header file generated by bison */
#include <stdio.h>
#include <stdlib.h>

#define BUF_SIZE 128

extern YYSTYPE yylval; //YYSTYPE
extern void dump_symbol(void);
extern void display_dump(void);
extern char err_msg[BUF_SIZE];

char buf[BUF_SIZE];
char string_buf[BUF_SIZE];
int dump_flag=0;
int semantic_error_flag=0;
int syntax_error_flag=0;

/* This macro is used to record code line */
#define CONCAT { strncat(buf, yytext, BUF_SIZE - strlen(buf) - 1); }
	

%}

/* Define regular expression label */
digit		[0-9]
letter		[a-zA-Z]
integer     {digit}+
float       {digit}+"."{digit}+
id			{letter}+({letter}|{digit})*

%option yylineno

%x COMMENT STRING_STATE

/* Rules section */
%%

 /* Arithmetic */
"+"     { CONCAT return(ADD); }
"-" 	{ CONCAT return(SUB); }
"*" 	{ CONCAT return(MUL); }
"/" 	{ CONCAT return(DIV); }
"%"     { CONCAT return(MOD); }
"++"    { CONCAT return(INC); }
"--"    { CONCAT return(DEC); }

 /* Relational */
">"		{ CONCAT return(MT); }
"<"		{ CONCAT return(LT); }
">="	{ CONCAT return(MTE); }
"<="	{ CONCAT return(LTE); }
"=="	{ CONCAT return(EQ); }
"!="	{ CONCAT return(NE); }

 /* Assignment */
"="		{ CONCAT return(ASGN); }
"+="	{ CONCAT return(ADDASGN); }
"-="	{ CONCAT return(SUBASGN); }
"*="	{ CONCAT return(MULASGN); }
"/="	{ CONCAT return(DIVASGN); }
"%="	{ CONCAT return(MODASGN); }

 /* Logical */
"&&"	{ CONCAT return(AND); }
"||"	{ CONCAT return(OR); }
"!"		{ CONCAT return(NOT); }

 /* Delimiters */
"("		{ CONCAT return(LB); }
")"		{ CONCAT return(RB); }
"{"		{ CONCAT return(LCB); }
"}"		{ CONCAT return(RCB); }
"["		{ CONCAT return(LSB); }
"]"		{ CONCAT return(RSB); }
","		{ CONCAT return(COMMA); }

 /* Print Keywords */	
"print"		{ CONCAT return(PRINT); }

 /* Condition and Loop Keywords */
"if"		{ CONCAT return(IF); }
"else"		{ CONCAT return(ELSE); }
"for"		{ CONCAT return(FOR); }
"while"		{ CONCAT return(WHILE); }

 /* Declaration Keywords */
"void"		{ yylval.string = strdup(yytext); CONCAT return(VOID); }
"int"		{ yylval.string = strdup(yytext); CONCAT return(INT); }
"float"  	{ yylval.string = strdup(yytext); CONCAT return(FLOAT); }
"string"  	{ yylval.string = strdup(yytext); CONCAT return(STRING); }
"bool"  	{ yylval.string = strdup(yytext); CONCAT return(BOOL); }

 /* boolean Keywords */
"true"      { CONCAT return(TRUE); }
"false"     { CONCAT return(FALSE); }

"return"    { CONCAT return(RET); }

 /* String Constant */
\"				        { CONCAT BEGIN STRING_STATE; 
                          memset(string_buf, 0, BUF_SIZE);
                        }
<STRING_STATE>\"		{ CONCAT 
                          BEGIN INITIAL; 
                          yylval.string = strdup(string_buf);
                          return(STRING); }
<STRING_STATE>[^"]*		{ CONCAT 
                          strncat(string_buf, yytext, BUF_SIZE - strlen(string_buf) - 1);
                        }

 /* Number Constant */
{integer}	{ 
                CONCAT
                yylval.i_val = atoi(yytext);
                return(I_CONST);
 }
{float}	    { 
                CONCAT
                yylval.f_val = atof(yytext);
                return(F_CONST);
 }

 /* C type Comment */
"/*"				{ BEGIN COMMENT; CONCAT }
<COMMENT>[^*\n]+	{ CONCAT }
<COMMENT>\n			{ printf("%d: %s\n", yylineno, buf); memset(buf, 0, BUF_SIZE); }
<COMMENT>"*"		{ CONCAT }
<COMMENT>"*/"		{  BEGIN INITIAL; CONCAT}

 /* C++ type Comment */
\/\/.*	{ CONCAT }

 /* Variable ID */
 {id}       { 
                CONCAT
                yylval.string = strdup(yytext);
                return(ID);
  }

 /* others */

[;]         { CONCAT return(SEMICOLON); }
[\n]        {   
                if(buf[0] == '\0'){
                    printf("%d:\n", yylineno);
                }
                else{
                    printf("%d: %s\n", yylineno, buf);
                }
              
			    if(dump_flag){
				    display_dump();
			    }	

                if(semantic_error_flag) {
                    printf("\n|-----------------------------------------------|\n");
                    printf("| Error found in line %d: %s\n", yylineno, buf);
                    printf("| %s", err_msg);
                    printf("\n|-----------------------------------------------|\n\n");
                    semantic_error_flag = 0;
                    memset(err_msg, '\0', BUF_SIZE);
                }

                if(syntax_error_flag){
                    printf("\n|-----------------------------------------------|\n");
                    printf("| Error found in line %d: %s\n", yylineno, buf);
                    printf("| syntax error");
                    printf("\n|-----------------------------------------------|\n\n");
                    syntax_error_flag = 0;
                    memset(err_msg, '\0', BUF_SIZE);

                    exit(1);
                }

                memset(buf, '\0', BUF_SIZE); 
			}
[ \t]		{ CONCAT } /* Ignore */
[^ \t\n] 	{ CONCAT } /* Ignore other charactor sets */
 /* <<EOF>>     {  } */

%%

int yywrap()
{
    return 1;
}
