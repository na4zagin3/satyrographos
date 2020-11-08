open Core
open Satyrographos

module Satysfi = Satyrographos_satysfi.Writer

module StringMap = Map.Make(String)

let name = "$fonts"

type font_location =
  | Single of { src: string; orig_location: string option; }
  | Collection of  { src: string; index: int; orig_location: string option;}

type font_type =
  | TextFont
  | MathFont

type font = {
  name : string;
  library_name : string;
  location: font_location;
  font_type : font_type;
  font_info : FontInfo.Font.t option;
}

let get_assoc ~outf names = function
  | `Assoc a -> a
  | j ->
    Format.fprintf outf "Invalid value in hash %s: %s. Ignored.@."
      ([%sexp_of: string list] names |> Sexp.to_string_hum)
      (Library.Json.to_string j);
    []

let decode_font_location ~outf library_name (lib: Library.t) font_name (j : Library.Json.t) =
  let get_src opts =
    let src = List.find ~f:(fun (field, _) -> String.equal field "src") opts in
    let src_dist = List.find ~f:(fun (field, _) -> String.equal field "src-dist") opts in
    begin match src, src_dist with
    | Some (_, `String src_with_dist), _ ->
      if String.is_prefix src_with_dist ~prefix:"dist/"
      then Some (String.drop_prefix src_with_dist 5)
      else begin
        Format.fprintf outf "WARNING: Font %s (%s) refers non-dist location %s.@." font_name library_name src_with_dist;
        None
      end
    | _, Some (_, `String src) ->
      Some ("fonts/" ^ src)
    | _ ->
      Format.fprintf outf "WARNING: Font %s (%s) does not have a valid font location.@." font_name library_name;
      None
    end
  in
  let get_orig_location src =
    begin match Map.find lib.files src with
    | Some (`Filename fn) -> Some fn
    | Some (`Content _) ->
      Format.fprintf outf "BUG: Attempt to get file location of %s (%s), which is automatically generated.@.Please report this bug.@." src library_name ;
      None
    | None ->
      Format.fprintf outf "WARNING: Package %s references font file %s not in the library.@." library_name src;
      None
    end
  in
  match j with
  | `Variant ("Collection", Some (`Assoc opts)) ->
    let index = List.find ~f:(fun (field, _) -> String.equal field "index") opts in
    begin match get_src opts, index with
    | Some src, Some (_, `Int index) ->
      let orig_location = get_orig_location src in
      Some (Collection { src; index; orig_location; })
    | _, _ ->
      Format.fprintf outf "WARNING: Font %s (%s) does not have a valid font location.@." font_name library_name;
      None
    end
  | `Variant ("Single", Some (`Assoc opts)) ->
    get_src opts
    |> Option.map ~f:(fun src ->
      let orig_location = get_orig_location src in
      Single { src; orig_location; }
    )
  | _ ->
    Format.fprintf outf "WARNING: Font %s (%s) does not have a valid font location.@." font_name library_name;
    None

let font_list ~outf (lib: Library.t) =
  let fonts =
    Map.find lib.hashes "hash/fonts.satysfi-hash"
    |> Option.value_map ~default:[] ~f:(fun (name, hash) -> get_assoc ~outf name hash) in
  let math_fonts =
    Map.find lib.hashes "hash/mathfonts.satysfi-hash"
    |> Option.value_map ~default:[] ~f:(fun (name, hash) -> get_assoc ~outf name hash) in
  let library_name = Option.value ~default:"(no name)" lib.name in
  let font_list font_type pairs =
    List.filter_map pairs ~f:(fun (font_name, location) ->
      decode_font_location ~outf library_name lib font_name location
      |> Option.map ~f:(fun location -> { name = font_name; library_name; location; font_type; font_info = None; })
    )
  in
  font_list TextFont fonts @ font_list MathFont math_fonts

let font_location_to_distint_font = function
  | Single { orig_location = Some file; _ } ->
    Some FontInfo.DistinctFont.{ file; index = 0; }
  | Collection { orig_location = Some file; index; _ } ->
    Some FontInfo.DistinctFont.{ file; index; }
  | _ ->
    None

let get_font_info ~outf font_list =
  let font_files =
    List.filter_map font_list ~f:(fun f -> match f.location with
      | Single { orig_location; _ } -> orig_location
      | Collection { orig_location; _ } -> orig_location)
    |> Set.of_list (module String)
    |> Set.to_list
  in
  let join_with_font_info font_info_map =
    (* font_info_map
    |> [%sexp_of: FontInfo.Font.t FontInfo.DistinctFontMap.t]
    |> Sexp.to_string_hum
    |> Format.fprintf outf "Font info map: %s"; *)
    List.map font_list ~f:(fun f ->
      let font_info =
        font_location_to_distint_font f.location
        |> Option.map ~f:(FontInfo.DistinctFontMap.find font_info_map) in
      { f with font_info = Option.value font_info ~default:f.font_info }
    )
  in
  let open Shexp_process.Infix in
  FontInfo.font_list_task ~outf (FontInfo.font_info_list_task font_files)
  >>| join_with_font_info

