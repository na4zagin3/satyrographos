open Core

module Json = Json_derivers.Yojson
module Library = Satyrographos.Library

let migrate_font_src ~outf (l: Library.t) =
  let migrate_font_hash_variant_entry ~outf names = function
    | ("src-dist", `String src_dist) ->
      "src", `String ("dist/fonts/" ^ src_dist)
    | ("src-dist", j) ->
      Format.fprintf outf "Invalid value in hash %s: %s. Ignored.@."
        ([%sexp_of: string list] names |> Sexp.to_string_hum)
        (Library.Json.to_string j);
      "src-dist", j
    | e ->
      e
  in
  let migrate_font_hash_variant_entry names = function
    | `Variant (font_type, Some (`Assoc xs)) ->
      let xs =
        List.map xs ~f:(migrate_font_hash_variant_entry ~outf names)
      in
      `Variant (font_type, Some(`Assoc xs))
    | j -> j
  in
  let migrate_font_hash names (j: Json.t) = match j with
    | `Assoc xs ->
      `Assoc (List.map xs ~f:(fun (font_name, variant) ->
          font_name, migrate_font_hash_variant_entry names variant))
    | j -> j
  in
  let hashes =
    Library.LibraryFiles.mapi l.hashes ~f:(fun ~key ~data -> match key with
        | "hash/fonts.satysfi-hash"
        | "hash/mathfonts.satysfi-hash" ->
          let names, j = data in
          names, migrate_font_hash names j
        | _ ->
          data
      )
  in
  { l with hashes }

let%expect_test "migrate_font_src: valid" =
  { name = Some "fonts-l";
    version = Some "0.1";
    files = Library.LibraryFiles.empty;
    hashes =
      ["hash/fonts.satysfi-hash", (["name1"], `Assoc [
           "font1", `Variant ("Single", Some (`Assoc [
               "src-dist", `String "fonts-l/font1.otf";
             ]))
         ]);
       "hash/mathfonts.satysfi-hash", (["name1"], `Assoc [
           "font2", `Variant ("Single", Some (`Assoc [
               "src-dist", `String "fonts-l/font2.otf";
             ]))
         ]);
       "hash/default-font.satysfi-hash", (["name1"], `Assoc [
           "han-ideographic", `Assoc [
               "ratio", `Float 0.8;
             ];
         ]);
      ]
      |> Library.LibraryFiles.of_alist_exn;
    compatibility = Library.Compatibility.empty;
    dependencies = Library.Dependency.empty;
    autogen = Library.Dependency.empty;
  }
  |> migrate_font_src ~outf:Format.std_formatter
  |> printf !"%{sexp: Library.t}";
  [%expect {|
    ((name (fonts-l)) (version (0.1))
     (hashes
      ((hash/default-font.satysfi-hash
        ((name1) (Assoc ((han-ideographic (Assoc ((ratio (Float 0.8)))))))))
       (hash/fonts.satysfi-hash
        ((name1)
         (Assoc
          ((font1
            (Variant
             (Single ((Assoc ((src (String dist/fonts/fonts-l/font1.otf))))))))))))
       (hash/mathfonts.satysfi-hash
        ((name1)
         (Assoc
          ((font2
            (Variant
             (Single ((Assoc ((src (String dist/fonts/fonts-l/font2.otf))))))))))))))) |}]

let migrate ~outf (buildscript_version: Satyrographos.BuildScript.version) satysfi_version l =
  match buildscript_version with
  | Lang_0_0_2 when Version.is_hash_font_src_dist_deprecated satysfi_version ->
    l |> migrate_font_src ~outf
  | _ ->
    l
