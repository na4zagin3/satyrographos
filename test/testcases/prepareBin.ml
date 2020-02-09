
let satysfi =
  let payload =
    {|
payload () {
INPUT=
OUTPUT=
while [ "$#" -ne "0" ] ; do
  case "$1" in
    --version)
      echo '  SATySFi version 0.0.3'
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
  String.concat "\n"
    [ "#!/bin/bash";
      payload;
      "echo 'Command invoked:' >&2";
      "echo satysfi \"$@\" | sed -e 's!/tmp/\\w*!@@build_temp_dir@@!' >&2";
      "payload \"$@\"";
      "echo >&2";
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
