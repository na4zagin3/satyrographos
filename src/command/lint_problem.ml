open Core

type problem =
  | ExceptionDuringSettingUpEnv of Exn.t
  | InternalBug of string
  | InternalException of Exn.t * string
  | LibraryMissingFile
  | LibraryVersionShouldNotBeEmpty
  | LibraryVersionShouldEndWithAnAlphanum of string
  | OpamFileShouldHaveVersion
  | OpamPackageShouldHaveSatysfiDependencies of string list
  | OpamPackageVersionShouldBePrefixedWithLibraryVersion of {
      opam_version: string;
      module_version: string;
    }
  | OpamProblem of int * string
  | OpamPackageNamePrefix of {
      opam_name: string;
      module_name: string;
    }
  | SatyrographosCompatibliltyNoticeIneffective of string
  | SatysfiFileCyclicDependency of
      Satyrographos_satysfi.Mode.t
  | SatysfiFileMissingDependency of {
      directive: Satyrographos_satysfi.Dependency.directive;
      suggested_dependency: string option;
      modes: Satyrographos_satysfi.Mode.t list;
    }
[@@deriving sexp_of]

let show_problem ~outf = function
  | ExceptionDuringSettingUpEnv exn ->
    Format.fprintf outf
      !"Exception during setting up the env. Install dependent libraries by `opam pin add \"file://$PWD\"`.\n%{sexp:Exn.t}"
      exn
  | InternalBug msg ->
    Format.fprintf outf
      "BUG: %s" msg
  | InternalException (exn, stacktrace) ->
    Format.fprintf outf
      "Exception:@;";
    Exn.pp outf
      exn;
    Format.fprintf outf
      "@;%s" stacktrace
  | LibraryMissingFile ->
    Format.fprintf outf
      "Missing file"
  | LibraryVersionShouldNotBeEmpty ->
    Format.fprintf outf
      "Version should not be empty."
  | LibraryVersionShouldEndWithAnAlphanum version ->
    Format.fprintf outf
      "Library version “%s” should end with an alphabet or a digit." version
  | OpamFileShouldHaveVersion ->
    Format.fprintf outf
      "OPAM file lacks the version field"
  | OpamPackageShouldHaveSatysfiDependencies libraries ->
    Format.fprintf outf
      !"The OPAM file lacks dependencies on specified SATySFi libraries: %{sexp:string list}."
      libraries
  | OpamPackageVersionShouldBePrefixedWithLibraryVersion {opam_version; module_version;} ->
    Format.fprintf outf
      "OPAM package version “%s” should be prefixed with “%s”." opam_version module_version
  | OpamProblem (error_no, msg) ->
    Format.fprintf outf
      "(%d) %s" error_no msg
  | OpamPackageNamePrefix {opam_name; module_name} ->
    Format.fprintf outf
      "OPAM package name “%s” should be “satysfi-%s”." opam_name module_name
  | SatyrographosCompatibliltyNoticeIneffective version ->
    Format.fprintf outf
      "Compatibility warnings for Satyrographos %s libraries are no longer effective."
      version
  | SatysfiFileCyclicDependency mode ->
    let open Satyrographos_satysfi in
    Format.fprintf outf
      !"Cyclic dependency found for mode %{sexp:Mode.t}" mode
  | SatysfiFileMissingDependency {directive; suggested_dependency; modes;} ->
    let open Satyrographos_satysfi in
    Format.fprintf outf
      !"Missing dependency for “%s” (mode %{sexp:Mode.t list})"
      (Dependency.render_directive directive)
      (List.sort ~compare:Mode.compare modes);
    match suggested_dependency with
    | None -> ()
    | Some l ->
      Format.fprintf outf
        "\n@;Hint: You may need to add dependency on “%s” to Satyristes."
        l
