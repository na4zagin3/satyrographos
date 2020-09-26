open Core

let templates =
  Satyrographos_template.Template.templates

let template_map =
  templates
  |> List.map ~f:(fun (k, (_, fs)) -> k, fs)
  |> String.Map.of_alist_exn

let template_descriptions =
  templates
  |> List.map ~f:(fun (k, (d, _)) -> k, d)

let licenses = [
  "MIT";
  "LGPL-3.0-or-later";
]

let input_if_missing f = function
  | Some value -> value
  | None ->
    f ()

let rec choose_license () =
  let license_list =
    List.mapi ~f:(sprintf "%d) %s") licenses
    |> String.concat ~sep:"\n"
  in
  printf "Choose licenses:\n%s\n> " license_list;
  let result =
    let (let>>=) = Option.(>>=) in
    let>>= i = read_int_opt () in
    let>>= l = List.nth licenses i in
    Some l
  in
  match result with
  | Some l -> l
  | None ->
    printf "Not a valid answer.\n";
    choose_license ()

let validate_name =
  let re =
    let open Re in
    seq [
      start;
      rep (Re.alt [wordc; char '-']);
      stop;
    ] |> compile
  in
  let f name =
    Re.matches re name
    |> List.is_empty
    |> not
  in
  f

let%test "validate_name: accepts “abc”" =
  validate_name "abc"

let%test "validate_name: accepts “abc-def”" =
  validate_name "abc-def"

let%test "validate_name: rejects “abc.def”" =
  validate_name "abc.def" |> not

let%test "validate_name: rejects “abc*def”" =
  validate_name "abc*def" |> not

let%test "validate_name: rejects “abc+def”" =
  validate_name "abc+def" |> not

let%test "validate_name: rejects “../def”" =
  validate_name "../def" |> not

let%test "validate_name: rejects “abc def”" =
  validate_name "abc def" |> not

let create_project name license files =
  if validate_name name |> not
  then begin
    Printf.printf "Project name should consist of ASCII alphabets, numbers, underscores, or hyphens.\n";
    exit 1
  end;
  if FileUtil.(test Exists name)
  then begin
    Printf.printf "%s already exists.\n" name;
    exit 1
  end;
  Printf.printf "Name: %s\n" name;
  let license = input_if_missing choose_license license in
  Printf.printf "License: %s\n" license;
  let vars = [
    "library", name;
    "license", license;
    "satysfi_version", {|>= "0.0.5" & < "0.0.6"|};
    "satyrographos_version", {|>= "0.0.2.6" & < "0.0.3"|};
  ] in
  Satyrographos_template.Template.create_files
    ~basedir:name
    vars
    files;
  Printf.printf "Created a new library/document.\n"

