open Core

include BuildScript_prim

let load f =
  let sexp = Sexp.load_sexp ~strict:false f in
  match sexp with
  | Sexp.List Sexp.[Atom "version"; Atom "0.0.2"] ->
    BuildScript_0_0_2.load f
  | _ ->
    failwith {|Satyrographos file should start with a lang version specifier.

Add the following line to the file.

    (version 0.0.2)|}

