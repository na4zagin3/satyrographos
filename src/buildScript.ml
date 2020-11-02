open Core

include BuildScript_prim

let load f =
  let sexp = Sexp.load_sexp ~strict:false f in
  match sexp with
  | Sexp.List Sexp.[Atom "version"; Atom "0.0.2"] ->
    Script_0_0_2 (BuildScript_0_0_2.load f)
  | Sexp.List Sexp.[Atom "lang"; Atom "0.0.3"]
  | Sexp.List Sexp.[Atom "Lang"; Atom "0.0.3"] ->
    Format.fprintf Format.err_formatter "WARNING: Script lang 0.0.3 is under development.@.";
    Script_0_0_3 (BuildScript_0_0_3.load f)
  | _ ->
    failwith {|Satyrographos file should start with a lang version specifier.

Add one of the following lines to the file.

    (version 0.0.2)

    (lang 0.0.3)
|}

