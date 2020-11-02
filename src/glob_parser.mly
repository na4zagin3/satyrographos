%parameter<Semantics : sig
  type glob
  val star: glob
  val atom: string -> glob
  val range: int -> int -> glob
  val slash: string -> glob -> glob
  val alt: glob list -> glob

  type selector
  val slash_select: string -> selector -> selector
  val selectors: (bool * glob) list -> selector
end>

%start<Semantics.selector> main

%{
  open Semantics
%}

%%

main:
  | exprs EOF { $1 }


exprs:
  | e = expr es = list( COMMA expr { $2 }) { selectors (e :: es) }
  | xs = list( ATOM SLASH { $1 }) LBRACE g = exprs RBRACE
    {
      List.fold_right slash_select xs g
    }

expr:
  | PLUS g = glob { true, g }
  | MINUS g = glob { false, g }

glob:
  | STAR { star }
  | x = ATOM { atom x }
  | r = NUM_RANGE { range (fst r) (snd r) }
  | LBRACE gs = globList RBRACE { alt gs }
  | x = ATOM SLASH g = glob { slash x g }

globList:
  | g = glob { [g] }
  | g = glob COMMA gs = globList { g :: gs }
