
let satysfi log_file =
  let log_invocation =
{|
    echo 'Command invoked:' >> $LOG_FILE
    echo satysfi "$@" | sed -e 's!/tmp/ \w*!@@build_temp_dir@@!' >> $LOG_FILE
|} in
  let parse_options =
    {|
parse_options () {
while [ "$#" -ne "0" ] ; do
  case "$1" in
    --version)
      MODE=version
      return 0
      ;;
    -C)
      shift
      ;;
    -o)
      shift
      OUTPUT=$1
      ;;
    *)
      MODE=process
      INPUT=$1
      ;;
  esac
  shift
done
}
    |}
  in
  let payload =
    {|
payload () {
case "$MODE" in
  version)
    echo '  SATySFi version 0.0.3'
    ;;
  process)
    echo "$INPUT -> $OUTPUT" >> $LOG_FILE
    cat $INPUT > $OUTPUT
esac
}
    |}
  in
  String.concat "\n"
    [ "#!/bin/sh";
      "LOG_FILE='" ^ log_file ^"'";
      "MODE=help";
      "INPUT=";
      "OUTPUT=";
      log_invocation;
      parse_options;
      payload;
      "parse_options \"$@\"";
      "payload \"$@\"";
    ]

let prepare_bin bin log_file =
  let satysfi_path = FilePath.concat bin "satysfi" in
  let path = Unix.getenv "PATH" in
  let open Shexp_process in
  let open Infix in
  Unix.putenv "PATH" (bin ^ ":" ^ path);
  mkdir bin
  >> stdout_to satysfi_path (satysfi log_file |> echo)
  >> chmod satysfi_path ~perm:0o755
