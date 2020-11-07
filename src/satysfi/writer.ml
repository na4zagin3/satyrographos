open Core

let literal_string str =
  (* TODO Refactor with an elegant algorithm *)
  if String.contains str '\n'
  then failwithf "literal_string still does not support strings with newlines, but got: %S" str ();
  let consequent_backticks =
    let result = ref 0 in
    let current = ref 0 in
    String.iter str ~f:(fun c ->
      if Char.equal c '`'
      then begin
        current := !current + 1;
        if !current > !result
        then result := !current
      end
      else current := 0);
    !result in
  let leading_spaces =
    String.equal " " (String.prefix str 1) in
  let trailing_spaces =
    String.equal " " (String.suffix str 1) in
  let hash_if b = if b then "#" else "" in
  let quotes = String.init (consequent_backticks + 1) ~f:(fun _ -> '`') in
  if String.is_empty str
  then "` `"
  else hash_if leading_spaces ^ quotes ^ str ^ quotes ^ hash_if trailing_spaces

let%expect_test {|literal_string: empty|} =
   literal_string ""
   |> print_string;
   [%expect{| ` ` |} ]
let%expect_test {|literal_string: non-special chars|} =
   literal_string "abc"
   |> print_string;
   [%expect{| `abc` |} ]
let%expect_test {|literal_string: a leading space|} =
   literal_string " abc"
   |> print_string;
   [%expect{| #` abc` |} ]
let%expect_test {|literal_string: a trailing space|} =
   literal_string "abc "
   |> print_string;
   [%expect{| `abc `# |} ]
let%expect_test {|literal_string: leading and trailing spaces|} =
   literal_string "   abc  "
   |> print_string;
   [%expect{| #`   abc  `# |} ]
let%expect_test {|literal_string: backticks|} =
   literal_string "abc``de`"
   |> print_string;
   [%expect{| ```abc``de```` |} ]


let literal_simple ppf = function
  | `Float i -> Format.fprintf ppf "%f" i
  | `Integer i -> Format.fprintf ppf "%d" i
  | `LiteralString ls ->
    literal_string ls
    |> Format.fprintf ppf "%s"

let%expect_test "literal_simple: integer: positive" =
  `Integer 1
  |> literal_simple Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| 1 |} ]
let%expect_test "literal_simple: integer: negative" =
  `Integer (-1)
  |> literal_simple Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| -1 |} ]

let%expect_test "literal_simple: string: negative" =
  `LiteralString "abc `def` ghi"
  |> literal_simple Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| ``abc `def` ghi`` |} ]

(* TODO reject problematic values *)
let rec format_type ppf = function
  | `TVar x ->
    Format.fprintf ppf "'%s" x
  | `TConst c ->
    Format.fprintf ppf "%s" c
  | `TApp (ts, f) ->
    (* TODO Remove redundant parentheses *)
    Format.fprintf ppf "@[<2>";
    List.iter ts ~f:(fun t -> begin match t with
      | `TVar _ | `TConst _ ->
        format_type ppf t
      | _ ->
        Format.fprintf ppf "(@[";
        format_type ppf t;
        Format.fprintf ppf "@])"
      end;
      Format.fprintf ppf "@ "
    );
    begin match f with
    | `TVar _ | `TConst _ ->
      format_type ppf f
    | _ ->
      Format.fprintf ppf "(@[";
      format_type ppf f;
      Format.fprintf ppf "@])"
    end;
    Format.fprintf ppf "@]"
  | `TTuple [] ->
    Format.fprintf ppf "()"
  | `TTuple (t :: ts) ->
    Format.fprintf ppf "(@[";
    format_type ppf t;
    List.iter ts ~f:(fun t ->
      Format.fprintf ppf "@ *@ ";
      format_type ppf t
    );
    Format.fprintf ppf "@])"
  | `TRecord fs ->
    Format.fprintf ppf "(| @[";
    List.iter fs ~f:(fun (f, t) ->
      Format.fprintf ppf "%s :@ @[" f;
      format_type ppf t;
      Format.fprintf ppf ";@]@ "
    );
    Format.fprintf ppf "@]|)"


let%expect_test "format_type: var" =
  `TVar "x"
  |> format_type Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| 'x |}]
let%expect_test "format_type: const" =
  `TConst "int"
  |> format_type Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| int |}]
let%expect_test "format_type: app" =
  `TApp ([`TConst "int"], `TConst "list")
  |> format_type Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| int list |}]
let%expect_test "format_type: app" =
  `TApp ([`TConst "int"; `TConst "int"], `TConst "m")
  |> format_type Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| int int m |}]
let%expect_test "format_type: unit" =
  `TTuple []
  |> format_type Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| () |}]
let%expect_test "format_type: tuple" =
  `TTuple [`TVar "x"; `TConst "int"]
  |> format_type Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| ('x * int) |}]
let%expect_test "format_type: record" =
  `TRecord ["a", `TVar "x"; "b", `TConst "int"]
  |> format_type Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| (| a : 'x; b : int; |) |}]

let format_type_decl_head ppf = function
  | n, vs ->
    Format.fprintf ppf "type ";
    List.iter vs ~f:(fun v ->
      Format.fprintf ppf "'%s@ " v
    );
    Format.fprintf ppf "%s" n

let%expect_test "format_type_decl_head: no variables" =
  ("t", [])
  |> format_type_decl_head Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| type t |}]
let%expect_test "format_type_decl_head: no variables" =
  ("t", ["a"])
  |> format_type_decl_head Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    type 'a
    t |}]

let format_type_decl_body ppf = function
  | `TAlias t ->
    Format.fprintf ppf " =@ ";
    format_type ppf t;
    Format.fprintf ppf ""
  | `TSum cts ->
    Format.fprintf ppf " @[<v>=";
    List.iter cts ~f:(function
      | c, None ->
        Format.fprintf ppf "@,| %s" c
      | c, Some t ->
        Format.fprintf ppf "@,@[<2>| %s of@ " c;
        format_type ppf t;
        Format.fprintf ppf "@]"
    );
    Format.fprintf ppf "@]"

let%expect_test "format_type_decl_body: alias" =
  `TAlias (`TTuple [`TConst "int"; `TVar "x"])
  |> format_type_decl_body Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
     =
    (int * 'x) |}]
let%expect_test "format_type_decl_body: sum" =
  `TSum (["A", Some (`TConst "int"); "B", Some (`TVar "x"); "C", None])
  |> format_type_decl_body Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    =
    | A of int
    | B of 'x
    | C |}]

let format_type_decl ppf (h, b) =
  Format.fprintf ppf "@[<2>";
  format_type_decl_head ppf h;
  format_type_decl_body ppf b;
  Format.fprintf ppf "@]"

let%expect_test "format_type_decl_body: sum" =
  (("t", ["x"]), `TSum (["A", Some (`TConst "int"); "B", None]))
  |> format_type_decl Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    type 'x t =
              | A of int
              | B |}]

