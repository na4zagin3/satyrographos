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
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 --satysfi-root-dirs 'root' --follow-require first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "root/local/packages/lib2.satyg" [shape=box, ];
    "root/dist/packages/lib1.satyh" [shape=box, ];
    "second" [shape=doubleoctagon, ];
    "lib1" [shape=ellipse, ];
    "lib2" [shape=ellipse, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyh" [color="#000000", fontcolor="#000000",
                                label=".satyh", style="dashed", ];
    "lib1" -> "root/dist/packages/lib1.satyh" [color="#000000",
                                               fontcolor="#000000",
                                               label=".satyh", style="dashed", ];
    "lib2" -> "root/local/packages/lib2.satyg" [color="#000000",
                                                fontcolor="#000000",
                                                label=".satyg", style="dashed", ];
    "second.satyh" -> "lib1" [color="#117722", fontcolor="#117722",
                              label="@require: lib1", ];
    "second.satyh" -> "lib2" [color="#117722", fontcolor="#117722",
                              label="@require: lib2", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    "first.saty" -> "lib1" [color="#117722", fontcolor="#117722",
                            label="@require: lib1", ];
    
    }

Dep files
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos util deps-make --satysfi-root-dirs 'root' -S 0.0.5 --depfile deps.d -o first.pdf --follow-required first.saty 2>&1 | sed -e "s!$HOME!@@HOME@@!g"
  Compatibility warning: You have opted in to use experimental features.
  $ cat deps.d
  first.pdf: first.saty second.satyh root/local/packages/lib2.satyg root/dist/packages/lib1.satyh
  
  deps.d: first.saty second.satyh root/local/packages/lib2.satyg root/dist/packages/lib1.satyh
  
