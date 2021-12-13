open Core

let generate_lockdown ~verbose ~env ~buildscript =
  let open Satyrographos in
  let dependent_opam_packages =
    BuildScript.get_opam_dependencies buildscript
  in
  let autogen_libraries =
    (* TODO implement this *)
    []
    |> Set.of_list (module String)
  in
  let autogen =
    let module Autogen = Satyrographos_autogen.Autogen in
    Autogen.normal_libraries
    |> List.filter_map ~f:(fun (al: Autogen.t) ->
        if Set.mem autogen_libraries al.name
        then
          al.generate_persistent ()
          |> Option.map ~f:(fun persistent -> al.name, persistent)
        else None
      )
  in
  LockdownFile.make
    ~dependencies:
      (LockdownFile.Opam
         (OpamDependencies.get_opam_dependencies ~verbose ~env dependent_opam_packages))
    ~autogen

let restore_lockdown ~verbose (lockdown : LockdownFile.t) =
  begin match lockdown.dependencies with
      LockdownFile.Opam opam_dependencies ->
      OpamDependencies.restore_opam_dependencies
        ~verbose
        opam_dependencies
  end
