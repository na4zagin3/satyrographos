open Core

let printed_err_warns = ref []

let print_err_warn ?(record=true) msg =
  if record
  then printed_err_warns := msg :: !printed_err_warns;
  Format.fprintf Format.err_formatter
    "\027[1;31m[OPTION DEPRECATION WARNING]\027[0m %s@."
      msg

let reprint_err_warn () =
  if not (List.is_empty !printed_err_warns)
  then begin
    print_err_warn ~record:false "";
    List.iter ~f:(print_err_warn ~record:false) !printed_err_warns;
    print_err_warn ~record:false ""
  end

let rename_option old_name old_value new_name new_value =
  let deprecated_warn () =
    Printf.sprintf
      "Option “%s” has been deprecated. Use “%s” instead."
        old_name new_name
    |> print_err_warn
  in
  match old_value, new_value with
    | Some value, None ->
      deprecated_warn ();
      Some value
    | Some _, Some value ->
      deprecated_warn ();
      Printf.sprintf
        "Both “%s” and “%s” are specified. Deprecated one is ignored."
          old_name new_name
      |> print_err_warn;
      Some value
    | None, value -> value

let rename_bool old_name old_value new_name new_value =
  rename_option old_name (Option.some_if old_value ()) new_name (Option.some_if new_value ())
  |> Option.is_some

let rename_list old_name old_value new_name new_value =
  let to_option = function
    | [] -> None
    | xs -> Some xs
  in
  let from_option = function
    | None -> []
    | Some xs -> xs
  in
  rename_option old_name (to_option old_value) new_name (to_option new_value)
  |> from_option

let long_flag_f rename_f arg_f ?doc_arg flag_name ?(aliases) arg ~doc =
  let open Command.Let_syntax in
  let doc_prefix = Option.map ~f:(fun x -> x ^ " ") doc_arg |> Option.value ~default:"" in
  [%map_open
    let new_opt = flag ("--" ^ flag_name) (arg_f arg) ?aliases ~doc:(doc_prefix ^ doc)
    and old_opt = flag (flag_name) (arg_f arg) ~doc:(doc_prefix ^ "Deprecated. Use --" ^ flag_name ^ " instead")
    in
      rename_f ("-" ^ flag_name) old_opt
        ("--" ^ flag_name) new_opt
  ]

let long_flag_optional ?doc_arg flag_name =
  long_flag_f rename_option Command.Flag.optional ?doc_arg flag_name

let long_flag_bool ?doc_arg flag_name =
  long_flag_f rename_bool (fun x -> x) ?doc_arg flag_name

let long_flag_listed ?doc_arg flag_name =
  long_flag_f rename_list Command.Flag.listed ?doc_arg flag_name
