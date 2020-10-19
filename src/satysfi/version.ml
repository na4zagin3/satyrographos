open Core

type t =
  | Satysfi_0_0_3
  | Satysfi_0_0_4
  | Satysfi_0_0_5
[@@deriving sexp, compare, equal]

let alist = [
  "0.0.3", Satysfi_0_0_3;
  "v0.0.3", Satysfi_0_0_3;
  "0.0.4", Satysfi_0_0_4;
  "v0.0.4", Satysfi_0_0_4;
  "0.0.5", Satysfi_0_0_5;
  "v0.0.5", Satysfi_0_0_5;
]

let of_string_opt =
  let map = Map.of_alist_exn (module String) alist in
  Map.find map

let%test "of_string_opt: valid" =
  of_string_opt "0.0.3"
  |> [%equal: t option] (Some Satysfi_0_0_3)

let%test "of_string_opt: invalid" =
  of_string_opt "0.0.0"
  |> [%equal: t option] None

let of_string_exn s : t =
  of_string_opt s
  |> Option.value_exn
    ~error:(Error.createf "Invalid SATySFi version: %S" s)

let to_string v =
  List.find_map alist ~f:(fun (se, ve) -> Option.some_if (equal v ve) se)
  |> Option.value_exn ~message:"BUG: Version.to_string: Unknown version. Please report this problem."

let%test "to_string" =
  to_string Satysfi_0_0_3
  |> String.equal "0.0.3"

let read_local_packages = function
  | Satysfi_0_0_3 -> false
  | _ -> true

let extract_version_string =
  let re =
    let open Re in
    let version_char =
      alt [
        alnum;
        char '.';
      ]
    in
    seq [
      bos;
      rep space;
      str "SATySFi version";
      rep space;
      rep version_char
      |> group;
    ]
    |> compile
  in
  fun str ->
    let g = Re.exec_opt re str in
    Option.map g ~f:(fun g ->
        Re.Group.get g 1
      )

let%expect_test "extract_version_string: valid: normal" =
  extract_version_string "  SATySFi version 0.0.5\n"
  |> printf !"%{sexp: string option}";
  [%expect{|
    (0.0.5) |}]

let%expect_test "extract_version_string: valid: with v" =
  extract_version_string "  SATySFi version v0.0.5\n"
  |> printf !"%{sexp: string option}";
  [%expect{|
    (v0.0.5) |}]

let%expect_test "extract_version_string: valid: dev" =
  extract_version_string "  SATySFi version v0.0.5-27-gc841df2\n"
  |> printf !"%{sexp: string option}";
  [%expect{|
    (v0.0.5) |}]

let parse_version_output str =
  extract_version_string str
  |> Option.bind ~f:of_string_opt

let%expect_test "parse_version_output: valid: normal" =
  parse_version_output "  SATySFi version 0.0.5\n"
  |> printf !"%{sexp: t option}";
  [%expect{|
    (Satysfi_0_0_5) |}]

let%expect_test "parse_version_output: valid: dev" =
  parse_version_output "  SATySFi version v0.0.5-27-gc841df2\n"
  |> printf !"%{sexp: t option}";
  [%expect{|
    (Satysfi_0_0_5) |}]

let get_current_version_cmd =
  let open Shexp_process in
  let open Shexp_process.Infix in
  run "satysfi" ["--version"]
  |> capture_unit [Stdout]
  >>| parse_version_output

let get_current_version () =
  Shexp_process.eval get_current_version_cmd

let flag =
  let open Command.Let_syntax in
  [%map_open
    let satysfi_version = flag "--satysfi-version" (optional (Arg_type.of_alist_exn alist)) ~aliases:["S"] ~doc:"VERSION SATySFi version"
    in
    match satysfi_version with
    | Some x -> x
    | None ->
      get_current_version ()
      |> Option.value_exn ~message:"Cannot detect SATySFi Version.  Please specify with --satysfi-version"
  ]
