%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    
    #include "alfa.h"
    #include "tablaSimbolos.h"
    #include "tablaHash.h"
    #include "generacion.h"

    void yyerror(const char* err);
    extern int line, col, error;
    extern FILE *yyin;
    extern FILE *yyout;
    extern int yylex();
    extern int yyleng;

    /*variables para conocer el estado actual del simbolo*/
    TIPO tipo_actual;
    CLASE clase_actual;
    INFO_SIMBOLO * aux;

    /*Ambito global y local*/
    extern TABLA_HASH * tablaSimbolosLocal;
    extern TABLA_HASH * tablaSimbolosGlobal;

    /*Otra informacion*/
    int tamanio_vector_actual=0; //Tamanio del vector
    int pos_variable_local_actual=1; //Posicion de variable global en ambitos de variables locales
    int num_variables_locales_actual=0;
    int cuantos_no=0;
    char aux_char[100];
    int en_explist=0;

    /*Parametros*/
    int num_parametros_actual=0;

%}
%union
        {
            tipo_atributos atributos;
        }


/*Simbolos no terminales con valor semantico*/

%type <atributos> condicional
%type <atributos> comparacion
%type <atributos> elemento_vector
%type <atributos> exp
%type <atributos> constante
%type <atributos> constante_entera
%type <atributos> constante_logica
%type <atributos> identificador

/*Simbolos terminales con valor semantico*/

%token <atributos> TOK_CONSTANTE_ENTERA
%token <atributos> TOK_CONSTANTE_REAL
%token <atributos> TOK_IDENTIFICADOR

/*Simbolos terminales sin valor semantico*/

%token TOK_MAIN
%token TOK_INT
%token TOK_BOOLEAN
%token TOK_ARRAY
%token TOK_FUNCTION
%token TOK_IF
%token TOK_ELSE
%token TOK_WHILE
%token TOK_SCANF
%token TOK_PRINTF
%token TOK_RETURN
%token TOK_PUNTOYCOMA
%token TOK_COMA
%token TOK_PARENTESISIZQUIERDO
%token TOK_PARENTESISDERECHO
%token TOK_CORCHETEIZQUIERDO
%token TOK_CORCHETEDERECHO
%token TOK_LLAVEIZQUIERDA
%token TOK_LLAVEDERECHA
%token TOK_ASIGNACION
%token TOK_MAS
%token TOK_MENOS
%token TOK_DIVISION
%token TOK_ASTERISCO
%token TOK_AND
%token TOK_OR
%token TOK_NOT
%token TOK_IGUAL
%token TOK_DISTINTO
%token TOK_MENORIGUAL
%token TOK_MAYORIGUAL
%token TOK_MENOR
%token TOK_MAYOR
%token TOK_TRUE
%token TOK_FALSE
%token TOK_ERROR

%left TOK_ASIGNACION
%left TOK_AND TOK_OR
%left TOK_IGUAL TOK_DISTINTO
%left TOK_MAYOR TOK_MENOR TOK_MAYORIGUAL TOK_MENORIGUAL
%left TOK_MAS TOK_MENOS
%left TOK_DIVISION TOK_ASTERISCO
%left TOK_NOT MENOSU
%left TOK_PARENTESISIZQUIERDO TOK_PARENTESISDERECHO TOK_CORCHETEIZQUIERDO TOK_CORCHETEDERECHO

%start programa

%%
programa: TOK_MAIN TOK_LLAVEIZQUIERDA inicio declaraciones escritura1 funciones escritura2 sentencias fin TOK_LLAVEDERECHA {fprintf(stdout, ";R1:\t<programa> ::= main { <declaraciones> <funciones> <sentencias> }\n");}
;

inicio:{
    CrearTablaGlobal();
    escribir_subseccion_data(yyout);
    escribir_cabecera_bss(yyout);
}

fin:{
    escribir_fin(yyout);
    LimpiarTablas();
}

escritura1:{
    INFO_SIMBOLO * totales = tablaSimbolosGlobal->simbolos;
    while(totales != NULL){

        if(totales->categoria == VARIABLE){
            if(totales->tipo == INT) {
                declarar_variable(yyout,totales->lexema,ENTERO,(totales->clase == VECTOR) ? totales->adicional1 : 1);
            }else if(totales->tipo == BOOLEAN){
                declarar_variable(yyout,totales->lexema,BOOLEANO,(totales->clase == VECTOR) ? totales->adicional1 : 1);
            }
        }

        totales = totales->siguiente;
    }

    escribir_segmento_codigo(yyout);
}

