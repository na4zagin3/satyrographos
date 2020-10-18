Prepare SATySFi source
  $ cat >first.saty <<EOF
  > @import: second
  > EOF
  $ cat >second.satyh <<EOF
  > @import: third
  > EOF
  $ cat >third.satyh <<EOF
  > EOF

Generate dependency graphs
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "third.satyh" [shape=box, ];
    "second" [shape=doubleoctagon, ];
    "third" [shape=doubleoctagon, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyh" [color="#000000", fontcolor="#000000",
                                label=".satyh", style="dashed", ];
    "third" -> "third.satyh" [color="#000000", fontcolor="#000000",
                              label=".satyh", style="dashed", ];
    "second.satyh" -> "third" [color="#002288", fontcolor="#002288",
                               label="@import: third", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    
    }
  $ SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos debug depgraph -S 0.0.5 --follow-required first.saty
  Compatibility warning: You have opted in to use experimental features.
  digraph G {
    "third.satyh" [shape=box, ];
    "second" [shape=doubleoctagon, ];
    "third" [shape=doubleoctagon, ];
    "second.satyh" [shape=box, ];
    "first.saty" [shape=box, ];
    
    
    "second" -> "second.satyh" [color="#000000", fontcolor="#000000",
                                label=".satyh", style="dashed", ];
    "third" -> "third.satyh" [color="#000000", fontcolor="#000000",
                              label=".satyh", style="dashed", ];
    "second.satyh" -> "third" [color="#002288", fontcolor="#002288",
                               label="@import: third", ];
    "first.saty" -> "second" [color="#002288", fontcolor="#002288",
                              label="@import: second", ];
    
    }
