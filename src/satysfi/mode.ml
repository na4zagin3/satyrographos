open Core

(** SATySFi typesetting mode. *)
type t =
  | Pdf
  | Text of string
  | Generic
[@@deriving sexp, compare, hash, equal]

let of_extension_opt = function
  | ".satyh" -> Some Pdf
  | ".satyg" -> Some Generic
  | s ->
    String.chop_prefix ~prefix:".satyh-" s
    |> Option.map ~f:(fun m -> Text m)

let of_basename_opt basename =
  "." ^ FilePath.get_extension basename
  |> of_extension_opt

let to_extension = function
  | Pdf ->
    ".satyh"
  | Text mode ->
    sprintf ".satyh-%s" mode
  | Generic ->
    ".satyg"

let ( <=: ) a b = match a, b with
  | Pdf, Pdf -> true
  | Text a, Text b when String.equal a b -> true
  | Generic, _ -> true
  | _, _ -> false

let%test "pdf <=: pdf" =
  Pdf <=: Pdf
let%test "pdf <=/: text" =
  not (Pdf <=: Text "md")
let%test "pdf <=/: generic" =
  not (Pdf <=: Text "md")
let%test "text <=/: pdf" =
  not (Text "md" <=: Pdf)
let%test "text md <=/: text text" =
  not (Text "md" <=: Text "text")
let%test "text md <=: text md" =
  Text "md" <=: Text "md"
let%test "text <=/: generic" =
  not (Text "md" <=: Generic)
let%test "generic <=: pdf" =
  Generic <=: Pdf
let%test "generic <=: text md" =
  Generic <=: Text "md"
let%test "generic <=: generic" =
  Generic <=: Generic

let%test_unit "(a <=: b) implies (a <= b)" =
  let test a b =
    match (a <=: b), compare a b with
    | true, n when n >= 0 ->
      ()
    | false, _ ->
      ()
    | t, n ->
      let da = sprintf !"%{sexp: t}" a in
      let db = sprintf !"%{sexp: t}" b in
      failwithf !"(%s <=: %s) is %{sexp:bool} but (%s <=> %s) is %d"
        da db t
        da db n ()
  in
  let values = [Pdf; Text "md"; Text "html"; Generic;] in
  List.iter values ~f:(fun a ->
    List.iter values ~f:(fun b ->
      test a b))
