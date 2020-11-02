{
  open Glob_tokens
  exception GlobRangeError of string
}

let num_char = ['0'-'9']
let id_char_first = ['0'-'9' 'A'-'Z' 'a'-'z']
let id_char = id_char_first | ['_' '-' '.']

rule token = parse
  | "*" { STAR }
  | "/" { SLASH }
  | "{" { LBRACE }
  | "}" { RBRACE }
  | "," { COMMA }
  | (num_char+ as n1) ".." (num_char+ as n2)
    {
      let n1 = int_of_string n1 in
      let n2 = int_of_string n2 in
      if n1 < n2
      then NUM_RANGE(n1, n2)
      else raise (GlobRangeError(Printf.sprintf "Range %d..%d should be ascending order." n1 n2))
    }
  | id_char_first id_char* as lexeme { ATOM(lexeme) }
  | "-" { MINUS }
  | "+" { PLUS }
  | eof { EOF }
  | _ { raise (Failure (Printf.sprintf "unknown token: %s" (Lexing.lexeme lexbuf))) }
