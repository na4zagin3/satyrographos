open Core

(* TODO Move this function to somewhere more appropriate *)
let empty_set_of (type k cmp) another_set: (k, cmp) Base.Set.t =
  Base.Set.empty (module struct
    type t = k
    type comparator_witness = cmp
    let comparator = (Set.comparator another_set)
  end)

module StringSet = Set.Make(String)
module StringMap = Map.Make(String)

type t = Library.t StringMap.t

(** Calculate a transitive closure. *)
let transitive_closure map init =
  let rec f visited queue = match Set.choose queue with
    | None -> visited
    | Some cur ->
      let visited = Set.add visited cur in
      match Map.find map cur with
      | None -> visited;
      | Some nexts ->
        let queue =  Set.union (Set.remove queue cur) (Set.diff nexts visited) in
        f visited queue in
  f (empty_set_of init) init

(* TODO property-based testing *)
let%expect_test "transitive_closure: empty" =
  let map = [ "a", ["b"; "c"; "f"]; "b", ["d"]; "c", []; "d", ["e"; "f"]; "f", [] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.empty in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| () |}]
let%expect_test "transitive_closure: transitive" =
  let map = [ "a", ["b"; "c"; "f"]; "b", ["d"]; "c", []; "d", ["e"; "f"]; "e", []; "f", [] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "a" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (a b c d e f) |}]
let%expect_test "transitive_closure: loop" =
  let map = [ "a", ["b"]; "b", ["a"] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "a" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (a b) |}]
let%expect_test "transitive_closure: non-closed" =
  let map = [ "a", ["b"] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "a" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (a b) |}]
let%expect_test "transitive_closure: non-closed" =
  let map = [ "a", ["b"] ]
    |> List.map ~f:(fun (x, y) -> x, StringSet.of_list y)
    |> StringMap.of_alist_exn in
  let init = StringSet.of_list [ "c" ] in
  transitive_closure map init
  |> [%sexp_of: StringSet.t] |> Sexp.to_string_hum |> print_endline;
  [%expect{| (c) |}]