let rec format_expr ppf = function
  | (`Float _ | `Integer _ | `LiteralString _) as ls -> literal_simple ppf ls
  | `Var x ->
    Format.fprintf ppf "%s" x
  | `Apply (f, x) ->
    Format.fprintf ppf "(@[<2>";
    format_expr ppf f;
    Format.fprintf ppf ") (";
    format_expr ppf x;
    Format.fprintf ppf "@])"
  | `Array xs ->
    Format.fprintf ppf "[ @[";
    List.iter xs ~f:(fun l ->
      format_expr ppf l;
      Format.fprintf ppf ";@ ";
    );
    Format.fprintf ppf "@]]"
  | `Record fs ->
    Format.fprintf ppf "(| @[";
    List.iter fs ~f:(fun (name, v) ->
      Format.fprintf ppf "%s = @[" name;
      format_expr ppf v;
      Format.fprintf ppf "@];@ ";
    );
    Format.fprintf ppf "@]|)"
  | `Tuple [] ->
    Format.fprintf ppf "()"
  | `Tuple (v :: vs) ->
    Format.fprintf ppf "(@[";
    format_expr ppf v;
    List.iter vs ~f:(fun (v) ->
      Format.fprintf ppf ",@ ";
      format_expr ppf v;
    );
    Format.fprintf ppf "@])"
  | `Constructor (c, []) ->
    Format.fprintf ppf "%s" c
  | `Constructor (c, f :: fs) ->
    Format.fprintf ppf "%s(@[" c;
    format_expr ppf f;
    List.iter fs ~f:(fun (v) ->
      Format.fprintf ppf ",@ ";
      format_expr ppf v;
    );
    Format.fprintf ppf "@])"
and format_decl ppf = function
  | `Let (v, e) ->
    Format.fprintf ppf "@[<hv 2>let %s =@ " v;
    format_expr ppf e;
    Format.fprintf ppf "@]"
  | `Module (m, ss, ds) ->
    Format.fprintf ppf "@[<v 2>module %s : sig" m;
    List.iter ss ~f:(fun s ->
      Format.fprintf ppf "@;";
      format_sig_decl ppf s;
    );
    Format.fprintf ppf "@]@;@[<v 2>end = struct";
    List.iter ds ~f:(fun d ->
      Format.fprintf ppf "@;";
      format_decl ppf d;
    );
    Format.fprintf ppf "@]@;end"
  | `Type td ->
    format_type_decl ppf td
and format_sig_decl ppf = function
  | `Val (v, t) ->
    Format.fprintf ppf "@[<hv 2>val %s :@ " v;
    format_type ppf t;
    Format.fprintf ppf "@]"
  | `Type th ->
    format_type_decl_head ppf th

let%expect_test "format_expr: integer" =
  `Integer 1
  |> literal_simple Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| 1 |} ]
let%expect_test "format_expr: integer list" =
  `Array [`Integer 1; `Integer 2; `Integer 3]
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| [ 1; 2; 3; ] |} ]

let%expect_test "format_expr: literal string list" =
  `Array (List.init 10 ~f:(fun _ -> `LiteralString "abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg"))
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    [ `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`;
      `abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg`; ] |} ]

let%expect_test "format_expr: var" =
  `Var "x"
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| x |} ]

let%expect_test "format_expr: app" =
  (* TODO Remove redundant parentheses *)
  `Apply (`Var "f", `Var "x")
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| (f) (x) |} ]

let%expect_test "format_expr: record" =
  `Record ["int", `Integer 1; "str", `LiteralString "abcdef"; "arr", `Array [`Integer 1; `Integer 3]]
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| (| int = 1; str = `abcdef`; arr = [ 1; 3; ]; |) |} ]

let%expect_test "format_expr: tuple: 0" =
  `Tuple []
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| () |} ]

let%expect_test "format_expr: tuple: 1" =
  `Tuple [`Integer 1]
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| (1) |} ]