escritura2:{
    escribir_inicio_main(yyout);
}

declaraciones: declaracion {fprintf(stdout, ";R2:\t<declaraciones> ::= <declaracion>\n");}
            | declaracion declaraciones {fprintf(stdout, ";R3:\t<declaraciones> ::= <declaracion> <declaraciones>\n");}
;

declaracion: clase identificadores TOK_PUNTOYCOMA {fprintf(stdout, ";R4:\t<declaracion> ::= <clase> <identificadores> ;\n");}
;

clase: clase_escalar {clase_actual=ESCALAR; fprintf(stdout, ";R5:\t<clase> ::= <clase_escalar>\n");}
    | clase_vector {clase_actual=VECTOR; fprintf(stdout, ";R7:\t<clase> ::= <clase_vector>\n");}
;

clase_escalar: tipo {fprintf(stdout, ";R9:\t<clase_escalar> ::= <tipo>\n");}
;

tipo: TOK_INT {tipo_actual=INT; fprintf(stdout, ";R10:\t<tipo> ::= int\n");}
    | TOK_BOOLEAN {tipo_actual=BOOLEAN; fprintf(stdout, ";R11:\t<tipo> ::= boolean\n");}
;

clase_vector: TOK_ARRAY tipo TOK_CORCHETEIZQUIERDO TOK_CONSTANTE_ENTERA TOK_CORCHETEDERECHO {


    tamanio_vector_actual = $4.valor_entero;
    if((tamanio_vector_actual < 1) || (tamanio_vector_actual > MAX_TAMANIO_VECTOR)){
        printf("****Error Semantico en la linea %d: tamanio array superior al permitido\n", line);
        return -1;
    }

    fprintf(stdout, ";R15:\t<clase_vector> ::= array <tipo> [ <constante_entera> ]\n");
};

identificadores: identificador {fprintf(stdout, ";R18:\t<identificadores> ::= <identificador>\n");}
            | identificador TOK_COMA identificadores {fprintf(stdout, ";R19:\t<identificadores> ::= <identificador> , <identificadores>\n");}
;

funciones: funcion funciones {fprintf(stdout, ";R20:\t<funciones> ::= <funcion> <funciones>\n");}
        | /* LAMBDA */ {fprintf(stdout, ";R21:\t<funciones> ::=\n");}
;

funcion: TOK_FUNCTION tipo identificador TOK_PARENTESISIZQUIERDO parametros_funcion TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA declaraciones_funcion sentencias TOK_LLAVEDERECHA {fprintf(stdout, ";R22:\t<funcion> ::= function <tipo> <identificador> ( <parametros_funcion> ) { <declaraciones_funcion> <sentencias> }\n");}
;

parametros_funcion: parametro_funcion resto_parametros_funcion {fprintf(stdout, ";R23:\t<parametros_funcion> ::= <parametro_funcion> <resto_parametros_funcion>\n");}
                | /* LAMBDA */ {fprintf(stdout, ";;R24:\t<parametros_funcion> ::=\n");}
;

resto_parametros_funcion: TOK_PUNTOYCOMA parametro_funcion resto_parametros_funcion {fprintf(stdout, ";R25:\t <resto_parametros_funcion> ::= ; <parametro_funcion> <resto_parametros_funcion>\n");}
                        | /* LAMBDA */ {fprintf(stdout, ";R26:\t<resto_parametros_funcion> ::=\n");}
;

parametro_funcion: tipo identificador {fprintf(stdout, ";R27:\t<parametro_funcion> ::= <tipo> <identificador>\n");}
;

declaraciones_funcion: declaraciones {fprintf(stdout, ";R28:\t<declaraciones_funcion> ::= <declaraciones>\n");}
                    | /* LAMBDA */ {fprintf(stdout, ";R29:\t<declaraciones_funcion> ::=\n");}
;

sentencias: sentencia {fprintf(stdout, ";R30:\t<sentencias> ::= <sentencia>\n");}
        | sentencia sentencias {fprintf(stdout, ";R31:\t<sentencias> ::= <sentencia> <sentencias>\n");}
;

sentencia: sentencia_simple TOK_PUNTOYCOMA {fprintf(stdout, ";R32:\t<sentencia> ::= <sentencia_simple> ;\n");}
            | bloque {fprintf(stdout, ";R33:\t<sentencia> ::= <bloque>\n");}
