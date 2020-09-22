let template_re =
  let open Re in
  seq [
    str {|@@|};
    rep (Re.alt [wordc; char ':']) |> group;
    str {|@@|};
  ] |> compile

let hyphen_re =
  let open Re in
  seq [
    char '-';
    rg 'a' 'z' |> group;
  ] |> compile

let camelize str =
  let f g = String.uppercase_ascii (Re.Group.get g 1) in
  Re.replace hyphen_re ~all:true ~f str
  |> String.capitalize_ascii

let replace_template vars =
  let expand_var (v, t) =
    [ v, t;
      v ^ ":camel", camelize t;
    ]
  in
  let vars = List.map expand_var vars |> List.concat in
  let f g = List.assoc (Re.Group.get g 1) vars in
  (fun s -> Re.replace template_re ~all:true ~f s)

let create_file ~basedir vars (name, content) =
  let name = replace_template vars name |> FilePath.concat basedir in
  let content = replace_template vars content in
  FileUtil.(mkdir ~parent:true (FilePath.dirname name));
  let oc = open_out name in
  try
    output_string oc content
  with e ->
    close_out_noerr oc;
    raise e

let create_files ~basedir vars templ =
  List.iter (create_file ~basedir vars) templ

let templates = [
  "lib", ("Package library", TemplateLib.files);
]
