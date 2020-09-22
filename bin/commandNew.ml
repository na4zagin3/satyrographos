open Core

let templates =
  Satyrographos_template.Template.templates

let template_map =
  Satyrographos_command.New.template_map

let help_templates () =
  Satyrographos_command.New.template_descriptions
  |> List.map ~f:(fun (k, d) -> Printf.sprintf "  %s : %s" k d)
  |> String.concat ~sep:"\n"

let new_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let readme () =
    sprintf {|
Create a new SATySFi document/library from a chosen template.

Available templates:
%s|} (help_templates ())
  in
  Command.basic
    ~summary:"Create a new SATySFi document/library"
    ~readme
    [%map_open
      let template = anon ("TEMPLATE" %: Arg_type.of_map template_map)
      and name = anon ("NAME" %: string)
      and license = flag "--license" (optional string) ~doc:"LICENSE License"
      in
      fun () ->
        Compatibility.optin ();
        Satyrographos_command.New.create_project
          name
          license
          template;
        reprint_err_warn ()
    ]
