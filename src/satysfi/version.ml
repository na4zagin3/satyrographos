open Core

type t =
  | Satysfi_0_0_3
  | Satysfi_0_0_4
  | Satysfi_0_0_5
[@@deriving sexp, compare, equal]

let alist = [
  "0.0.3", Satysfi_0_0_3;
  "0.0.4", Satysfi_0_0_4;
  "0.0.5", Satysfi_0_0_5;
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
