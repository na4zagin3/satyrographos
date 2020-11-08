open Core

module Location = Satyrographos.Location

type directive =
  | Import of string
  | Require of string
  | MdDepends of string
[@@deriving sexp, compare, hash, equal]

type t = {
  path: string;
  directives: (Location.t * directive) list;
}
[@@deriving sexp]

let render_directive = function
  | Import f -> sprintf "@import: %s" f
  | Require p -> sprintf "@require: %s" p
  | MdDepends p -> sprintf "md depends %s" p

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
  {
    path = path;
    directives = List.map ds ~f:(fun (cr, d) -> loc cr, d);
  }

let parse_string_saty ~path str =
  parse_directives str
  |> of_directives ~path

let%expect_test "parse_string_saty: empty" =
  let path = "test.saty" in
  parse_string_saty ~path ""
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty) (directives ())) |}]

let%expect_test "parse_string_saty: single import with crlf" =
  let path = "test.saty" in
  parse_string_saty ~path "@import: imported/file1\r\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        (Import imported/file1))))) |}]

let%expect_test "parse_string_saty: single import with eol" =
  let path = "test.saty" in
  parse_string_saty ~path "@import: imported/file1\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        (Import imported/file1))))) |}]

let%expect_test "parse_string_saty: single import with eos" =
  let path = "test.saty" in
  parse_string_saty ~path "@import: imported/file1"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        (Import imported/file1))))) |}]

let%expect_test "parse_string_saty: single require" =
  let path = "test.saty" in
  parse_string_saty ~path "@require: required/file1"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        (Require required/file1))))) |}]

let%expect_test "parse_string_saty: imports and requires" =
  let path = "test.saty" in
  parse_string_saty ~path "@require: required/file1\n@import: imported/file1\n@require: required/file2\n@import: imported/file2\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        (Require required/file1))
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 9))))))))
        (Import imported/file1))
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 2) (cnum 1))) (rend ((lnum 2) (cnum 10))))))))
        (Require required/file2))
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 3) (cnum 1))) (rend ((lnum 3) (cnum 9))))))))
        (Import imported/file2))))) |}]

let%expect_test "parse_string_saty: conflicting names" =
  let path = "test.saty" in
  parse_string_saty ~path "@require: file1\n@import: file1\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        (Require file1))
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 9))))))))
        (Import file1))))) |}]

let%expect_test "parse_string_saty: % in package name" =
  let path = "test.saty" in
  parse_string_saty ~path "@require: file1 % not a comment\n@import: file1 % not a comment\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 9))))))))
        (Require "file1 % not a comment"))
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 9))))))))
        (Import "file1 % not a comment"))))) |}]

let%expect_test "parse_string_saty: comment lines" =
  let path = "test.saty" in
  parse_string_saty ~path "% comment\n%\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty) (directives ())) |}]

let%expect_test "parse_string_saty: comment lines followed by directives" =
  let path = "test.saty" in
  parse_string_saty ~path "% comment\n%\n@import: file\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 2) (cnum 1))) (rend ((lnum 2) (cnum 9))))))))
        (Import file))))) |}]

let%expect_test "parse_string_saty: comment lines interleaved between directives" =
  let path = "test.saty" in
  parse_string_saty ~path "% comment\n@require: lib\n%\n@import: file\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 1) (cnum 1))) (rend ((lnum 1) (cnum 10))))))))
        (Require lib))
       (((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 3) (cnum 1))) (rend ((lnum 3) (cnum 9))))))))
        (Import file))))) |}]

let%expect_test "parse_string_saty: directives followed by declarations" =
  let path = "test.saty" in
  parse_string_saty ~path "@import: file\nlet x = 1\n"
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives
      ((((path test.saty)
         (range
          ((ColumnRange
            ((rstart ((lnum 0) (cnum 0))) (rend ((lnum 0) (cnum 8))))))))
        (Import file))))) |}]

let parse_satysfi_md_yojson ~path (json: Yojson.Safe.t) =
  begin match json with
    | `Assoc lvs ->
      List.find_map lvs ~f:(function
          | "depends", `List ds ->
            List.filter_map ds ~f:(function
                | `String s -> Some s
                | _ ->
                  failwithf
                    "%s:\nDependency must be a list of strings but got %s@."
                    path
                    (Yojson.Safe.to_string (`List ds))
                    ()
              )
            |> Option.some
          | _ -> None
        )
      |> Option.map ~f:(fun ps ->
          {
            path = path;
            directives =
              let loc = {
                Location.path;
                range = None;
              }
              in
              List.map ~f:(fun p -> loc, MdDepends p) ps
          })
    | _ ->
      None
  end
  |> Option.value_exn ~message:(sprintf "File %s does not have depends field" path)

let parse_satysfi_md_str ~path str =
  Yojson.Safe.from_string str
  |> parse_satysfi_md_yojson ~path

let parse_satysfi_md_file ~path =
  Yojson.Safe.from_file path
  |> parse_satysfi_md_yojson ~path

let%expect_test "parse_satysfi_md_str: valid" =
  let path = "test.saty" in
  parse_satysfi_md_str ~path {|{"depends":["mdja"]}|}
  |> [%sexp_of: t]
  |> Sexp.output_hum Out_channel.stdout;
  [%expect{|
    ((path test.saty)
     (directives ((((path test.saty) (range ())) (MdDepends mdja))))) |}]

let parse_file_result path =
  match FilePath.get_extension path with
  | "satysfi-md" ->
    Result.try_with (fun () ->
        parse_satysfi_md_file ~path)
  | _ ->
    Result.try_with (fun () ->
        In_channel.read_all path
      )
    |> Result.map ~f:(match FilePath.get_extension path with
        | _ -> parse_string_saty ~path)

let referred_file_basenames ~package_root_dirs { path; directives; }=
  let basedir = FilePath.dirname path in
  List.map directives ~f:(fun (loc, d) ->
      match d with
      | Import f ->
        loc, d, [FilePath.concat basedir f]
      | Require p
      | MdDepends p ->
        loc, d, List.map package_root_dirs ~f:(fun rd -> FilePath.concat rd p)
    )
