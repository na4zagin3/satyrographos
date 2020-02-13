
let satysfi =
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
      echo OUTPUT=$1
      ;;
    *)
      MODE=process
      INPUT=$1
      echo INPUT=$1
      ;;
  esac
  shift
done
echo "$INPUT -> $OUTPUT" >&2
cat $INPUT > $OUTPUT
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
    echo 'Command invoked:'
    echo satysfi "$@" | sed -e 's!/tmp/\w*!@@build_temp_dir@@!'
    echo "$INPUT -> $OUTPUT"
    cat $INPUT > $OUTPUT
esac
}
    |}
  in
  String.concat "\n"
    [ "#!/bin/bash";
      "MODE=help";
      "INPUT=";
      "OUTPUT=";
      parse_options;
      payload;
      "parse_options \"$@\"";
      "payload \"$@\"";
    ]

let prepare_bin bin =
  let satysfi_path = FilePath.concat bin "satysfi" in
  let path = Unix.getenv "PATH" in
  let open Shexp_process in
  let open Infix in
  Unix.putenv "PATH" (bin ^ ":" ^ path);
  mkdir bin
  >> stdout_to satysfi_path (echo satysfi)
  >> chmod satysfi_path ~perm:0o755
