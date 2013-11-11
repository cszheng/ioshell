%{/* bison parser for iosh */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/resource.h>
#include "globals.h"
#include "y.tab.h"

extern int errno;

command* addArg(char* arg, command* curCmd);
command* newCommand(void);
command* setPromptCmd(command* curCmd);
command* setDebugCmd(command* curCmd);
command* quitCmd();
command* chdirCmd(command* curCmd);
void run(command* curCmd);

int yylex(void);
void yyerror(char* s);
%}

%union{
	char* string_val;
	command* command_val;
};
%start shell

%token <string_val> WORD
%token <string_val> STRING
%token NEWLINE
%token COMMENT
%token SETPROMPT
%token DEBUG
%token CHDIR
%token QUIT
%token '<'
%token '>'

%type <command_val> builtin
%type <command_val> args

%%
shell:	        shell builtin NEWLINE {run($2); printf("%s%% ", prompt);}
		| shell COMMENT {printf("%s%% ", prompt);}
		|
		;
builtin: 	SETPROMPT args {$$ = setPromptCmd($2);}
		| DEBUG args {$$ = setDebugCmd($2);}
		| CHDIR args {$$ = chdirCmd($2);}
		| QUIT {$$ = quitCmd();}
		;
args:		args WORD {$$ = addArg($2, $1);}
		| args STRING {$$ = addArg($2, $1);}
		| {$$ = newCommand();}
		;
%%
void run(command* curCmd){
	switch(curCmd -> commandType){
		case SETPROMPTCMD:
		{	
			if(debug_flag)
			{
				printf("Token Type = word\t  Token = setprompt\t Usage = setprompt\n");
				printf("Token Type = string\t  Token = %s\t Usage = string\n", curCmd->argStart->arg);
				printf("Token Type = end-of-line  Token = EOL\t\t Usage = EOL\n");
			}

			free(prompt);
			prompt = strdup(curCmd->argStart->arg);
		}
			break;
		case QUITCMD:
		{
			if(debug_flag)
			{
				printf("Token Type = word\t  Token = quit\t Usage = quit\n");
				printf("Token Type = end-of-line  Token = EOL\t Usage = EOL\n");
			}

			printf("quitting shell\n");
			exit(0);
		}
			break;
		case CHDIRCMD:
		{
			if(debug_flag)
			{
				printf("Token Type = word\t  Token = chdir\t Usage = chdir\n");
				printf("Token Type = word\t  Token = %s\t Usage = word\n", curCmd->argStart->arg);
				printf("Token Type = end-of-line  Token = EOL\t Usage = EOL\n");  

			}
			int chdirErr = chdir(curCmd->argStart->arg);	
			if(chdirErr == -1){
				printf("An error occured with changing directory\n");			
			}
		}
			break;
		case SETDEBUGCMD:
			if(strcmp("on", curCmd->argStart->arg)==0){
				debug_flag = true;
				printf("debug turned on\n");
			}
			else if(strcmp("off", curCmd->argStart->arg)==0){
				debug_flag = false;
				printf("debug turned off\n");
			}
			else{
				printf("Debug mode must be set to either \"on\" or \"off\". %s is not valid.\n", curCmd->argStart->arg);
			} 
			break;
		case EXECPROGCMD:
			break;
	}
}

command* newCommand(){
	command* newCommand = malloc(sizeof(command));
	newCommand->command = NULL;
	newCommand->commandType = 0;
	newCommand->inputFrom = NULL;
	newCommand->outputTo = NULL;
	newCommand->argStart = NULL;
	newCommand->argc = 0;
	return newCommand;
}

command* addArg(char* arg, command* curCmd){
	arglist* argPtr;
	if(curCmd->argc == 0){
		argPtr = malloc(sizeof(arglist));
		char* newArg = strdup(arg);
		argPtr->arg = newArg;
		argPtr->next = NULL;
		curCmd->argStart=argPtr;
		curCmd->argc=1;				
	}
	else{	
		argPtr = curCmd->argStart;
		while(argPtr->next != NULL){
			argPtr = argPtr->next;
		}
		arglist* newArgList = malloc(sizeof(arglist));
		char* newArg = strdup(arg);
		newArgList->arg = newArg;
		newArgList->next = NULL;
		argPtr->next = newArgList;
		curCmd->argc++;
	}	

	return curCmd;	
}

command* setPromptCmd(command* curCmd){
	curCmd->commandType = SETPROMPTCMD;
	return curCmd;
}

command* setDebugCmd(command* curCmd){
	curCmd->commandType = SETDEBUGCMD;
	return curCmd;
}

command* chdirCmd(command* curCmd){
	curCmd->commandType = CHDIRCMD;
	return curCmd;
}

command* quitCmd(){
	command* quitCommand = malloc(sizeof(command));
	quitCommand->command = NULL;
	quitCommand->commandType = QUITCMD;
	quitCommand->inputFrom = NULL;
	quitCommand->outputTo = NULL;
	quitCommand->argStart = NULL;
	quitCommand->argc = 0;
	return quitCommand;
}

int main(void){
	prompt = strdup("iosh");
	printf("%s%% ", prompt);	
	yyparse();
	free(prompt);
	return 0;
}
	
void yyerror(char* s)
{
        printf("%s\n",s);
        printf("%s%% ",prompt);
        yyparse();
        return;
}