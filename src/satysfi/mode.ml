open Core

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
