Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > @require: lib1
  > EOF
  $ cat >second.satyh <<EOF
  > @require: lib1
  > @require: lib2
  > EOF
  $ mkdir -p root/dist/packages
  $ cat >root/dist/packages/lib1.satyh <<EOF
  > EOF
  $ mkdir -p root/local/packages
  $ cat >root/local/packages/lib2.satyg <<EOF
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph --satysfi-root-dirs 'root' --follow-require first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "root/local/packages/lib2.satyg" [shape=box, ];
    "first.saty" [shape=box, ];
    "root/dist/packages/lib1.satyh" [shape=box, ];
    "second.satyh" [shape=box, ];
    
    
    "first.saty" -> "root/dist/packages/lib1.satyh" [color="#001267",
                                                     label="@require: lib1 (.satyh)",
                                                     ];
    "first.saty" -> "second.satyh" [color="#001267",
                                    label="@import: second (.satyh)", ];
    "second.satyh" -> "root/dist/packages/lib1.satyh" [color="#001267",
                                                       label="@require: lib1 (.satyh)",
                                                       ];
    "second.satyh" -> "root/local/packages/lib2.satyg" [color="#001267",
                                                        label="@require: lib2 (.satyg)",
                                                        ];
    
    }
