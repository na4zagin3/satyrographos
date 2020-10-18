open Core

module Location = Satyrographos.Location

type directive =
  | Import of string
  | Require of string
[@@deriving sexp, compare, hash, equal]

type t = {
  path: string;
  imports: (Location.t * string) list;
  requires: (Location.t * string) list;
}
[@@deriving sexp]

let render_directive = function
  | Import f -> sprintf "@import: %s" f
  | Require p -> sprintf "@require: %s" p

let parse_directives =
  (* TODO Rewrite when multi-line comment is added to SATySFi *)
  let open Re in
  let line_re =
    seq [
      rep space;
      alt [
        char '%';
        seq [
          str "@";
          alt [str "require"; str "import"];
          str ":";
        ];
      ]
      |> group;
      rep (char ' ');
      rep (notnl)
      |> group;
      alt [eol; eos;];
    ]
  in
  let file_re =
    seq [
      bos;
      rep line_re;
    ]
  in
  let line_c = compile line_re in
  let file_c = compile file_re in
  fun str ->
    match Re.Seq.matches file_c str () with
    | Nil -> []
    | Cons (ls, _) ->
      let chop_suffix_cr str =
        String.chop_suffix ~suffix:"\r" str
        |> Option.value ~default:str
      in
      let range_of_offset_pair str (s, e) : Location.column_range = {
        rstart=Location.position_of_offset str s;
        rend=Location.position_of_offset str e;
      }
      in
      let f g =
        match Group.all g with
        | [| _; "%"; _ |] -> []
        | [| _; "@import:"; c |] ->
          [ range_of_offset_pair str (Group.offset g 1), Import (chop_suffix_cr c) ]
        | [| _; "@require:"; c |] ->
          [ range_of_offset_pair str (Group.offset g 1), Require (chop_suffix_cr c) ]
        | a ->
          failwithf !"BUG: parse_line: Unmatched Re %{sexp:string array} Please report this." a ()
      in
      Re.all line_c ls
      |> List.concat_map ~f

let of_directives ~path ds =
  let loc cr =
    Location.{
      path;
      range = Some (ColumnRange cr);
    }
  in
  let accum acc = function
    | cr, Import c ->
      { acc with imports = (loc cr, c) :: acc.imports; }
    | cr, Require c ->
      { acc with requires = (loc cr, c) :: acc.requires; }
  in
  let empty = {
    path = path;
    imports = [];
    requires = [];
  } in
  List.fold_left ~f:accum ~init:empty ds

let parse_string ~path str =
  parse_directives str
  |> of_directives ~path

let parse_file_result path =
  Result.try_with (fun () ->
      In_channel.read_all path
    )
  |> Result.map ~f:(parse_string ~path)

let%expect_test "parse_string: empty" =
  let path = "test.saty" in
  parse_string ~path ""
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty) (imports ()) (requires ())) |}]

let%expect_test "parse_string: single import with crlf" =
  let path = "test.saty" in
  parse_string ~path "@import: imported/file1\r\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        imported/file1)))
     (requires ())) |}]

let%expect_test "parse_string: single import with eol" =
  let path = "test.saty" in
  parse_string ~path "@import: imported/file1\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        imported/file1)))
     (requires ())) |}]

let%expect_test "parse_string: single import with eos" =
  let path = "test.saty" in
  parse_string ~path "@import: imported/file1"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        imported/file1)))
     (requires ())) |}]

let%expect_test "parse_string: single require" =
  let path = "test.saty" in
  parse_string ~path "@require: required/file1"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty) (imports ())
     (requires
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        required/file1)))) |}]

let%expect_test "parse_string: imports and requires" =
  let path = "test.saty" in
  parse_string ~path "@require: required/file1\n@import: imported/file1\n@require: required/file2\n@import: imported/file2\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 3) (cnum 1))) (rend ((lnum 3) (cnum 9))))))))
        imported/file2)
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 9))))))))
        imported/file1)))
     (requires
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 2) (cnum 1))) (rend ((lnum 2) (cnum 10))))))))
        required/file2)
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        required/file1)))) |}]

let%expect_test "parse_string: conflicting names" =
  let path = "test.saty" in
  parse_string ~path "@require: file1\n@import: file1\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 9))))))))
        file1)))
     (requires
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        file1)))) |}]

let%expect_test "parse_string: % in package name" =
  let path = "test.saty" in
  parse_string ~path "@require: file1 % not a comment\n@import: file1 % not a comment\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 9))))))))
        "file1 % not a comment")))
     (requires
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        "file1 % not a comment")))) |}]

let%expect_test "parse_string: comment lines" =
  let path = "test.saty" in
  parse_string ~path "% comment\n%\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty) (imports ()) (requires ())) |}]

let%expect_test "parse_string: comment lines followed by directives" =
  let path = "test.saty" in
  parse_string ~path "% comment\n%\n@import: file\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 2) (cnum 1))) (rend ((lnum 2) (cnum 9))))))))
        file)))
     (requires ())) |}]

let%expect_test "parse_string: comment lines interleaved between directives" =
  let path = "test.saty" in
  parse_string ~path "% comment\n@require: lib\n%\n@import: file\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 3) (cnum 1))) (rend ((lnum 3) (cnum 9))))))))
        file)))
     (requires
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 10))))))))
        lib)))) |}]

let%expect_test "parse_string: directives followed by declarations" =
  let path = "test.saty" in
  parse_string ~path "@import: file\nlet x = 1\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (imports
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        file)))
     (requires ())) |}]

let referred_file_basenames ~package_root_dirs { path; imports; requires; }=
  let basedir = FilePath.dirname path in
  List.map imports ~f:(fun (loc, p) -> loc, Import p, [FilePath.concat basedir p])
  @ List.map requires ~f:(fun (loc, p) -> loc, Require p, List.map package_root_dirs ~f:(fun rd -> FilePath.concat rd p))
