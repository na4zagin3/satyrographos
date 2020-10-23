module StdList = List

open Satyrographos_testlib
open Core

open Shexp_process

let satyristes =
{|
(version "0.0.2")
(library
  (name "grcnum")
  (version "0.2")
  (sources
    ((package "grcnum.satyh" "./grcnum.satyh")
     (font "grcnum-font.ttf" "./font.ttf")
     (hash "fonts.satysfi-hash" "./fonts.satysfi-hash")
     (file "doc/grcnum.md" "README.md")
     (fontDir "font")
     (packageDir "src")
    ))
  (opam "satysfi-grcnum.opam")
  (dependencies ((fonts-theano ())))
  (compatibility ((satyrographos 0.0.1))))
(libraryDoc
  (name "grcnum-doc")
  (version "0.2")
  (build
    ((satysfi "doc-grcnum.saty" "-o" "doc-grcnum-ja.pdf")))
  (sources
    ((doc "doc-grcnum-ja.pdf" "./doc-grcnum-ja.pdf")))
  (opam "satysfi-grcnum-doc.opam")
  (dependencies ((grcnum ())
                 (fonts-theano ()))))
|}

let () =
  let main ~outf ~temp_dir =
    let open Shexp_process.Infix in
    let log_file = FilePath.concat temp_dir "exec.log" in
    let pkg_dir = FilePath.concat temp_dir "pkg" in
    let prepare_pkg =
      PrepareDist.empty pkg_dir
      >> stdout_to (FilePath.concat pkg_dir "Satyristes") (echo satyristes)
      >> stdout_to (FilePath.concat pkg_dir "README.md") (echo "@@README.md@@")
      >> stdout_to (FilePath.concat pkg_dir "doc-example.saty") (echo "@@doc-example.saty@@")
    in
    let empty_dist = FilePath.concat temp_dir "empty_dist" in
    let prepare_dist = PrepareDist.empty empty_dist in
    let opam_reg = FilePath.concat temp_dir "opam_reg" in
    let bin_dir = FilePath.concat temp_dir "bin" in
    let system_font_prefix = None in
    let autogen_libraries = [] in
    let libraries = Some [] in
    let verbose = true in
    let project_env = Some Satyrographos.Environment.{
        buildscript_path = FilePath.concat pkg_dir "Satyristes";
        satysfi_runtime_dir = FilePath.concat pkg_dir "_build/satysfi";
      }
    in
    let cmd =
      PrepareBin.prepare_bin bin_dir log_file
      >> prepare_pkg
      >> prepare_dist
      >>| TestLib.read_env ~opam_reg ~dist_library_dir:empty_dist
      >>= fun env ->
      Satyrographos_command.RunSatysfi.satysfi_command
        ~outf
        ~system_font_prefix
        ~autogen_libraries
        ~libraries
        ~verbose
        ~project_env
        ~env
        [FilePath.concat pkg_dir "doc-example.saty"; "-o"; FilePath.concat pkg_dir "doc-example.pdf";]
      >>= (fun exit_code ->
          if exit_code <> 0
          then sprintf "Non zero exit code: %d" exit_code |> echo
          else return ())
      >> TestLib.echo_line
      >> stdin_from log_file (iter_lines echo)
      >> TestLib.echo_line
    in
    TestLib.with_bin_dir bin_dir cmd
  in
  let open Shexp_process.Infix in
  eval (
    Shexp_process.with_temp_dir ~prefix:"Satyrographos" ~suffix:"satysfi" (fun temp_dir ->
        TestLib.with_formatter_map (fun outf ->
            main ~outf ~temp_dir
          )
      )
    |- TestLib.censor_tempdirs
  )

