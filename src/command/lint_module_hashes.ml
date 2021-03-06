open Core
open Satyrographos
open Lint_prim


let lint_module_hashes ~outf:_ ~locs ~satysfi_version ~basedir ~env:_ (m : BuildScript.m) =
  let target_library =
    BuildScript.read_module ~src_dir:basedir m
  in
  target_library.hashes
  |> Library.LibraryFiles.to_alist
  |> List.concat_map ~f:(fun (file, (_, json)) ->
      match file with
      | "hash/fonts.satysfi-hash"
      | "hash/mathfonts.satysfi-hash" ->
        let problematic_fonts =
          match json with
          | `Assoc xs ->
            List.concat_map xs ~f:(function
                | (font_name, `Variant (_, Some (`Assoc loc)))->
                  let has_src_dist =
                    List.exists loc ~f:(function
                        | "src-dist", _ ->
                          Satyrographos_satysfi.Version.is_hash_font_src_dist_deprecated satysfi_version
                        | _ -> false
                      )
                  in
                  if has_src_dist
                  then [font_name]
                  else []
                | _ -> []
              )
          | _ -> []
        in
        [{
          locs;
          level = `Warning;
          problem = HashFontLocationSrcDist problematic_fonts;
        }]
      | _ ->
        []
    )
