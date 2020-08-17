open Core

module StringSet = Set.Make(String)

let name = "%fonts-system"
let system_font_prefix = "system:"

let blacklist = StringSet.of_list [
  (* Each SanFranciso font has several weights with the same postscriptname *)
  "/System/Library/Fonts/SFNSDisplay.ttf";
  "/System/Library/Fonts/SFNSText.ttf";
  "/System/Library/Fonts/SFNSTextItalic.ttf";
]

module Font = struct
  type t = {
    file: string;
    postscriptname: string;
    index: int;
    fontformat: string
  } [@@deriving sexp, compare]
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

let font_fields =
  ["file"; "postscriptname"; "index"; "fontformat"]

let fc_format_data_field field =
  Printf.sprintf "(%s \"%%{%s|cescape}\")" field field

let fc_format_data =
  List.map ~f:fc_format_data_field font_fields
  |> String.concat ~sep:" "
  |> Printf.sprintf "(%s)"

module DistinctFontMap = Map.Make(DistinctFont)

let font_list ~outf =
  Printf.sprintf "fc-list -f '%s'" fc_format_data (* TODO escape quotes *)
  |> Unix.open_process_in
  |> In_channel.input_all
  |> Printf.sprintf "(%s)"
  |> Sexp.of_string
  |> [%of_sexp: Font.t list] (* Use Parsexp.Many *)
  |> List.filter ~f:(fun f -> not (StringSet.mem blacklist f.file))
  |> List.map ~f:(fun f -> DistinctFont.of_font f, f)
  |> DistinctFontMap.of_alist_reduce ~f:(fun f1 f2 ->
      let sf1 = [%sexp_of: Font.t] f1 |> Sexp.to_string in
      let sf2 = [%sexp_of: Font.t] f2 |> Sexp.to_string in
      begin if not ([%compare.equal: Font.t] f1 f2)
        then Format.fprintf outf "WARNING: the following fonts look the same.\n%s\n%s\n@." sf1 sf2
      end;
      f1
    )
  |> DistinctFontMap.data

let satysfi_name (font: Font.t) =
  font.postscriptname

module FileMap = Map.Make(String)

let font_dir = "fonts/system/"
let font_filename_prefix = ""

(* TODO handle filename collision *)
let font_to_json_and_hash prefix f =
  let filename (f: Font.t) = font_filename_prefix ^ FilePath.basename f.file in
  let filepath (f: Font.t) = font_dir ^ filename f in
  let name (f: Font.t) = prefix ^ match f.postscriptname with
    | "" -> FilePath.basename f.file
    | psname -> psname
  in
  match f with
    | `Single f ->
      let value = `Assoc ["src", `String ("dist/" ^ filepath f)] in
      [(name f, `Variant ("Single", Some value)), (filepath f, f.file)]
    | `Collection fs ->
      List.map fs ~f:(fun f ->
        let value = `Assoc [
          "src", `String ("dist/" ^ filepath f);
          "index", `Int f.index
        ] in
        (name f, `Variant ("Collection", Some value)), (filepath f, f.file)
      )

let fonts_to_library ~outf prefix fonts =
  let add_variant = function
    | [] -> failwith "BUG: fonts_to_library"
    | [f] -> `Single f
    | fs -> `Collection fs
  in
  (* let stored_font_name font = FilePath.basename font.file in *)
  let (hash, files) = List.map ~f:(fun (f: Font.t) -> f.file, f) fonts
    |> FileMap.of_alist_multi
    |> FileMap.map ~f:add_variant
    |> FileMap.data
    |> List.concat_map ~f:(font_to_json_and_hash prefix)
    |> List.unzip
  in
  let hash_filename_fonts = "hash/fonts.satysfi-hash" in
  let map = Library.LibraryFiles.of_alist_reduce files ~f:(fun f1 f2 -> match f1, f2 with
        | f1, f2 ->
          begin if not (String.equal f1 f2)
            then Format.fprintf outf "WARNING: %s and %s have conflicting filename.@." f1 f2
          end;
          f1
    ) in
  let hash_path_fonts = "#Automatically generated from the system fonts#" in
  Library.{ empty with
    name = Some name;
    version = Some "0.1";
    hashes = LibraryFiles.singleton hash_filename_fonts ([hash_path_fonts], `Assoc hash);
    files = LibraryFiles.map map ~f:(fun fn -> `Filename fn)
  }

let get_library ~outf prefix () =
  font_list ~outf |> fonts_to_library ~outf prefix
