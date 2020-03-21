open Core

module P = Shexp_process

module Font = struct
  type fc_raw = {
    file: string;
    postscriptname: string;
    index: int;
    fontformat: string;
    family: string;
    familylang: string;
    style: string;
    stylelang: string;
    fullname: string;
    fullnamelang: string;
    slant: int;
    weight: float;
    width: int;
    foundry: string;
    verticallayout: string; (* TODO It should be int, though*)
    outline: bool;
    scalable: bool;
    color: bool;
    charset: string;
    lang: string;
    fontversion: int;
    fontfeatures: string;
    namelang: string;
    prgname: string;
  } [@@deriving sexp, compare, fields, typerep]
  (* TODO Generate from the type definition *)
  let fc_raw_fields =
    [
      "file";
      "postscriptname";
      "index";
      "fontformat";
      "family";
      "familylang";
      "style";
      "stylelang";
      "fullname";
      "fullnamelang";
      "slant";
      "weight";
      "width";
      "foundry";
      "verticallayout";
      "outline";
      "scalable";
      "color";
      "charset";
      "lang";
      "fontversion";
      "fontfeatures";
      "namelang";
      "prgname";
    ]

  type lang = string
    [@@deriving sexp, compare]

  type t = {
    file: string;
    postscriptname: string;
    index: int;
    fontformat: string;
    family: (string * lang) list;
    style: (string * lang) list;
    fullname: (string * lang) list;
    slant: int;
    weight: float;
    width: int;
    foundry: string;
    verticallayout: string; (* TODO It should be int, though*)
    outline: bool;
    scalable: bool;
    color: bool;
    charset: string;
    lang: lang list;
    fontversion: int;
    fontfeatures: string;
    namelang: string;
    prgname: string;
  } [@@deriving sexp, compare]

  let to_name_lang_pair names_str langs_str =
    let names = String.split ~on:',' names_str in
    let langs = String.split ~on:',' langs_str in
    List.zip_exn names langs

  let of_fc_raw (fcr: fc_raw) : t=
    {
      file = fcr.file;
      postscriptname = fcr.postscriptname;
      index = fcr.index;
      fontformat = fcr.fontformat;
      family = to_name_lang_pair fcr.family fcr.familylang;
      style = to_name_lang_pair fcr.style fcr.stylelang;
      fullname = to_name_lang_pair fcr.fullname fcr.fullnamelang;
      slant = fcr.slant;
      weight = fcr.weight;
      width = fcr.width;
      foundry = fcr.foundry;
      verticallayout = fcr.verticallayout; (* TODO It should be int, though*)
      outline = fcr.outline;
      scalable = fcr.scalable;
      color = fcr.color;
      charset = fcr.charset;
      lang = String.split ~on:'|' fcr.lang;
      fontversion = fcr.fontversion;
      fontfeatures = fcr.fontfeatures;
      namelang = fcr.namelang;
      prgname = fcr.prgname;
    }

end

module DistinctFont = struct
  type t = {
    file: string;
    index: int;
  } [@@deriving sexp, compare]

  let of_font (f: Font.t) = {
    file = f.file;
    index = f.index;
  }
end

let fc_format_data_field field =
  Printf.sprintf "(%s \"%%{%s|cescape}\")" field field

let fc_format_data =
  List.map ~f:fc_format_data_field Font.fc_raw_fields
  |> String.concat ~sep:" "
  |> Printf.sprintf "(%s)"

module DistinctFontMap = Map.Make(DistinctFont)

let system_font_info_list_task =
  let open P.Infix in
  P.echo "("
  >> P.run "fc-list" ["-f"; fc_format_data]
  >> P.echo ")"

(* TODO Handle extremely long argument lists *)
let font_info_list_task fonts =
  P.run "fc-scan" (["-f"; fc_format_data] @ fonts)

(* Remove ~outf *)
let font_list_task ~outf list_task =
  let sexp_string_to_map s =
    (* Sexp.of_string_conv_exn s [%of_sexp: Font.t list] (* Use Parsexp.Many *) *)
    Parsexp.Many.parse_string_exn s
    |> List.filter_map ~f:(fun sexp ->
      try
        Some ([%of_sexp: Font.fc_raw] sexp |> Font.of_fc_raw)
      with
        | Sexplib.Conv.Of_sexp_error (e, e_sexp) ->
          let stack_trace = Printexc.get_backtrace() in
          let exc_msg = Exn.to_string e in
          Format.fprintf outf "Font info parsing error:@[<2>@.%s@]@[<2>@.%s@]@." stack_trace exc_msg;
          Format.fprintf outf "Problematic value:@ @[<2>";
          Sexp.pp_hum outf e_sexp;
          Format.fprintf outf "@]@.Entire value:@ @[<2>";
          Sexp.pp_hum outf sexp;
          Format.fprintf outf "@]@.";
          None
        | e ->
          let stack_trace = Printexc.get_backtrace() in
          let exc_msg = Exn.to_string e in
          Format.fprintf outf "Font info parsing error:@[<2>@.%s@]@[<2>@.%s@]@." stack_trace exc_msg;
          Format.fprintf outf "Entire value:@ @[<2>";
          Sexp.pp_hum outf sexp;
          Format.fprintf outf "@]@.";
          None
      )
    (* |> List.filter ~f:(fun f -> not (StringSet.mem blacklist f.file)) *)
    |> List.map ~f:(fun f -> DistinctFont.of_font f, f)
    |> DistinctFontMap.of_alist_reduce ~f:(fun f1 f2 ->
        let sf1 = [%sexp_of: Font.t] f1 |> Sexp.to_string in
        let sf2 = [%sexp_of: Font.t] f2 |> Sexp.to_string in
        begin if not ([%compare.equal: Font.t] f1 f2)
          then Format.fprintf outf "WARNING: the following fonts look the same.\n%s\n%s\n@." sf1 sf2
        end;
        f1
      )
    in
  let open P.Infix in
  list_task
  |> P.capture_unit [P.Std_io.Stdout]
  >>| sexp_string_to_map
