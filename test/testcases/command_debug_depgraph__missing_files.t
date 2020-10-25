Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > @require: lib1
  > EOF
  $ mkdir root

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 --satysfi-root-dirs 'root' --follow-require first.saty missing.saty
  Compatibility warning: You have opted in to use experimental features.
  Cannot read files for “@import: second”
  Candidate basenames:
    - second
  
  Cannot read files for “@require: lib1”
  Candidate basenames:
    - root/dist/packages/lib1
    - root/local/packages/lib1
  
  digraph G {
    "second" [shape=doubleoctagon, ];
    "lib1" [shape=ellipse, ];
    "missing.saty" [shape=mdiamond, ];
    "first.saty" [shape=box, ];
    
    
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    "first.saty" -> "lib1" [color="#117722", fontcolor="#117722",
                            label="@require: lib1", ];
    
    }

Dep files
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos util deps-make -S 0.0.5 --depfile deps.d -o first.pdf --follow-required first.saty 2>&1 | sed -e "s!$HOME!@@HOME@@!g"
  Compatibility warning: You have opted in to use experimental features.
  Cannot read files for “@import: second”
  Candidate basenames:
    - second
  
  Cannot read files for “@require: lib1”
  Candidate basenames:
    - @@HOME@@/.satysfi/dist/packages/lib1
    - /usr/local/share/satysfi/dist/packages/lib1
    - /usr/share/satysfi/dist/packages/lib1
    - @@HOME@@/.satysfi/local/packages/lib1
    - /usr/local/share/satysfi/local/packages/lib1
    - /usr/share/satysfi/local/packages/lib1
  
  $ cat deps.d
  first.pdf: first.saty
  
  deps.d: first.saty
  
