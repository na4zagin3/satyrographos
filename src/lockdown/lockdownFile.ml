open Core

let version = "0.0.3"

module Json = struct
  include Satyrographos.Library.Json
  let to_yojson = ident
  let of_yojson x = Result.Ok x
end

type opam_package = {
  name: string;
  version: string;
}
[@@deriving equal, sexp, yojson]

let x =
  opam_package_of_yojson
type opam_dependencies = {
  packages: opam_package list;
}
[@@deriving equal, sexp, yojson]

type dependencies =
  | Opam of opam_dependencies
[@@deriving equal, sexp, yojson]

type autogen = (string * Json.t) list
[@@deriving equal, sexp]

let autogen_to_yojson lvs =
  `Assoc lvs

let autogen_of_yojson (j : Yojson.Safe.t) =
  match j with
  | `Assoc lvs ->
    Result.Ok lvs
  | _ ->
    Result.Error "autogen_of_yojson: Invalid form"

type t = {
  satyrographos: string;
  dependencies: dependencies;
  autogen: autogen;
}
[@@deriving equal, sexp, yojson]


let make ~dependencies ~autogen = {
  satyrographos = version;
  dependencies;
  autogen;
}

let error_msg_to_invalid_arg res =
  res
  |> Result.map_error ~f:(function `Msg m -> m)
  |> Result.ok_or_failwith

let save_file_exn f ld =
  Out_channel.with_file f ~f:(fun oc ->
      let str =
        to_yojson ld
        |> YamlYojson.yaml_of_yojson
        |> Yaml.yaml_to_string
      in
      str
      |> error_msg_to_invalid_arg
      |> Out_channel.output_string oc
    )

let load_file_exn f =
  In_channel.read_all f
  |> Yaml.yaml_of_string
  |> error_msg_to_invalid_arg
  |> YamlYojson.yojson_of_yaml
  |> of_yojson
  |> Result.ok_or_failwith
