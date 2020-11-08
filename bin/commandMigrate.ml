open Core

let templates =
  Satyrographos_template.Template.templates

let template_map =
  Satyrographos_command.New.template_map

let help_templates () =
  Satyrographos_command.New.template_descriptions
  |> List.map ~f:(fun (k, d) -> Printf.sprintf "  %s : %s" k d)
  |> String.concat ~sep:"\n"

let migrate_command =
  let open Command.Let_syntax in
  let open RenameOption in
  let readme () =
    sprintf {|
Migrate an old project format for a new format.

Please take a backup beforehand.

|}
  in
  Command.basic
    ~summary:"Migrate an old project format for a new format (experimental)"
    ~readme
    [%map_open
      let buildscript_path = flag "--script" (optional string) ~doc:"SCRIPT Install script"
      in
      fun () ->
        Compatibility.optin ();
        let outf = Format.std_formatter in
        Format.fprintf outf "*WARNING*@.";
        Format.fprintf outf "Before migration, please ensure that `satyrographos lint` reports no problems.@ Otherwise, address them.@.";
        Format.fprintf outf "Additionally, please take a backup (e.g., committing changes to the git repo) beforehand.@.";
        Format.fprintf outf "Type “yes” if you are ready to proceed.@.";
        Format.fprintf outf "[yes/NO] ";
        Format.print_flush ();
        let response =
          In_channel.(input_line stdin)
          |> Option.map ~f:String.strip
        in
        begin if [%equal: string option] response (Some "yes")
        then Satyrographos_command.Migrate.migrate
            ~outf
            ~buildscript_path
        else Format.fprintf outf !"Canceled.@."
        end;
        reprint_err_warn ()
    ]
