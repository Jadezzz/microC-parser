/*	Definition section */
%{

#define BUF_SIZE 128
extern int yylineno;
extern int yylex();
extern char* yytext;   // Get current token from lex
extern char buf[BUF_SIZE];  // Get current code line from lex
extern int dump_flag;
extern int error_flag;
int syntax_error_flag = 0;

char err_msg[128] = {'\0'};
/* Symbol table function - you can add new function if needed. */
int lookup_symbol();
void create_symbol();
void insert_symbol();
void dump_symbol();
void display_dump();
void check_symbol(const char*);

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
    char entry_type[12];
    char data_type[10];
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
sym_tab_ptr DUMP_SYM = NIL;
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
    : type_spec ID SEMICOLON { insert_symbol($2, "variable", $1, "", 0); }
    | type_spec ID ASGN expr SEMICOLON { insert_symbol($2, "variable", $1, "", 0); }
    ;

type_spec
    : VOID 
    | BOOL
    | INT
    | FLOAT
    | STRING
    ;

fun_decl
    : type_spec ID LB { level++; create_symbol(); } params RB { insert_symbol($2, "function", $1, attributes_buf, 1); 
                                    for(int i=0;i<MAX_ATTRI;i++){
                                        attributes_buf[i] = '\0';
                                    } 
                                } fun_decl_cont
    ;

fun_decl_cont
    : SEMICOLON
    | function_compound_stmt
    ;

params
    : param_list
    | VOID { strcat(attributes_buf, "void"); }
    ;

param_list
    : param_list COMMA param
    | param
    ;

param
    : type_spec ID {    
                        insert_symbol($2, "parameter", $1, "", 0);
                        if(attributes_buf[0] == '\0'){
                            strcat(attributes_buf, $1);
                        }
                        else{
                            strcat(attributes_buf, ", ");
                            strcat(attributes_buf, $1);
                        }
                    }
    |
    ;


compound_stmt
    : LCB { level++; create_symbol(); }content_list RCB { dump_symbol(); level--; }
    ;

function_compound_stmt
    : LCB content_list RCB { dump_symbol(); level--; }


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
    : PRINT LB ID RB { check_symbol($3); }
    | PRINT LB STRING RB
    ;

while_stmt
    : WHILE LB expr RB stmt

if_stmt
    : IF LB expr RB compound_stmt
    | IF LB expr RB compound_stmt else_if_stmt

else_if_stmt
    : ELSE IF LB expr RB compound_stmt else_if_stmt
    | else_stmt

else_stmt
    : ELSE compound_stmt

return_stmt
    : RET SEMICOLON
    | RET expr SEMICOLON

expr
    : ID ASGN expr { check_symbol($1); }
    | ID ADDASGN expr { check_symbol($1); }
    | ID SUBASGN expr { check_symbol($1); }
    | ID MULASGN expr { check_symbol($1); }
    | ID DIVASGN expr { check_symbol($1); }
    | ID MODASGN expr { check_symbol($1); }
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
    | ID { check_symbol($1); }
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
	
    if(!syntax_error_flag){
        dump_symbol();
        display_dump();

        printf("\nTotal lines: %d \n",yylineno);
    }
    
    return 0;
}

void yyerror(char *s)
{
    if(!strcmp(s, "syntax error")){
        printf("%d: %s\n", yylineno + 1, buf); 
        printf("\n|-----------------------------------------------|\n");
        printf("| Error found in line %d: %s\n", yylineno + 1, buf);
        printf("| %s", s);
        printf("\n|-----------------------------------------------|\n\n");

        syntax_error_flag = 1;
    }
    else{
        strncpy(err_msg, s, strlen(s));
        error_flag = 1;
    }
    
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

    //printf("Create symbol table of level: %d\n", p->level);
}
void insert_symbol(const char* name, const char* entry_type, 
                  const char* data_type, const char* attributes, const int prev) {
    
    
    if(!lookup_symbol(name, level-prev)){
        //printf("Inserting symbol / %s / %s / %s / %s /\n", name, entry_type, data_type, attributes);
        sym_node_ptr p = calloc(1, sizeof(sym_node));

        strncpy(p->name, name, MAX_NAME-1);
        strncpy(p->entry_type, entry_type, 11);
        strncpy(p->data_type, data_type, 9);
        p->level = level - prev;
        strncpy(p->attributes, attributes, MAX_ATTRI-1);

        p->next = NIL;
        int prev_level = prev;
        sym_tab_ptr tab = SYM_TAB;
        while(prev_level){
            tab = tab->next;
            prev_level --;
        }
        sym_node_ptr pos = tab->first;

        // Originally empty
        if(pos == NIL){
            tab->first = p;
        }

        // Originally not empty
        else{
            while(pos->next != NIL){
                pos = pos->next;
            }
            pos->next = p;
        }
    }

    // printf("Inserted symbol %s done\n", name);
}

void check_symbol(const char* name){

    int found = 0;
    sym_tab_ptr cur = SYM_TAB;
    while(cur != NIL){
        //printf("Lookup %d level...\n", cur->level);
        sym_node_ptr p = cur->first;
        while( p != NIL){
            if(!strcmp(name, p->name)){
                found = 1;
            }
            p = p->next;
        }

        cur = cur->next;
    }
    if(!found){
        char msg[128] = {'\0'};
        sprintf(msg, "Undeclared variable %s", name);
        yyerror(msg);
    }

}

int lookup_symbol(const char* name, const int lvl) {
    // Return 0 if symbol not found
    // Return 1 if symbol found

    sym_tab_ptr cur = SYM_TAB;
    while(cur != NIL){
        //printf("Lookup %d level...\n", cur->level);
        sym_node_ptr p = cur->first;
        while( p != NIL){
            if(!strcmp(name, p->name) && lvl==p->level){
                char msg[128] = {'\0'};
                sprintf(msg, "Redeclared variable %s", name);
                yyerror(msg);
                return 1;
            }
            p = p->next;
        }

        cur = cur->next;
    }
    return 0;
}
void dump_symbol() {

    printf("\n Dumping symbol table of level: %d\n", SYM_TAB->level);

    // Symbol table from head
    DUMP_SYM = SYM_TAB;    
    dump_flag = 1;
    // Remove symbol table from head
    SYM_TAB = SYM_TAB->next;

}

void display_dump(){
    sym_node_ptr p = DUMP_SYM->first;
    if(p == NIL){
        // printf("Empty symbol table!\n");
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

        printf("\n");
    }

    free(DUMP_SYM);
    DUMP_SYM = NIL;
    dump_flag = 0;
}
