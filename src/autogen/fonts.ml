open Core
open Satyrographos

module StringMap = Map.Make(String)

let name = "%fonts"

type font_location =
  | Single of string
  | Collection of string * int

type font_type =
  | TextFont
  | MathFont

type font = {
  name : string;
  library_name : string;
  location: font_location;
  font_type : font_type;
}

let get_assoc ~outf names = function
  | `Assoc a -> a
  | j ->
    Format.fprintf outf "Invalid value in hash %s: %s. Ignored.@."
      ([%sexp_of: string list] names |> Sexp.to_string_hum)
      (Library.Json.to_string j);
    []

let decode_font_location ~outf library_name font_name (j : Library.Json.t) = match j with
  | `Variant ("Collection", Some (`Assoc opts)) ->
    let src = List.find ~f:(fun (field, _) -> String.equal field "src") opts in
    let src_dist = List.find ~f:(fun (field, _) -> String.equal field "src-dist") opts in
    let index = List.find ~f:(fun (field, _) -> String.equal field "index") opts in
    begin match Option.first_some src src_dist, index with
    | Some (_, `String src), Some (_, `Int index) ->
      Some (Collection (src, index))
    | _, _ ->
      Format.fprintf outf "WARNING: Font %s (%s) does not have a valid font location.@." font_name library_name;
      None
    end
  | `Variant ("Single", Some (`Assoc opts)) ->
    let src = List.find ~f:(fun (field, _) -> String.equal field "src") opts in
    let src_dist = List.find ~f:(fun (field, _) -> String.equal field "src-dist") opts in
    begin match Option.first_some src src_dist with
    | Some (_, `String src) ->
      Some (Single src)
    | _ ->
      Format.fprintf outf "WARNING: Font %s (%s) does not have a valid font location.@." font_name library_name;
      None
    end
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
      decode_font_location ~outf library_name font_name location
      |> Option.map ~f:(fun location -> { name = font_name; library_name; location; font_type })
    )
  in
  font_list TextFont fonts @ font_list MathFont math_fonts
  (* TODO Implement math fonts *)

let package_name = "satyrographos/experimental/fonts"
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
        "Single", Some (`TConst "string");
        "Collection", Some (`TTuple [`TConst "string"; `TConst "int"])]);
    `Type (("font-type", []), `TSum ["TextFont", None; "MathFont", None]);
    `Type (
      (font_type_name, []),
      `TAlias (`TRecord [
        font_name_field_name, `TConst "string";
        library_name_field_name, `TConst "string";
        font_location_field_name, `TConst font_location_type_name;
        font_type_field_name, `TConst font_type_field_name;
      ]));
  ]

let font_module_sig =
  [ `Val (font_list_field_name,
      `TApp ([`TConst font_type_name], `TConst "list"));
  ]

let font_location_to_value = function
  | Single src ->
    `Constructor ("Single", [`LiteralString src])
  | Collection (src, index) ->
    `Constructor ("Collection", [`LiteralString src; `Integer index])

let font_type_to_value = function
  | TextFont ->
    `Constructor ("TextFont", [])
  | MathFont ->
    `Constructor ("MathFont", [])

let font_to_value f =
  `Record [
    font_name_field_name, `LiteralString f.name;
    library_name_field_name, `LiteralString f.library_name;
    font_location_field_name, font_location_to_value f.location;
    font_type_field_name, font_type_to_value f.font_type;
  ]

let generate ~outf library_map =
  let records =
    Map.to_alist library_map
    |> List.map ~f:(fun (_, library) -> font_list ~outf library)
    |> List.join
    |> List.map ~f:font_to_value
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
