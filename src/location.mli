type position
[@@deriving sexp, equal, compare, hash]

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

val position_of_offset : string -> int -> position

val display : t -> string