let%expect_test "format_expr: tuple: 2" =
  `Tuple [`Integer 1; `LiteralString "abc"]
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| (1, `abc`) |} ]

let%expect_test "format_expr: tuple: 3" =
  `Tuple [`Integer 1; `LiteralString "abc"; `Array [`Tuple [`Array []; `LiteralString "d"]]]
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| (1, `abc`, [ ([ ], `d`); ]) |} ]

let%expect_test "format_expr: constructor: 0" =
  `Constructor ("A4Paper", [])
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| A4Paper |} ]

let%expect_test "format_expr: constructor: 1" =
  `Constructor ("Some", [`Integer 1])
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{| Some(1) |} ]

let%expect_test "format_decl: let" =
  `Let ("x", `Integer 1)
  |> format_decl Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    let x = 1 |} ]

let%expect_test "format_decl: module" =
  `Module ("List", [`Val ("x", `TConst "int")], [`Let ("x", `Integer 1)])
  |> format_decl Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    module List : sig
      val x : int end = struct
                    let x = 1
    end |}]

let%expect_test "format_decl: type decl" =
  `Type (("list", ["a"]), `TSum ["Nil", None; "Cons", Some (`TTuple [`TVar "a"])])
  |> format_decl Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    type 'a list =
                 | Nil
                 | Cons of ('a) |}]

let format_directive ppf = function
  | `Import x ->
    Format.fprintf ppf "@import: %s@." x

let format_file ppf dirs decls =
  List.iter dirs ~f:(fun dir ->
    format_directive ppf dir;
    Format.fprintf ppf "@."
  );
  List.iter decls ~f:(fun decl ->
    format_decl ppf decl;
    Format.fprintf ppf "@."
  )

let format_file_to_string dirs decls =
  let buf = Buffer.create 100 in
  let ppf = Format.formatter_of_buffer buf in
  format_file ppf dirs decls;
  Buffer.contents buf

let expr_show_message str =
  `Let ("_", `Apply (`Var "display-message", `LiteralString str))

let expr_experimental_message p =
  [ expr_show_message (" [Warning] Satyrographos: Package " ^ p ^ " is an experimental autogen package.");
    expr_show_message (" [Warning] Satyrographos: Its API is unstable; will thus be backward-incompatibly changed.");
    expr_show_message (" [Warning] Satyrographos: Furthermore, the package itself may be renamed or removed.");
  ]

let%expect_test "expr_show_message" =
  expr_show_message "p"
  |> format_decl Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    let _ = (display-message) (`p`) |}]

let value_of_option f = function
  | None ->
    `Constructor ("None", [])
  | Some x ->
    `Constructor ("Some", [f x])

let%expect_test "value_of_option: None" =
  None
  |> value_of_option (fun x -> `LiteralString x)
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    None |}]

let%expect_test "value_of_option: Some (\"a\")" =
  Some ("a")
  |> value_of_option (fun x -> `LiteralString x)
  |> format_expr Format.std_formatter;
  Format.pp_print_newline Format.std_formatter ();
  [%expect{|
    Some(`a`) |}]

let value_of_string (x: string) = `LiteralString x

let value_of_int (x: int) = `Integer x

let value_of_float (x: float) = `Float x

let value_of_list (type a) f (xs: a list) =
  `Array (List.map ~f xs)

let value_of_tuple2 f1 f2 (v1, v2) =
  `Tuple [f1 v1; f2 v2]