let package_name = "$fonts"
let package_path = "packages/" ^ package_name ^ ".satyg"

let font_type_name = "font"
let font_location_type_name = "font-location"
let font_name_field_name = "name"
let library_name_field_name = "library-name"
let font_location_field_name = "font-location"
let font_type_field_name = "font-type"
let font_list_field_name = "list"

let font_type_decl =
  [ `Type ((font_location_type_name, []),
      `TSum [
        "Single", Some (`TRecord [
          "src", `TConst "string";
          "orig-location", `TApp ([`TConst "string"], `TConst "option");
        ]);
        "Collection", Some (`TRecord [
          "src", `TConst "string";
          "index", `TConst "int";
          "orig-location", `TApp ([`TConst "string"], `TConst "option");
        ])]);
    `Type (("font-type", []), `TSum ["TextFont", None; "MathFont", None]);
    `Type (("font-info", []), `TAlias (`TRecord [
        "postscript-name", `TConst "string";
        "font-format", `TConst "string";
        "width", `TConst "int";
        "weight", `TConst "float";
        "slant", `TConst "int";
        "version", `TConst "int";
        "family", `TApp ([`TTuple [`TConst "string"; `TConst "string"]], `TConst "list");
        "style", `TApp ([`TTuple [`TConst "string"; `TConst "string"]], `TConst "list");
        "fullname", `TApp ([`TTuple [`TConst "string"; `TConst "string"]], `TConst "list");
        "charset", `TConst "string";
        "lang", `TApp ([`TConst "string"], `TConst "list");
    ]));
    `Type (
      (font_type_name, []),
      `TAlias (`TRecord [
        font_name_field_name, `TConst "string";
        library_name_field_name, `TConst "string";
        font_location_field_name, `TConst font_location_type_name;
        font_type_field_name, `TConst font_type_field_name;
        "font-info", `TApp ([`TConst "font-info"], `TConst "option");
      ]));
  ]

let font_module_sig =
  [ `Val (font_list_field_name,
      `TApp ([`TConst font_type_name], `TConst "list"));
  ]

let font_location_to_value = function
  | Single { src; orig_location; } ->
    `Constructor (
      "Single", [`Record [
        "src", Satysfi.value_of_string src;
        "orig-location",  Satysfi.(value_of_option value_of_string orig_location);
      ]];)
  | Collection { src; index; orig_location; } ->
    `Constructor ("Collection", [`Record [
        "src", Satysfi.value_of_string src;
        "index", Satysfi.value_of_int index;
        "orig-location",  Satysfi.(value_of_option value_of_string orig_location);
      ]])

let font_type_to_value = function
  | TextFont ->
    `Constructor ("TextFont", [])
  | MathFont ->
    `Constructor ("MathFont", [])

let font_info_to_value (fi: FontInfo.Font.t) =
  `Record [
    "postscript-name", `LiteralString fi.postscriptname;
    "font-format", `LiteralString fi.fontformat;
    "width", Satysfi.value_of_int fi.width;
    "weight", Satysfi.value_of_float fi.weight;
    "slant", Satysfi.value_of_int fi.slant;
    "version", Satysfi.value_of_int fi.fontversion;
    "family", Satysfi.(value_of_list (value_of_tuple2 value_of_string value_of_string)) fi.family;
    "style", Satysfi.(value_of_list (value_of_tuple2 value_of_string value_of_string)) fi.style;
    "fullname", Satysfi.(value_of_list (value_of_tuple2 value_of_string value_of_string)) fi.fullname;
    "charset", Satysfi.(value_of_string) fi.charset;
    "lang", Satysfi.(value_of_list value_of_string) fi.lang;
  ]

let font_to_value f =
  `Record [
    font_name_field_name, `LiteralString f.name;
    library_name_field_name, `LiteralString f.library_name;
    font_location_field_name, font_location_to_value f.location;
    font_type_field_name, font_type_to_value f.font_type;
    "font-info", Satysfi.value_of_option font_info_to_value f.font_info;
  ]

let generate ~outf ~persistent_yojson:_ library_map =
  let fonts =
    Map.to_alist library_map
    |> List.map ~f:(fun (_, library) -> font_list ~outf library)
    |> List.join
  in
  let fonts =
    Shexp_process.eval (get_font_info ~outf fonts)
  in
  let records =
    List.map fonts ~f:font_to_value
  in
  let f = `Module ("Fonts", font_module_sig, [`Let (font_list_field_name, `Array records)]) in
  let decls =
    Satysfi.expr_experimental_message package_name
    @ font_type_decl
    @ [f] in
  let cont = Satysfi.format_file_to_string [] decls in
  Library.{ empty with
    name = Some name;
    version = Some "0.1";
    files = LibraryFiles.singleton package_path (`Content cont);
  }
