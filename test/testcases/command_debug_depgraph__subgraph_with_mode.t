Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > EOF
  $ cat >second.satyh <<EOF
  > EOF
  $ cat >second.satyh-md <<EOF
  > EOF
  $ cat >second.satyg <<EOF
  > EOF


Generate dependency graphs for satyh
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 --mode pdf first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second" [shape=doubleoctagon, ];
    "second.satyh" [shape=box, ];
    "second.satyg" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyg" [color="#000000", fontcolor="#000000",
                                label=".satyg", style="dashed", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    
    }

Generate dependency graphs for satyh-md
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 --mode text-md first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "second.satyh-md" [shape=box, ];
    "second" [shape=doubleoctagon, ];
    "second.satyg" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyg" [color="#000000", fontcolor="#000000",
                                label=".satyg", style="dashed", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    
    }
