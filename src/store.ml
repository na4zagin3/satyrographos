open Core

type library_name = string
exception RegisteredAlready of library_name

type store = {
  library_dir: string;
}

(* Basic operations *)
let list reg = FileUtil.ls reg.library_dir |> List.map ~f:FilePath.basename |> List.sort ~compare:String.compare
let directory reg name = Filename.concat reg.library_dir name
let mem reg name = directory reg name |> FileUtil.test FileUtil.Is_dir
let remove_multiple reg names =
  List.map ~f:(directory reg) names |> FileUtil.rm ~force:Force ~recurse:true
let remove reg name =
  remove_multiple reg [name]
let add_dir reg name dir =
  let add_dir reg name dir = FileUtil.cp ~recurse:true [dir] (directory reg name) in
  match mem reg name, FileUtil.test FileUtil.Is_dir dir with
  | true, _ -> remove reg name; add_dir reg name dir
  | _, false -> failwith (dir ^ " is not a directory")
  | false, true -> add_dir reg name dir
  (* | false, false -> FileUtil.cp ~recurse:true [dir] (directory reg name) *)

let add_library reg name library =
  if mem reg name
  then failwith (Printf.sprintf "%s is already registered. Please remove it first." name)
  else Library.write_dir (directory reg name) library

let initialize libraries_dir =
  FileUtil.mkdir ~parent:true libraries_dir

let read library_dir = {
    library_dir = library_dir;
  }

(* Tests *)
open Core
let create_new_reg dir =
  let registry_dir = Filename.concat dir "registry" in
  initialize registry_dir;
  read registry_dir
let with_new_reg f =
  let dir = Filename.temp_dir "Satyrographos" "Store" in
  protect ~f:(fun () -> create_new_reg dir |> f) ~finally:(fun () -> FileUtil.rm ~force:Force ~recurse:true [dir])

let test_library_list ~expect reg =
  [%test_result: string list] ~expect (list reg)
let test_library_content ~expect reg p =
  [%test_result: string list] ~expect begin
    let target_dir = directory reg p in
    target_dir |> FileUtil.ls |> List.map ~f:(FilePath.make_relative target_dir)
  end

let%test "store: initialize" = with_new_reg (fun _ -> true)
let%test "store: list: empty" = with_new_reg begin fun reg ->
    list reg = []
  end
let%test_unit "store: add empty dir" = with_new_reg begin fun reg ->
    let dir = Filename.temp_dir "Satyrographos" "Library" in
    add_dir reg "a" dir;
    test_library_list ~expect:["a"] reg;
    [%test_result: bool] ~expect:true (mem reg "a");
    [%test_result: bool] ~expect:false (mem reg "b");
    [%test_result: bool] ~expect:true (directory reg "a" |> FileUtil.(test Is_dir ))
  end

let%test_unit "store: add nonempty dir" = with_new_reg begin fun reg ->
    let dir = Filename.temp_dir "Satyrographos" "Library" in
    FilePath.concat dir "c" |> FileUtil.touch;
    add_dir reg "a" dir;
    test_library_list ~expect:["a"] reg;
    [%test_result: bool] ~expect:true (mem reg "a");
    [%test_result: bool] ~expect:false (mem reg "b");
    [%test_result: bool] ~expect:true (directory reg "a" |> FileUtil.(test Is_dir));
    test_library_content ~expect:["c"] reg "a"
  end

let%test_unit "store: add nonempty dir twice" = with_new_reg begin fun reg ->
    let dir1 = Filename.temp_dir "Satyrographos" "Library" in
    FilePath.concat dir1 "c" |> FileUtil.touch;
    add_dir reg "a" dir1;
    test_library_list ~expect:["a"] reg;
    test_library_content ~expect:["c"] reg "a";
    let dir2 = Filename.temp_dir "Satyrographos" "Library" in
    FilePath.concat dir2 "d" |> FileUtil.touch;
    add_dir reg "a" dir2;
    test_library_list ~expect:["a"] reg;
    test_library_content ~expect:["d"] reg "a"
  end

let%test_unit "store: added dir must be copied" = with_new_reg begin fun reg ->
    let dir = Filename.temp_dir "Satyrographos" "Library" in
    FilePath.concat dir "c" |> FileUtil.touch;
    add_dir reg "a" dir;
    test_library_list ~expect:["a"] reg;
    test_library_content ~expect:["c"] reg "a";
    FilePath.concat dir "d" |> FileUtil.touch;
    test_library_list ~expect:["a"] reg;
    test_library_content ~expect:["c"] reg "a";
    FileUtil.rm [FilePath.concat dir "c"];
    test_library_list ~expect:["a"] reg;
    test_library_content ~expect:["c"] reg "a";
  end

let%test_unit "store: add the same directory twice with different contents" = with_new_reg begin fun reg ->
    let dir = Filename.temp_dir "Satyrographos" "Library" in
    FilePath.concat dir "c" |> FileUtil.touch;
    add_dir reg "a" dir;
    test_library_list ~expect:["a"] reg;
    test_library_content ~expect:["c"] reg "a";
    FilePath.concat dir "d" |> FileUtil.touch;
    FileUtil.rm [FilePath.concat dir "c"];
    add_dir reg "b" dir;
    test_library_list ~expect:["a"; "b"] reg;
    test_library_content ~expect:["c"] reg "a";
    test_library_content ~expect:["d"] reg "b";
  end
