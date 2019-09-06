(* TODO Use some DB *)

open Core

module Uri_sexp = struct
  include Uri_sexp
  let compare = Uri.compare
end

type library_name = string
exception RegisteredAlready of library_name

module Libraries = String.Map
type entry = {
  url: Uri_sexp.t;
} [@@deriving sexp]

type t = {
  libraries: entry Libraries.t;
} [@@deriving sexp]

type store = string

let empty = {
  libraries = Libraries.empty;
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

let list reg = with_reading_file reg ~f:(fun m -> Libraries.keys m.libraries)
let find reg name = with_reading_file reg ~f:(fun m -> Libraries.find m.libraries name)
let mem reg name = with_reading_file reg ~f:(fun m -> Libraries.mem m.libraries name)
let remove reg name = with_modifying_file reg ~f:(fun m -> {libraries = Libraries.remove m.libraries name})
let remove_multiple reg names =
  let name_set = String.Set.of_list names in
  with_modifying_file reg ~f:(fun m ->
    {libraries = Libraries.filter_keys ~f:(Fn.compose (not) (String.Set.mem name_set)) m.libraries}
  )
let add reg name ent = with_modifying_file reg ~f:(fun m -> {libraries = Libraries.add_exn m.libraries ~key:name ~data:ent})

(* Tests *)
