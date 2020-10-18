open Core

type position = {
  lnum: int;
  cnum: int;
}
[@@deriving sexp, equal, compare, hash]

let next_line pos =
  {lnum = pos.lnum + 1; cnum = 0;}
let next_column pos =
  {pos with cnum = pos.cnum + 1;}
let initial_position =
  {lnum=0; cnum=0;}

type column_range = {
  rstart: position;
  rend: position;
}
[@@deriving sexp, equal, compare, hash]

type line_range = {
  rstart: int;
  rend: int;
}
[@@deriving sexp, equal, compare, hash]

type position_or_range =
  | Line of int
  | Column of position
  | LineRange of line_range
  | ColumnRange of column_range
[@@deriving sexp, equal, compare, hash]

type t = {
  path: string;
  range: position_or_range option;
}
[@@deriving sexp, equal, compare, hash]

let display_line lnum =
  sprintf "%d" (lnum + 1)
let display_position pos =
  sprintf "%d.%d" (pos.lnum + 1) (pos.cnum + 1)

let display_position_or_range = function
  | Line l ->
    display_line l
  | Column p ->
    display_position p
  | LineRange r ->
    sprintf "%s-%s"
      (display_line r.rstart)
      (display_line r.rend)
  | ColumnRange r ->
    sprintf "%s-%s"
      (display_position r.rstart)
      (display_position r.rend)

let display p =
  match p.range with
  | None -> p.path
  | Some r ->
    sprintf "%s:%s"
      p.path
      (display_position_or_range r)

let position_of_offset content off =
  let rec sub cur pos =
    if cur = off
    then pos
    else
      let cur = cur + 1 in
      if Char.equal (String.get content cur) '\n'
      then sub cur (next_line pos)
      else sub cur (next_column pos)
  in
  sub 0 initial_position

let%expect_test "position_of_offset: empty content" =
  position_of_offset "" 0
  |> printf !"%{sexp: position}";
  [%expect{|
    ((lnum 0) (cnum 0)) |}]

let%expect_test "position_of_offset: empty content" =
  position_of_offset "abc" 1
  |> printf !"%{sexp: position}";
  [%expect{|
    ((lnum 0) (cnum 1)) |}]

let%expect_test "position_of_offset: empty content" =
  let test off =
    position_of_offset "abc\nd\n" off
    |> printf !"%d: %{sexp: position}\n" off
  in
  Sequence.init 6 ~f:test
  |> Sequence.iter ~f:ident;
  [%expect{|
    0: ((lnum 0) (cnum 0))
    1: ((lnum 0) (cnum 1))
    2: ((lnum 0) (cnum 2))
    3: ((lnum 1) (cnum 0))
    4: ((lnum 1) (cnum 1))
    5: ((lnum 2) (cnum 0)) |}]

let offset_of_position content pos =
  let rec sub off cur =
    if equal_position pos cur
    then off
    else
      let off = off + 1 in
      if Char.equal (String.get content off) '\n'
      then sub off {lnum = pos.lnum + 1; cnum = 0;}
      else sub off {pos with cnum = pos.cnum + 1;}
  in
  sub 0 {lnum=0; cnum=0;}

