%{
 open Netlist_ast

 let value_of_int n =
   let rec aux n =
     let b =
       match n mod 10 with
         | 0 -> false
         | 1 -> true
         | i -> Format.eprintf "Unexpected: %d@." i; raise Parsing.Parse_error
     in
     if n < 10 then
       [b]
     else
       b::(aux (n / 10))
   in
   match aux n with
     | [] -> Format.eprintf "Empty list@."; raise Parsing.Parse_error
     | [b] -> VBit b
     | bl -> VBitArray (List.rev bl)

 let env_of_vars l =
   List.fold_left (fun env (x, ty) -> Env.add x ty env) Env.empty l
%}

%token <int> INT
%token <string> NAME
%token AND MUX NAND OR RAM ROM XOR REG NOT
%token CONCAT SELECT SLICE
%token COLON EQUAL COMMA VAR IN
%token EOF

%start program             /* the entry point */
%type <Netlist_ast.program> program

%%
program:
  VAR vars=separated_list(COMMA, var) IN eqs=list(equ) EOF
    { { p_eqs = eqs; p_vars = env_of_vars vars } }

equ:
  x=NAME EQUAL e=exp { (x, e) }

exp:
  | n=INT { Econst (value_of_int n) }
  | NOT x=arg { Enot x }
  | REG x=NAME { Ereg x }
  | AND x=arg y=arg { Ebinop(And, x, y) }
  | OR x=arg y=arg { Ebinop(Or, x, y) }
  | NAND x=arg y=arg { Ebinop(Nand, x, y) }
  | XOR x=arg y=arg { Ebinop(Xor, x, y) }
  | MUX x=arg y=arg z=arg { Emux(x, y, z) }
  | ROM addr=INT word=INT ra=arg
    { Erom(addr, word, ra) }
  | RAM addr=INT word=INT ra=arg we=arg wa=arg data=arg
    { Eram(addr, word, ra, we, wa, data) }
  | CONCAT x=arg y=arg
     { Econcat(x, y) }
  | SELECT idx=INT x=arg
     { Eselect (idx, x) }
  | SLICE min=INT max=INT x=arg
     { Eslice (min, max, x) }

arg:
  | n=INT { Aconst (value_of_int n) }
  | id=NAME { Avar id }

var: x=NAME ty=ty_exp { (x, ty) }
ty_exp:
  | /*empty*/ { TBit }
  | COLON n=INT { TBitArray n }