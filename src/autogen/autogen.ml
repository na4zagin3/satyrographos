type t = {
  name: string;
  generate_persistent: unit -> Yojson.Safe.t option;
  generate:
    outf:Format.formatter ->
    persistent_yojson:Yojson.Safe.t option -> Satyrographos.Library.t
}

let normal_libraries = [
  { name=Today.name;
    generate_persistent=Today.generate_persistent_opt;
    generate=Today.generate;
  }
]
