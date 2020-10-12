open Core

type t =
  | Satysfi_0_0_3
  | Satysfi_0_0_4
  | Satysfi_0_0_5
[@@deriving sexp]

let of_string_opt = function
  | "0.0.3" -> Some Satysfi_0_0_3
  | "0.0.4" -> Some Satysfi_0_0_4
  | "0.0.5" -> Some Satysfi_0_0_5
  | _ -> None

let of_string_exn s : t =
  of_string_opt s
  |> Option.value_exn
    ~error:(Error.createf "Invalid SATySFi version: %S" s)

let to_string = function
  | Satysfi_0_0_3 -> "0.0.3"
  | Satysfi_0_0_4 -> "0.0.4"
  | Satysfi_0_0_5 -> "0.0.5"

let read_local_packages = function
  | Satysfi_0_0_3 -> false
  | _ -> true
