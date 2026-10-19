# List installed style sets

Built-in sets ship with the package; user sets install under the user
data directory and survive package updates.

## Usage

``` r
designer_sets()
```

## Value

A data frame of sets with the library they live in (`core` or `user`),
the upstream repo they were installed from, and a style count.