;
sentencia_simple: asignacion {fprintf(stdout, ";R34:\t<sentencia_simple> ::= <asignacion>\n");}
                | lectura {fprintf(stdout, ";R35:\t<sentencia_simple> ::= <lectura>\n");}
                | escritura {fprintf(stdout, ";R36:\t<sentencia_simple> ::= <escritura>\n");}
                | retorno_funcion {fprintf(stdout, ";R38:\t<sentencia_simple> ::= <retorno_funcion>\n");}
;

bloque: condicional {fprintf(stdout, ";R40:\t<bloque> ::= <condicional>\n");}
    | bucle {fprintf(stdout, ";R41:\t<bloque> ::= <bucle>\n");}
;

asignacion: TOK_IDENTIFICADOR TOK_ASIGNACION exp {

    aux = UsoLocal($1.lexema);
    if(aux == NULL){ fprintf(stdout,"Error Semantico en la linea %d: No existe la variable a asignar\n",line);
    return -1;}
    if(aux->categoria == FUNCION){ fprintf(stdout,"Error Semantico en la linea %d: La variable es de categoria FUNCION\n",line);
    return -1;}
    if(aux->clase == VECTOR){ fprintf(stdout,"Error Semantico en la linea %d: La variable es de clase VECTOR\n",line);
    return -1;}
    if(aux->tipo != $3.tipo){ fprintf(stdout,"Error Semantico en la linea %d: La asignacion es de tipos distintos\n",line);
    return -1;}

    /*quiere decir que es global*/
    if(UsoExclusivoLocal($1.lexema) == NULL){
        asignar(yyout,$1.lexema,$3.direcciones);
    

    /*quiere decir que es parametro*/
    }else if(aux->categoria == PARAMETRO){
        escribir_operando(yyout,$3.lexema,$3.direcciones?0:1);
        escribirParametro(yyout,aux->adicional2,num_parametros_actual);
        asignarDestinoEnPila(yyout,$3.direcciones);

    /*quiere decir que es local*/
    }else{
        escribir_operando(yyout,$3.lexema,$3.direcciones?0:1);
        escribirVariableLocal(yyout,aux->adicional2);
        asignarDestinoEnPila(yyout,$3.direcciones);
    }

fprintf(stdout, ";R43:\t<asignacion> ::= <identificador> = <exp>\n");

}
        | elemento_vector TOK_ASIGNACION exp {

        aux = UsoLocal($1.lexema);
        if(aux == NULL){ fprintf(stdout,"Error Semantico en la linea %d: No existe la variable a asignar\n",line);
        return -1;}
        if(aux->tipo != $3.tipo){
        fprintf(stdout,"Error Semantico en la linea %d: La asignacion es de tipos distintos\n",line);
        return -1;
        }

        escribir_elemento_vector(yyout,$1.lexema,MAX_TAMANIO_VECTOR,$1.direcciones);
        asignar(yyout,$1.lexema,$3.direcciones);

        fprintf(stdout, ";R44:\t<asignacion> ::= <elemento_vector> = <exp>\n");

};

elemento_vector: identificador TOK_CORCHETEIZQUIERDO exp TOK_CORCHETEDERECHO {fprintf(stdout, ";R48:\t<elemento_vector> ::= <identificador> [ <exp> ]\n");}
;

condicional: TOK_IF TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA {fprintf(stdout, ";R50:\t<condicional> ::= if ( <exp> ) { <sentencias> }\n");}
        | TOK_IF TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEIZQUIERDA TOK_ELSE TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA {fprintf(stdout, ";R51:\t<condicional> ::= if ( <exp> ) { <sentencias> } else { <sentencias> }\n");}
;

bucle: TOK_WHILE TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO TOK_LLAVEIZQUIERDA sentencias TOK_LLAVEDERECHA {fprintf(stdout, ";R52:\t<bucle> ::= while ( <exp> ) { <sentencias> }\n");}
;

