/*	Definition section */
%{
extern int yylineno;
extern int yylex();
extern char* yytext;   // Get current token from lex
extern char buf[256];  // Get current code line from lex

/* Symbol table function - you can add new function if needed. */
int lookup_symbol();
void create_symbol();
void insert_symbol();
void dump_symbol();

#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
#include <string.h>

#define MAX_NAME 32
#define MAX_ATTRI 32
#define NIL (void*)-1

char attributes_buf[MAX_ATTRI] = {'\0'};

struct symbol_node{
    char name[MAX_NAME];
    char entry_type[10];
    char data_type[6];
    int level;
    char attributes[MAX_ATTRI];
    struct symbol_node * next;
};

typedef struct symbol_node sym_node;
typedef struct symbol_node * sym_node_ptr;

struct symbol_table{
    struct symbol_table * next;
    int level;
    sym_node_ptr first;
};

typedef struct symbol_table sym_tab;
typedef struct symbol_table * sym_tab_ptr;

sym_tab_ptr SYM_TAB = NIL;
int level = 0;

void yyerror(char*);
%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
}

/* Token without return */
%token PRINT 
%token IF ELSE FOR WHILE
%token SEMICOLON
%token ADD SUB MUL DIV MOD INC DEC
%token MT LT MTE LTE EQ NE
%token ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token AND OR NOT
%token LB RB LCB RCB LSB RSB COMMA
%token TRUE FALSE RET

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> STRING
%token <string> ID
%token <string> VOID INT FLOAT BOOL

/* Nonterminal with return, which need to sepcify type */
%type <string> type_spec

/* Yacc will start at this nonterminal */
%start program

/* precedence */
%right ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%left OR AND EQ NE
%left MT LT MTE LTE  
%left ADD SUB 
%left MUL DIV MOD
%nonassoc INC DEC NOT

%nonassoc IFX
%nonassoc ELSE

/* Grammar section */
%%

program
    : decl_list
    ;

decl_list
    : decl_list decl
    | decl
    ;

decl
    : var_decl
    | fun_decl
    ;

var_decl
    : type_spec ID SEMICOLON { insert_symbol($2, "variable", $1, ""); }
    | type_spec ID ASGN expr SEMICOLON { insert_symbol($2, "variable", $1, ""); }
    ;

type_spec
    : VOID 
    | BOOL
    | INT
    | FLOAT
    | STRING
    ;

fun_decl
    : type_spec ID LB params RB function_compound_stmt { insert_symbol($2, "function", $1, ""); }
    | type_spec ID LB params RB SEMICOLON { insert_symbol($2, "function", $1, ""); }
    ;

params
    : param_list
    | VOID
    ;

param_list
    : param_list COMMA param
    | param
    ;

param
    : type_spec ID 
    |
    ;

function_compound_stmt 
    : LCB { level++; create_symbol(); } content_list RCB { dump_symbol(); level--; }
    ;
compound_stmt
    : LCB { level++; create_symbol(); } content_list RCB { dump_symbol(); level--; }
    ;

content_list
    : content_list content
    |
    ;

content
    : var_decl
    | stmt

stmt
    : expr SEMICOLON
    | compound_stmt 
    | if_stmt
    | while_stmt
    | return_stmt
    | print_stmt SEMICOLON
    ;

print_stmt
    : PRINT LB ID RB
    | PRINT LB STRING RB
    ;

while_stmt
    : WHILE LB expr RB stmt

if_stmt
    : IF LB expr RB stmt %prec IFX
    | IF LB expr RB stmt ELSE stmt

return_stmt
    : RET SEMICOLON
    | RET expr SEMICOLON

expr
    : ID ASGN expr
    | ID ADDASGN expr
    | ID SUBASGN expr
    | ID MULASGN expr
    | ID DIVASGN expr 
    | ID MODASGN expr
    | expr OR expr
    | expr AND expr
    | expr EQ expr
    | expr NE expr
    | expr LTE expr
    | expr LT expr
    | expr MTE expr
    | expr MT expr
    | expr ADD expr
    | expr SUB expr
    | expr MUL expr
    | expr DIV expr
    | expr MOD expr
    | NOT expr
    | expr INC
    | expr DEC
    | LB expr RB
    | ID 
    | ID LB args RB
    | TRUE
    | FALSE
    | I_CONST
    | F_CONST
    | SUB I_CONST
    | SUB F_CONST
    | STRING
    ;

arg_list
    : arg_list COMMA expr
    | expr
    ;

args
    : arg_list
    |
    ;


%%

/* C code section */
int main(int argc, char** argv)
{
    create_symbol();
    yylineno = 0;



    yyparse();
	printf("\nTotal lines: %d \n",yylineno);

    dump_symbol();

    return 0;
}

void yyerror(char *s)
{
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno + 1, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
}

void create_symbol() {

    sym_tab_ptr p = calloc(1, sizeof(sym_tab));

    if(SYM_TAB == NIL){
        // Create a new symbol table as first table

        // Initialize a symbol table 
        p->next = NIL;
        p->level = level;
        p->first = NIL;
        

        // Assign as head
        SYM_TAB = p;
    }
    else{
        // Initialize a symbol table
        p->next = SYM_TAB;
        p->level = level;
        p->first = NIL;


        // Add to head of symbol tables
        SYM_TAB = p;
    }

    printf("Create symbol table of level: %d\n", p->level);
}
void insert_symbol(const char* name, const char* entry_type, 
                  const char* data_type, const char* attributes) {
    //printf("Inserting symbol / %s / %s / %s / %s /\n", name, entry_type, data_type, attributes);
    
    
    sym_node_ptr p = calloc(1, sizeof(sym_node));

    strncpy(p->name, name, MAX_NAME-1);
    strncpy(p->entry_type, entry_type, 9);
    strncpy(p->data_type, data_type, 5);
    p->level = level;
    strncpy(p->attributes, attributes, MAX_ATTRI-1);

    p->next = NIL;

    sym_node_ptr pos = SYM_TAB->first;

    // Originally empty
    if(pos == NIL){
        SYM_TAB->first = p;
    }

    // Originally not empty
    else{
        while(pos->next != NIL){
            pos = pos->next;
        }
        pos->next = p;
    }
    

    

    // printf("Inserted symbol %s done\n", name);
}
int lookup_symbol() {}
void dump_symbol() {

    printf("\n Dumping symbol table of level: %d\n", SYM_TAB->level);

    // Symbol table from head
    sym_tab_ptr del_sym_tab = SYM_TAB;
    sym_node_ptr p = del_sym_tab->first;
    if(p == NIL){
        printf("Empty symbol table!\n");
    }

    else{
        printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
        int index = 0;
        while(p != NIL){
            printf("%-10d%-10s%-12s%-10s%-10d%-10s\n",
                    index,
                    p->name,
                    p->entry_type,
                    p->data_type,
                    p->level,
                    p->attributes);
            sym_node_ptr del_node = p;
            p = p->next;

            // Free each symbol node
            free(del_node);
            index ++; 
        }
    }
    
    // Remove symbol table from head
    SYM_TAB = SYM_TAB->next;
    free(del_sym_tab);
}
