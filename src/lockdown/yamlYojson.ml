open Core


let rec yaml_of_yojson =
  let label s = Yaml.{
    anchor = None;
    tag = None;
    value = s;
    plain_implicit = true;
    quoted_implicit = true;
    style = `Any;
  }
  in
  function
  | `Assoc (lvs) ->
    `O (List.map lvs ~f:(fun (l, v) ->
        label l, yaml_of_yojson v
      ))
  | `Bool b ->
    `Scalar Yaml.{
    anchor = None;
    tag = Some "tag:yaml.org,2002:bool";
    value = string_of_bool b;
    plain_implicit = true;
    quoted_implicit = false;
    style = `Plain;
  }
  | `Float f ->
    `Scalar Yaml.{
      anchor = None;
      tag = Some "tag:yaml.org,2002:float";
      value = string_of_float f;
      plain_implicit = true;
      quoted_implicit = false;
      style = `Plain;
    }
  | `Int i ->
    `Scalar Yaml.{
      anchor = None;
      tag = Some "tag:yaml.org,2002:int";
      value = string_of_int i;
      plain_implicit = true;
      quoted_implicit = false;
      style = `Plain;
    }
  | `Intlit i ->
    `Scalar Yaml.{
      anchor = None;
      tag = Some "tag:yaml.org,2002:int";
      value = i;
      plain_implicit = true;
      quoted_implicit = false;
      style = `Plain;
    }
  | `List xs ->
    `A (List.map ~f:yaml_of_yojson xs)
  | `Null ->
    `Scalar Yaml.{
      anchor = None;
      tag = Some "tag:yaml.org,2002:null";
      value = "null";
      plain_implicit = true;
      quoted_implicit = false;
      style = `Plain;
    }
  | `String s ->
    begin match Option.try_with (fun () ->
        Yojson.Safe.from_string s
      )
      with
      | None ->
        `Scalar Yaml.{
            anchor = None;
            tag = Some "tag:yaml.org,2002:str";
            value = s;
            plain_implicit = true;
            quoted_implicit = true;
            style = `Any;
          }
      | Some _ ->
        `Scalar Yaml.{
            anchor = None;
            tag = Some "tag:yaml.org,2002:str";
            value = s;
            plain_implicit = false;
            quoted_implicit = true;
            style = `Any;
          }
    end
  | `Tuple _ ->
    failwithf "Non standard JSON is not accepted." ()
  | `Variant _ ->
    failwithf "Non standard JSON is not accepted." ()

let rec yojson_of_yaml =
  function
  | `O (lvs) ->
    `Assoc (List.map lvs ~f:(fun (l, v) ->
        l.Yaml.value, yojson_of_yaml v
      ))
  | `Scalar {Yaml.tag = Some "tag:yaml.org,2002:bool"; value = v; _} ->
    `Bool (bool_of_string v)
  | `Scalar {Yaml.tag = Some "tag:yaml.org,2002:float"; value = v; _} ->
    `Float (float_of_string v)
  | `Scalar {Yaml.tag = Some "tag:yaml.org,2002:int"; value = v; _} ->
      begin match int_of_string_opt v with
      | None -> `Intlit v
      | Some i -> `Int i
      end
  | `A ys ->
    `List (List.map ~f:yojson_of_yaml ys)
  | `Scalar {Yaml.tag = Some "tag:yaml.org,2002:null"; value = _; _}
  | `Scalar {Yaml.plain_implicit = true; value = "null"; _} ->
    `Null
  | `Scalar {Yaml.tag = Some "tag:yaml.org,2002:str"; value = v; _} ->
    `String v
  | `Scalar {Yaml.style = (`Double_quoted | `Single_quoted | `Folded); value = v; _} ->
    `String v
  | `Scalar {Yaml.plain_implicit = true; value = s; _} ->
    let v = Option.try_with (fun () ->
        Yojson.Safe.from_string s
      )
    in
    begin match v with
    | Some (`Bool _ as v)
    | Some (`Float _ as v)
    | Some (`Int _ as v)
    | Some (`Intlit _ as v) ->
      v
    | _ ->
      `String s
    end
  | y ->
    failwithf !"Unknown YAML object: %{sexp: Yaml.yaml}" y ()

let%test_unit "yaml_of_yojson: roundtrip" =
  let test json =
    let yaml = yaml_of_yojson json in
    let result = yojson_of_yaml yaml in
    if Yojson.Safe.equal json result
    then ()
    else failwithf "Round trip failed\nOriginal: %s\n\nYaml: %s\n\nConverted: %s"
        (Yojson.Safe.to_string json)
        (Yaml.yaml_to_string yaml |> Rresult.R.get_ok)
        (Yojson.Safe.to_string result)
        ()
  in
  let test_str json_str =
    Yojson.Safe.from_string json_str
    |> test
  in
  test_str "null";
  test_str "1";
  test_str "1.0";
  test_str "true";
  test_str "false";
  test_str {|""|};
  test_str {|"1"|};
  test_str {|"1.0"|};
  test_str {|"true"|};
  test_str {|"false"|};
  test_str {|100000000000000000000000000000000000000000|};
  test_str {|"null"|};
  test_str {|"{a:b}"|};
  test_str {|{"a":true}|};