lectura: TOK_SCANF TOK_IDENTIFICADOR {
      if(tablaSimbolosLocal != NULL){ //HAY AMBITO LOCAL

        aux = UsoExclusivoLocal($2.lexema);

        if(aux != NULL){
            if(aux->categoria == FUNCION){
                printf("****Error Semantico en la linea %d: Variable declarada como funcion\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                printf("****Error Semantico en la linea %d: Variable declarada como vector\n", line);
                return -1;
            }

            /*LEER SI ES UN PARAMETRO*/
            if(aux->categoria == PARAMETRO){
                //escribirParametro(yyout,aux->adicional2,num_parametros_actual);
            }else{/*LEER SI ES UNA LOCAL*/

            }

            

        }else{
            
            aux = UsoGlobal($2.lexema);

            if(aux != NULL){
                if(aux->categoria == FUNCION){
                    printf("****Error Semantico en la linea %d: Variable declarada como funcion\n", line);
                    return -1;
                }

                if(aux->clase == VECTOR){
                    printf("****Error Semantico en la linea %d: Variable declarada como vector\n", line);
                    return -1;
                }

                if(aux->tipo == INT){
                    leer(yyout,$2.lexema,0);
                }else if(aux->tipo == BOOLEAN){
                    leer(yyout,$2.lexema,1);
                }


            }else{
                printf("****Error Semantico en la linea %d: LLamada a la variable %s sin declarar\n", line, $2.lexema);
                return -1;
            }
        }

    }else{

        aux = UsoGlobal($2.lexema);

        if(aux != NULL){
            if(aux->categoria == FUNCION){
                printf("****Error Semantico en la linea %d: Variable declarada como funcion\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                printf("****Error Semantico en la linea %d: Variable declarada como vector\n", line);
                return -1;
            }

            if(aux->tipo == INT){
                leer(yyout,$2.lexema,0);
            }else if(aux->tipo == BOOLEAN){
                leer(yyout,$2.lexema,1);
            }


        }else{
            printf("****Error Semantico en la linea %d: LLamada a la variable %s sin declarar\n", line, $2.lexema);
            return -1;
        }

    }

    fprintf(stdout, ";R54:\t<lectura> ::= scanf <identificador>\n");
}
;

escritura: TOK_PRINTF exp {
    if($2.tipo == INT){
        escribir(yyout,$2.direcciones,0);    
    }else{
        escribir(yyout,$2.direcciones,1);
    }

fprintf(stdout, ";R56:\t<escritura> ::= printf <exp>\n");

};

retorno_funcion: TOK_RETURN exp {fprintf(stdout, ";R61:\t<retorno_funcion> ::= return <exp>\n");}
;

exp: exp TOK_MAS exp {
    
    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        sumar(yyout,$1.direcciones,$3.direcciones);

    }else{
        printf("****Error Semantico en la linea %d: Suma de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R72:\t<exp> ::= <exp> + <exp>\n");

}
    | exp TOK_MENOS exp {

    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        restar(yyout,$1.direcciones,$3.direcciones);

    }else{
        printf("****Error Semantico en la linea %d: Resta de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R73:\t<exp> ::= <exp> - <exp>\n");

}
    | exp TOK_DIVISION exp {

    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        dividir(yyout, $1.direcciones, $3.direcciones);

    }else{
        printf("****Error Semantico en la linea %d: Division de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R74:\t<exp> ::= <exp> / <exp>\n");

}
    | exp TOK_ASTERISCO exp {

    if($1.tipo == INT && $3.tipo == INT){

        $$.tipo = INT;
        $$.direcciones = 0;

        multiplicar(yyout,$1.direcciones,$3.direcciones);

    }else{
        printf("****Error Semantico en la linea %d: Multiplicacion de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R75:\t<exp> ::= <exp> * <exp>\n");


}
    | TOK_MENOS exp %prec MENOSU {


    if($2.tipo == INT){
        $$.tipo = INT;
        $$.direcciones = 0;

        cambiar_signo(yyout,$2.direcciones);
    }else{
        printf("****Error Semantico en la linea %d: Cambio de signo en variable que no es de tipo INT\n", line);
        return -1;
    }

    fprintf(stdout, ";R76:\t<exp> ::= - <exp>\n");

}
    | exp TOK_AND exp {

    if($1.tipo == BOOLEAN && $3.tipo == BOOLEAN){

        $$.tipo = BOOLEAN;
        $$.direcciones = 0;

        y(yyout,$1.direcciones,$3.direcciones);

    }else{
        printf("****Error Semantico en la linea %d: And de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R77:\t<exp> ::= <exp> && <exp>\n");
}
    | exp TOK_OR exp {

    if($1.tipo == BOOLEAN && $3.tipo == BOOLEAN){

        $$.tipo = BOOLEAN;
        $$.direcciones = 0;

        o(yyout,$1.direcciones,$3.direcciones);

    }else{
        printf("****Error Semantico en la linea %d: Or de variables de distinto tipo\n", line);
        return -1;
    }

    fprintf(stdout, ";R78:\t<exp> ::= <exp> || <exp>\n");
}
    | TOK_NOT exp {

    if($2.tipo == BOOLEAN){
        $$.tipo = BOOLEAN;
        $$.direcciones = 0;

        no(yyout,$2.direcciones,cuantos_no);
        cuantos_no++;

    }else{
        printf("****Error Semantico en la linea %d: Negacion de variable que no es de tipo BOOLEAN\n",line);
        return -1;
    }

    fprintf(stdout, ";R79:\t<exp> ::= ! <exp>\n");
}
    | TOK_IDENTIFICADOR {

    strcpy($$.lexema,$1.lexema);

    if(tablaSimbolosLocal != NULL){
        aux = UsoExclusivoLocal($1.lexema);
        if(aux != NULL){ //BUSQUEDA EN LOCAL
            if(aux->categoria == FUNCION){
                printf("****Error Semantico en la linea %d: Variable no es de la categoria correspondiente\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                printf("****Error Semantico en la linea %d: Variable no es de la clase correspondiente\n", line);
                return -1;
            }

            $$.tipo = aux->tipo;
            $$.direcciones = 1;

            if(aux->categoria == VARIABLE){
                escribirVariableLocal(yyout,aux->adicional2);
            }else if(aux->categoria == PARAMETRO){
                escribirParametro(yyout,aux->adicional2,num_parametros_actual);
                operandoEnPilaAArgumento(yyout,$1.direcciones);
            }
        }else{
            //ERROR VARIANLE
        }
        
    }else{ //BUSQUEDA EN GLOBAL

        aux =  UsoGlobal($1.lexema);
        if(aux != NULL){
            if(aux->categoria == FUNCION){
                printf("****Error Semantico en la linea %d: Variable no es de la categoria correspondiente\n", line);
                return -1;
            }

            if(aux->clase == VECTOR){
                printf("****Error Semantico en la linea %d: Variable no es de la clase correspondiente\n", line);
                return -1;
            }

            $$.tipo = aux->tipo;
            $$.direcciones = 1;

            if(en_explist==0){
                escribir_operando(yyout,$1.lexema,1); //Direccion
            }else{
                escribir_operando(yyout,$1.lexema,1); //Direccion
                operandoEnPilaAArgumento(yyout,$1.direcciones); //Valor
            }

            /*if(aux->categoria == VARIABLE){
                escribirVariableLocal(yyout,aux->adicional2);
            }else if(aux->categoria == PARAMETRO){
                escribirParametro(yyout,aux->adicional2,num_parametros_actual);
            }*/

            escribir_operando(yyout,$1.lexema,$1.direcciones?0:1);
        }else{
            printf("****Error Semantico en la linea %d: LLamada a variable sin definir\n", line);
            return -1;
        }

    }


    fprintf(stdout, ";R80:\t<exp> ::= <identificador>\n");

}
    | constante {

    snprintf(aux_char, sizeof(aux_char), "%d", $1.valor_entero);
    escribir_operando(yyout,aux_char,$1.direcciones);
    $$.tipo = $1.tipo;
    $$.direcciones = $1.direcciones;

    fprintf(stdout, ";R81:\t<constante>\n");

}
    | TOK_PARENTESISIZQUIERDO exp TOK_PARENTESISDERECHO {

    $$.tipo = $2.tipo;
    $$.direcciones = $2.direcciones;

    fprintf(stdout, ";R82:\t<exp> ::= ( <exp> )\n");

}
    | TOK_PARENTESISIZQUIERDO comparacion TOK_PARENTESISDERECHO {

    $$.tipo = $2.tipo;
    $$.direcciones = $2.direcciones;

    fprintf(stdout, ";R83:\t<exp> ::= ( <comparacion> )\n");

}
    | elemento_vector {

    $$.tipo = $1.tipo;
    $$.direcciones = $1.direcciones;

    fprintf(stdout, ";R85:\t<exp> ::= <elemento_vector>\n");

}
    | TOK_IDENTIFICADOR TOK_PARENTESISIZQUIERDO lista_expresiones TOK_PARENTESISDERECHO {
    
    fprintf(stdout, ";R88:\t<exp> ::= <identificador> ( <lista_expresiones> )\n");

};


lista_expresiones: exp resto_lista_expresiones {fprintf(stdout, ";R89:\t<lista_expresiones> ::= <exp> <resto_lista_expresiones>\n");}
                | /* LAMBDA */ {fprintf(stdout, ";R90:\t<lista_expresiones> ::=\n");}
;

resto_lista_expresiones: TOK_COMA exp resto_lista_expresiones {fprintf(stdout, ";R91:\t<resto_lista_expresiones> ::= , <exp> <resto_lista_expresiones>\n");}
                    | /* LAMBDA */ {fprintf(stdout, ";R92:\t<resto_lista_expresiones> ::=\n");}
;

comparacion: exp TOK_IGUAL exp {fprintf(stdout, ";R93:\t<comparacion> ::= <exp> == <exp>\n");}
        | exp TOK_DISTINTO exp {fprintf(stdout, ";R94:\t<comparacion> ::= <exp> != <exp>\n");}
        | exp TOK_MENORIGUAL exp {fprintf(stdout, ";R95:\t<comparacion> ::= <exp> <= <exp>\n");}
        | exp TOK_MAYORIGUAL exp {fprintf(stdout, ";R96:\t<comparacion> ::= <exp> >= <exp>\n");}
        | exp TOK_MENOR exp {fprintf(stdout, ";R97:\t<comparacion> ::= <exp> < <exp>\n");}
        | exp TOK_MAYOR exp {fprintf(stdout, ";R98:\t<comparacion> ::= <exp> > <exp>\n");}
;

constante:
constante_logica{

    $$.tipo=$1.tipo;
    $$.direcciones=$1.direcciones;
    $$.valor_entero=$1.valor_entero;

    fprintf(stdout, ";R99:\t<constante> ::= <constante_logica>\n");

}| constante_entera {

    $$.tipo=$1.tipo;
    $$.direcciones=$1.direcciones;
    $$.valor_entero=$1.valor_entero;

    fprintf(stdout, ";R100:\t<constante> ::= <constante_entera>\n");
};

constante_logica: TOK_TRUE {$$.tipo=BOOLEAN; $$.direcciones=0; $$.valor_entero=1; fprintf(stdout, ";R102:\t<constante_logica> ::= true\n");}
                | TOK_FALSE {$$.tipo=BOOLEAN; $$.direcciones=0; $$.valor_entero=0; fprintf(stdout, ";R103:\t<constante_logica> ::= false\n");}
;

constante_entera: TOK_CONSTANTE_ENTERA {$$.tipo=INT; $$.direcciones=0; $$.valor_entero=$1.valor_entero; fprintf(stdout, ";R104:\t<constante_entera> ::= <numero>\n");}
;

identificador: TOK_IDENTIFICADOR {

fprintf(stdout, ";R108:\t<identificador> ::= TOK_IDENTIFICADOR\n");

if(tablaSimbolosLocal != NULL){ //EXISTE LA LOCAL
        aux = UsoExclusivoLocal($1.lexema);
        if(aux != NULL){ //YA EXISTE EL ELEMENTO
            //INDICARLO CON PRINT
            printf("****Error Semantico en linea %d: variable duplicada\n", line);
            return -1;
        }else{
            //INSERTARLO EN LA TABLA LOCAL MIRANDO QUE SU CLASE SEA ESCALAR
            if(clase_actual != ESCALAR){
                //ERROR DE DECLARACION, INDICAMOS
                printf("****Error Semantico en la linea %d: Variable local de tipo incorrecto\n",line);
                return -1;
            }else{
                //INSERTARLO EN LA TABLA LOCAL(Revisar parametros)
                if(DeclararLocal($1.lexema,VARIABLE,tipo_actual,clase_actual,0,pos_variable_local_actual) == OK){
                    pos_variable_local_actual++;
                    num_variables_locales_actual++;
                }else{
                    //ERROR INTERNO
                }
            }
        }
    }else{
        aux = UsoExclusivoGlobal($1.lexema);
        if(aux != NULL){ //YA EXISTE EL ELEMENTO
            //INDICARLO CON PRINT
            printf("****Error Semantico en la linea %d: variable duplicada\n", line);
            return -1;
        }else{
            //INSERTARLO EN LA TABLA GLOBAL(Revisar parametros)
            if(DeclararGlobal($1.lexema,VARIABLE,tipo_actual,clase_actual,tamanio_vector_actual,0) == OK){
                tamanio_vector_actual=0;
            }else{
                //ERROR INTERNO
            }
            
        }
    }
};

%%

void yyerror (const char* err){
        if(error == 0){
                fprintf(stdout,"****Error sintactico en [lin %d, col %d]\n", line, col-yyleng);
        }
        error = 0;
}