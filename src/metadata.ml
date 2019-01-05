(* TODO Use some DB *)

open Core

module Uri_sexp = struct
  include Uri_sexp
  let compare = Uri.compare
end

type package_name = string
exception RegisteredAlready of package_name

module Packages = String.Map
type entry = {
  url: Uri_sexp.t;
} [@@deriving sexp]

type t = {
  packages: entry Packages.t;
} [@@deriving sexp]

type store = string

let empty = {
  packages = Packages.empty;
}

let initialize file =
  empty
  |> [%sexp_of: t]
  |> Sexp.save_hum file

(* TODO Lock file *)
let with_reading_file file ~f =
  Sexp.load_sexp_conv_exn file [%of_sexp: t]
  |> f

(* TODO Lock file *)
let with_modifying_file file ~f =
  Sexp.load_sexp_conv_exn file [%of_sexp: t]
  |> f
  |> [%sexp_of: t]
  |> Sexp.save_hum file

let list reg = with_reading_file reg ~f:(fun m -> Packages.keys m.packages)
let find reg name = with_reading_file reg ~f:(fun m -> Packages.find m.packages name)
let mem reg name = with_reading_file reg ~f:(fun m -> Packages.mem m.packages name)
let remove reg name = with_modifying_file reg ~f:(fun m -> {packages = Packages.remove m.packages name})
let remove_multiple reg names =
  let name_set = String.Set.of_list names in
  with_modifying_file reg ~f:(fun m ->
    {packages = Packages.filter_keys ~f:(Fn.compose (not) (String.Set.mem name_set)) m.packages}
  )
let add reg name ent = with_modifying_file reg ~f:(fun m -> {packages = Packages.add_exn m.packages ~key:name ~data:ent})

(* Tests *)
