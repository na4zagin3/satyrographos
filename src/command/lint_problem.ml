open Core

type problem =
  | ExceptionDuringSettingUpEnv of Exn.t
  | InternalBug of string
  | InternalException of Exn.t * string
  | LibraryBuildDeprecatedMakeCommand
  | LibraryMissingFile
  | LibraryVersionShouldNotBeEmpty
  | LibraryVersionShouldEndWithAnAlphanum of string
  | OpamPackageShouldHaveSatysfiDependencies of string list
  | OpamPackageShouldHaveVersion
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

let problem_class = function
  | ExceptionDuringSettingUpEnv _ ->
    "lib/dep/exception-during-setup"
  | InternalBug _ ->
    "internal/bug"
  | InternalException _ ->
    "internal/exception"
  | LibraryBuildDeprecatedMakeCommand ->
    "lib/build/deprecated/make"
  | LibraryMissingFile ->
    "lib/missing-file"
  | LibraryVersionShouldNotBeEmpty
  | LibraryVersionShouldEndWithAnAlphanum _ ->
    "lib/version"
  | OpamPackageShouldHaveSatysfiDependencies _ ->
    "opam-file/dependency"
  | OpamPackageShouldHaveVersion
  | OpamPackageVersionShouldBePrefixedWithLibraryVersion _ ->
    "opam-file/version"
  | OpamProblem (error_no, _) ->
    sprintf "opam-file/lint/%d" error_no
  | OpamPackageNamePrefix _ ->
    "opam-file/name"
  | SatyrographosCompatibliltyNoticeIneffective version ->
    sprintf
      "lib/compat/%s"
      version
  | SatysfiFileCyclicDependency _ ->
    "lib/dep/cyclic"
  | SatysfiFileMissingDependency _ ->
    "lib/dep/missing"

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
  | LibraryBuildDeprecatedMakeCommand ->
    Format.fprintf outf
      "(make <args>...) build command has been deprecated.@ Please use (make <args>...) instead and then `satyrographos satysfi ...` command instead of `satysfi -C $SATYSFI_RUNTIME ...`."
  | LibraryMissingFile ->
    Format.fprintf outf
      "Missing file"
  | LibraryVersionShouldNotBeEmpty ->
    Format.fprintf outf
      "Version should not be empty."
  | LibraryVersionShouldEndWithAnAlphanum version ->
    Format.fprintf outf
      "Library version “%s” should end with an alphabet or a digit." version
  | OpamPackageShouldHaveSatysfiDependencies libraries ->
    Format.fprintf outf
      !"The OPAM file lacks dependencies on specified SATySFi libraries: %{sexp:string list}."
      libraries
  | OpamPackageShouldHaveVersion ->
    Format.fprintf outf
      "OPAM file lacks the version field"
  | OpamPackageVersionShouldBePrefixedWithLibraryVersion {opam_version; module_version;} ->
    Format.fprintf outf
      "OPAM package version “%s” does not match “%s” specified in Satyristes.@;Hint: OPAM package version may be more specific than that in Satyristes, but not the other way around." opam_version module_version
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
        "@\n@;Hint: You may need to add dependency on “%s” to Satyristes."
        l
