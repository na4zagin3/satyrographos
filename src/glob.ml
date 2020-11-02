open Core

module PrinterSemantics = struct
  type glob = string
  let star = "*"
  let atom = ident
  let range =
    sprintf "%d..%d"
  let slash s g =
    s ^ "/" ^ g
  let alt gs =
    "{" ^ String.concat ~sep:"," gs ^ "}"

  type selector = string
  let slash_select s e =
    s ^ "/" ^ e
  let selectors es =
    let e_to_string (d, g) =
      match d with
      | true -> sprintf "+%s" g
      | false -> sprintf "-%s" g
    in
    "{"
    ^ (List.map ~f:e_to_string es |> String.concat ~sep:",")
    ^ "}"
end

module TokenMatcher = struct
  type 'a t = {
    value: 'a option;
    children: 'a children;
  }
  and 'a children =
    (string, 'a t, String.comparator_witness) Map.t

  let empty : 'a t = {
    value = None;
    children = Map.empty (module String);
  }
  let node value children = {
    value;
    children =
      children
      |> Map.of_alist_exn (module String);
  }

  let merge (a: 'a t) (b: 'a t) =
    let rec sub v (a: 'a t) (b: 'a t) =
      if Option.is_some b.value
      then b
      else begin
        let v =
          List.find_map ~f:ident
            [b.value; a.value; v;]
        in
        let merge_children =
          let combine ~key:_ = sub v in
          Map.merge_skewed ~combine
        in
        {
          value = v;
          children = merge_children a.children b.children;
        }
      end
    in
    sub None a b

  let rec path ts v =
    match ts with
    | [] -> {
        empty with
        value = v;
      }
    | t :: ts ->
      {
        empty with
        children =
          Map.singleton
            (module String)
            t
            (path ts v)
      }

  let exec m ts =
    let rec sub v m =
      let v = Option.first_some m.value v in
      function
      | [] ->
        v
      | x :: xs ->
        match Map.find m.children x with
        | None ->
          v
        | Some n ->
          sub v n xs
    in
    sub None m ts

  let rec pp pp_value outf (m: 'a t) =
    Format.fprintf outf "@[";
    begin match m.value with
      | None -> ()
      | Some v ->
        Format.fprintf outf "@[(";
        pp_value outf v;
        Format.fprintf outf ")@]";
    end;
    Format.fprintf outf "@[{";
    begin match Map.to_alist m.children with
      | [] -> ()
      | [key, data] ->
        pp_child pp_value outf ~key ~data
      | (key, data) :: xs ->
        pp_child pp_value outf ~key ~data;
        List.iter xs ~f:(fun (key, data) ->
            Format.fprintf outf ",@,";
            pp_child pp_value outf ~key ~data
          )
    end;
    Format.fprintf outf "}@]@]"
  and pp_child (pp_value: Formatter.t -> 'a -> unit) outf ~key ~(data:'a t) =
    Format.fprintf outf "@[%S@[" key;
    pp pp_value outf data;
    Format.fprintf outf "@]@]"

  let to_string pp_value m =
    let buf = Buffer.create 10 in
    let outf = Format.formatter_of_buffer buf in
    pp pp_value outf m;
    Format.pp_print_flush outf ();
    Buffer.contents buf

  let gen_token =
    Quickcheck.Generator.of_list ["a"; "b"; "c";]

  let gen gen_value =
    let open Base_quickcheck.Generator in
    let open Quickcheck.Generator in
    list (both small_strictly_positive_int (both gen_token gen_value))
    >>| (fun children ->
        let map =
          children
          |> List.mapi ~f:(fun i (d, c) ->
              let index =
                if i <> 0
                then i - (d % i) - 1
                else -1
              in
              index, (i, c)
            )
          |> Map.of_alist_multi (module Int)
        in
        let rec sub i =
          Map.find_multi map i
          |> List.map ~f:(fun (i, (t, v)) ->
              let result = t, node v (sub i) in
              result
            )
          |> Map.of_alist_reduce (module String) ~f:const
          |> Map.to_alist
        in
        match children with
        | [] -> empty
        | (_, (_, v)) :: _ ->
          node v (sub 0)
      )

end

let gen_token = TokenMatcher.gen_token

let prefix_lists l =
  let rec sub acc = function
    | [] -> acc
    | x :: xs ->
      sub (List.map ~f:(fun ys -> x :: ys) ([] :: acc)) xs
  in
  List.map ~f:List.rev (sub [] l)

let gen_value =
  let open Base_quickcheck.Generator in
  option small_positive_or_zero_int

let test_matcher ?context m ts expected =
  let result = TokenMatcher.exec m ts in
  if [%equal: int option] result expected |> not
  then
    let msg =
      sprintf !"matching path %s with %{sexp: string list} should return %{sexp: int option}, but got %{sexp: int option}"
        (TokenMatcher.to_string Int.pp m)
        ts
        expected
        result
    in
    let msg =
      Option.value_map ~default:msg ~f:(fun context -> msg ^ "\nContext:\n" ^ context ) context
    in
    failwith msg

let%test_unit "TokenMatcher: path" =
  let gen =
    let open Base_quickcheck.Generator in
    (both (both (list gen_token) (list gen_token)) gen_value)
  in
  let f ((ms, ts), v) =
    let matched_token_lists =
      prefix_lists ts
      |> List.map ~f:(fun ts -> ms @ ts)
    in
    let non_matched_token_lists =
      prefix_lists ms
      |> List.filter ~f:(fun ts -> List.length ts < List.length ms)
    in
    let test_cases =
      List.map matched_token_lists ~f:(fun ts -> ts, v)
      @ List.map non_matched_token_lists ~f:(fun ts -> ts, None)
    in
    List.iter test_cases ~f:(fun (ts, expected) ->
        let m = TokenMatcher.path ms v in
        test_matcher m ts expected
      )
  in
  Quickcheck.test
    ~sizes:(Sequence.cycle_list_exn (List.range 0 3 ~stop:`inclusive))
    gen
    ~f

let%test_unit "TokenMatcher: merge paths" =
  let gen =
    let open Quickcheck.Generator in
    let open Base_quickcheck.Generator in
    let gen_m_path =
      (both (list gen_token) (option small_positive_or_zero_int))
      >>| fun (ms, v) ->
      TokenMatcher.path ms v
    in
    (tuple3
       gen_m_path
       gen_m_path
       (list gen_token))
  in
  let f (m1, m2, ts) =
    let v1 = TokenMatcher.exec m1 ts in
    let v2 = TokenMatcher.exec m2 ts in
    let expected =
      Option.first_some v2 v1
    in
    let m = TokenMatcher.merge m1 m2 in
    test_matcher m ts expected ~context:(
      sprintf !"m1: %s, m2: %s"
        (TokenMatcher.to_string Int.pp m1)
        (TokenMatcher.to_string Int.pp m2)
    )
  in
  Quickcheck.test
    gen
    ~f

let%test_unit "TokenMatcher: merge" =
  let gen =
    let open Quickcheck.Generator in
    let open Base_quickcheck.Generator in
    (tuple3
       (TokenMatcher.gen gen_value)
       (TokenMatcher.gen gen_value)
       (list gen_token))
  in
  let f (m1, m2, ts) =
    let v1 = TokenMatcher.exec m1 ts in
    let v2 = TokenMatcher.exec m2 ts in
    let expected =
      Option.first_some v2 v1
    in
    let m = TokenMatcher.merge m1 m2 in
    test_matcher m ts expected ~context:(
      sprintf !"m1: %s, m2: %s"
        (TokenMatcher.to_string Int.pp m1)
        (TokenMatcher.to_string Int.pp m2)
    )
  in
  Quickcheck.test
    gen
    ~f

module TokenMatcherSemantics = struct
  let iota a b =
    let rec sub acc b =
      if a < b
      then sub (b :: acc) (b - 1)
      else acc
    in
    sub [] b

  type value = bool

  type glob = value -> value TokenMatcher.t
  let id_char =
    Re.alt [
      Re.alnum;
      Re.set "_-.";
    ]
  let star : glob = fun v ->
    TokenMatcher.node (Some v) []
  let atom x : glob = fun v ->
    let open TokenMatcher in
    node None [
      x, node (Some v) []
    ]

  let range n1 n2 : glob = fun v ->
    let open TokenMatcher in
    iota n1 n2
    |> List.map ~f:(fun x ->
        Int.to_string x, node (Some v) []
      )
    |> node None
  let slash s g : glob = fun v ->
    let open TokenMatcher in
    node None [
      s, node None [
        "/", g v
      ]
    ]
  let alt (gs: glob list) : glob = fun v ->
    List.map ~f:(fun f -> f v) gs
    |> List.fold_left ~init:TokenMatcher.empty ~f:TokenMatcher.merge

  type selector = value TokenMatcher.t
  let slash_select s e =
    let open TokenMatcher in
    node None [
      s, node None [
        "/", e
      ]
    ]
  let selectors es =
    es
    |> List.map ~f:(fun (v, g) -> g v)
    |> List.fold_left ~init:TokenMatcher.empty ~f:TokenMatcher.merge
end

module Printer = Glob_parser.Make(PrinterSemantics)
module TokenMatcherParser = Glob_parser.Make(TokenMatcherSemantics)

let parse_as_tm_exn l =
  TokenMatcherParser.main Glob_lexer.token l

let split_on_slash str =
  let rec sub acc str =
    match str, String.index str '/' with
    | "", None ->
      List.rev acc
    | _, None ->
      List.rev (str :: acc)
    | _, Some 0 ->
      let s2 = String.slice str 1 0 in
      sub ("/" :: acc) s2
    | _, Some i ->
      let s1 = String.slice str 0 i in
      let s2 = String.slice str (i + 1) 0 in
      sub ("/" :: s1 :: acc) s2
  in
  sub [] str

let%expect_test "split_on_slash: printer" =
  let test x =
    split_on_slash x
    |> printf !"%S -> %{sexp: string list}\n" x
  in
  test "";
  test "a";
  test "a/";
  test "a/b";
  test "/b";
  test "/";
  [%expect {|
    "" -> ()
    "a" -> (a)
    "a/" -> (a /)
    "a/b" -> (a / b)
    "/b" -> (/ b)
    "/" -> (/) |}]

let%expect_test "glob: printer" =
  Printer.main Glob_lexer.token (Lexing.from_string "+abc/{d,e,3-5}")
  |> print_endline;
  [%expect {| {+abc/{d,e,3-5}} |}]

let%expect_test "glob: test" =
  let test pat x =
    let tm =
      parse_as_tm_exn (Lexing.from_string pat)
    in
    let outf = Format.std_formatter in
    Format.fprintf outf "Test %S for %S@." pat x;
    TokenMatcher.pp Bool.pp outf tm;
    Format.fprintf outf "@.";
    TokenMatcher.exec tm (split_on_slash x)
    |> Format.fprintf outf !"result:@,%{sexp: bool option}@.@."
  in
  test "-abc/{d,e,3..5}" "abc";
  test "-abc/{d,e,3..5}" "abc/d";
  test "-abc/{d,e,3..5}" "abc/d/g";
  test "-abc/{d,e,3..5}" "abc/4";

  test "abc/{-d,+e,-3..5}" "abc/4";
  test "abc/{-d,+e,-3..5}" "abc/e";
  test "abc/{-*,+e}" "abc/e";

  test "+a,-b,+c" "a";
  test "+a,-b,+c" "b";
  test "+a,-b,+c" "d";
  [%expect {|
    Test "-abc/{d,e,3..5}" for "abc"
    {"abc"{"/"{"4"(false){},"5"(false){},"d"(false){},"e"(false){}}}}
    result:
    ()

    Test "-abc/{d,e,3..5}" for "abc/d"
    {"abc"{"/"{"4"(false){},"5"(false){},"d"(false){},"e"(false){}}}}
    result:
    (false)

    Test "-abc/{d,e,3..5}" for "abc/d/g"
    {"abc"{"/"{"4"(false){},"5"(false){},"d"(false){},"e"(false){}}}}
    result:
    (false)

    Test "-abc/{d,e,3..5}" for "abc/4"
    {"abc"{"/"{"4"(false){},"5"(false){},"d"(false){},"e"(false){}}}}
    result:
    (false)

    Test "abc/{-d,+e,-3..5}" for "abc/4"
    {"abc"{"/"{"4"(false){},"5"(false){},"d"(false){},"e"(true){}}}}
    result:
    (false)

    Test "abc/{-d,+e,-3..5}" for "abc/e"
    {"abc"{"/"{"4"(false){},"5"(false){},"d"(false){},"e"(true){}}}}
    result:
    (true)

    Test "abc/{-*,+e}" for "abc/e"
    {"abc"{"/"(false){"e"(true){}}}}
    result:
    (true)

    Test "+a,-b,+c" for "a"
    {"a"(true){},"b"(false){},"c"(true){}}
    result:
    (true)

    Test "+a,-b,+c" for "b"
    {"a"(true){},"b"(false){},"c"(true){}}
    result:
    (false)

    Test "+a,-b,+c" for "d"
    {"a"(true){},"b"(false){},"c"(true){}}
    result:
    () |}]
