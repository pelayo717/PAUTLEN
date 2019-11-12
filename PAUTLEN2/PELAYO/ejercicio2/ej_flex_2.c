#include <stdio.h>
#include <stdlib.h>
#include "tokens.h"

extern int yylex();
extern FILE *yyin;
extern char yytext[];
FILE * salida;

int main(int argc, char** argv){

	int valor_patron=0;

	if(argc < 3){
		printf("Error en los parametros ==>> ./ejecutable fichero_entrada fichero_salida");
		return -1;
	}

	yyin = fopen(argv[1], "r");
	salida = fopen(argv[2],"w+");

	while((valor_patron = yylex()) != 0){

		switch(valor_patron){
			
			case TOK_MAIN:
				fprintf(salida,"TOK_MAIN %d\n", valor_patron);
				break;

			case TOK_INT:
				fprintf(salida,"TOK_INT %d\n", valor_patron);
				break;

			case TOK_ARRAY:
				fprintf(salida,"TOK_ARRAY %d\n", valor_patron);
				break;

			case TOK_IF:
				fprintf(salida,"TOK_IF %d\n", valor_patron);
				break;
	
			case TOK_ELSE:
				fprintf(salida,"TOK_ELSE %d\n", valor_patron);
				break;

			case TOK_WHILE:
				fprintf(salida,"TOK_WHILE %d\n", valor_patron);
				break;

			case TOK_PUNTOYCOMA:
				fprintf(salida,"TOK_PUNTOYCOMA %d\n", valor_patron);
				break;

			case TOK_PARENTESISIZQUIERDO:
				fprintf(salida,"TOK_PARENTESISIZQUIERDO %d\n", valor_patron);
				break;

			case TOK_PARENTESISDERECHO:
				fprintf(salida,"TOK_PARENTESISDERECHO %d\n", valor_patron);
				break;

			case TOK_ASTERISCO:
				fprintf(salida,"TOK_ASTERISCO %d\n", valor_patron);
				break;

			case TOK_MAS:
				fprintf(salida,"TOK_MAS %d\n", valor_patron);
				break;

			case TOK_MENORIGUAL:
				fprintf(salida,"TOK_MENORIGUAL %d\n", valor_patron);
				break;

			default:
				printf("\nError producido detectando una expresion");

		}
	}

	fclose(salida);
	fclose(yyin);
	return 0;


}
