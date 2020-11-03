open Core

let version = "0.0.3"

type opam_package = {
  name: string;
  version: string;
}
[@@deriving equal, sexp, yojson]

type opam_dependencies = {
  packages: opam_package list;
}
[@@deriving equal, sexp, yojson]

type dependencies =
  | Opam of opam_dependencies
[@@deriving equal, sexp, yojson]

type t = {
  satyrographos: string;
  dependencies: dependencies;
}
[@@deriving equal, sexp, yojson]


let make ~dependencies = {
  satyrographos = version;
  dependencies;
}

let save_file_exn f ld =
  Out_channel.with_file f ~f:(fun oc ->
      let str =
        to_yojson ld
        |> YamlYojson.yaml_of_yojson
        |> Yaml.yaml_to_string
      in
      str
      |> Rresult.R.error_msg_to_invalid_arg
      |> Out_channel.output_string oc
    )

let load_file_exn f =
  In_channel.read_all f
  |> Yaml.yaml_of_string
  |> Rresult.R.error_msg_to_invalid_arg
  |> YamlYojson.yojson_of_yaml
  |> of_yojson
  |> Result.ok_or_failwith
