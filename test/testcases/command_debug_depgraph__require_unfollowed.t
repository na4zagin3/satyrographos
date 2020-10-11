Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > @require: lib1
  > EOF
  $ cat >second.satyh <<EOF
  > @import: third
  > @require: lib1
  > @require: lib2
  > EOF
  $ cat >third.satyh <<EOF
  > @require: lib3
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "third.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    "lib2" [shape=box, ];
    "lib1" [shape=box, ];
    "lib3" [shape=box, ];
    "second.satyh" [shape=box, ];
    
    
    "third.satyh" -> "lib3" [color="#001267", label="@require: lib3", ];
    "first.saty" -> "second.satyh" [color="#001267",
                                    label="@import: second (.satyh)", ];
    "first.saty" -> "lib1" [color="#001267", label="@require: lib1", ];
    "second.satyh" -> "third.satyh" [color="#001267",
                                     label="@import: third (.satyh)", ];
    "second.satyh" -> "lib1" [color="#001267", label="@require: lib1", ];
    "second.satyh" -> "lib2" [color="#001267", label="@require: lib2", ];
    
    }
