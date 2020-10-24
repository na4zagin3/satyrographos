
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

let opam log_file =
  String.concat "\n"
    [ "#!/bin/sh";
      "LOG_FILE='" ^ log_file ^"'";
      {|echo 'Command invoked:' >> "$LOG_FILE"|};
      {|echo opam "$@" >> "$LOG_FILE"|};
    ]

(* TODO Refactor this so that bin_dir is implicitly shared by the main test function (e.g., test_install) *)
let prepare_bin bin log_file =
  let path = Unix.getenv "PATH" in
  let gen_bin name content =
    let path = FilePath.concat bin name in
    let open Shexp_process in
    let open Infix in
    mkdir ~p:() bin
    >> stdout_to path (content |> echo)
    >> chmod path ~perm:0o755
  in
  let open Shexp_process in
  let open Infix in
  Unix.putenv "PATH" (bin ^ ":" ^ path);
  gen_bin "satysfi" (satysfi log_file)
  >> gen_bin "opam" (opam log_file)
