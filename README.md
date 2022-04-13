# Standard `Ppxlib.Deriving` derivers

This repo is a work in progress. Its goal is to create something similar to the old [`ppx_deriving` standard plugins](https://github.com/ocaml-ppx/ppx_deriving/tree/master/src_plugins) for `Ppxlib.Deriving`.

So far, there is no such thing as a unified place with the most standard `Ppxlib.Deriving` derivers. That leads to the situation that some of the old `ppx_deriving` standard plugins have a `Ppxlib.Deriving` version somewhere out there and others don't. The idea of this project is to adapt and unify the ones out there on two different levels: adapt them to coherently respect the same conventions and standards; merge them into the same repo and package. Notice that some of the original derivers, such as the Jane Street ones, will keep on co-existing since they fulfill a different purpose as well.

## What's the need for this project?

There are different points of motivation for this project.

#### Find all derivers easily

Not knowing where to find the `Ppxlib.Deriving` derivers is the main reason for sticking to the `ppx_deriving` ones.

#### No extra dependencies

Another reason for sticking to the `ppx_deriving` derivers is avoiding the dependencies some of the currently existing `Ppxlib.Deriving` derivers pull in. For example, the Jane Street ones tend to depend on `base`.

#### Ease portability from `ppx_deriving.std`

Unless there's a good reason not to, we'll stick to the same naming and syntax as in the `ppx_deriving` plugins. That will make it as easy as possible to move from the `ppx_deriving` ones to these ones.

#### Hygienic base ecosystem

We'll make sure that the derivers here meet good standards so that people can trust them. That includes good error reporting, using fully qualified names for the derived values, and having a solid set of tests. We also make sure not to use polymorphic comparisons, because the code generated by a deriver should not depend on the environment in scope.  E.g. rather than `foo = []`, we do `match foo with [] ->`, to eliminate the use of `=`, which might be overwritten in the environment.

#### Serve as how-to guides

Another advantage of the last point is that the code of these derivers can serve as examples of how to write a deriver.

#### Re-use the driver

One technical advantage of this project is that it will increase the number of files in a project applying the same set of ppx rewriters. Since in that case the ppx driver can be re-used that implies improving performance.

#### Make `Ppxlib.Deriving` even more of an official standard

All those points mentioned above might help folks move even more from the sustained `ppx_deriving` to the maintained `ppxlib`.

#### Allow to avoid PPX dependencies

One important feature of `Ppxlib.Deriving` is `deriving_inline`. When using a deriver via `deriving_inline`, both the deriver and the PPX library behind it are only required for development. So, in contrary to `ppx_deriving.std`, this project will allow to use the standard derivers without declaring them or anything related to them as a hard dependency.

## Who's implementing this project?

@ayc9 is implementing this project as part of an [Outreachy internship](https://www.outreachy.org/) with the OCaml community. The derivers we plan to include are originally written by Jane Street (`ord` and `eq` will come from [`ppx_compare`](https://github.com/janestreet/ppx_compare); the basic structure of `make` will come from [`ppx_fields_conv`](https://github.com/janestreet/ppx_fields_conv)) and by @thierry-martinez (`show` and `pp` will come from [`ppx_show`](https://github.com/thierry-martinez/ppx_show)).

## `make` 

The `make` deriver generates a constructor function for a given record type `t`. The derived function, `make_t`, accepts labelled arguments for each field in the record. `make_t` is then used to construct records of type `t`. Note that:
- A `[@main]` annotation can be added to specify a field to be the last argument of the constructor function. This main argument will not be labelled.
- A `[@default]` annotation can be added to specify a default value for a given field. Its corresponding argument will be optional. 
- Fields of `list` type are automatically set with a default of `[]`.
- If the generated constructor function has optional arguments, it will require the unit `()` as a last argument, except in the case it also has a main argument. 

``` ocaml
type t = {
  x : int;
  l : int list;
  o : int option;
  m : int [@main];
  d : int [@default 0] 
} [@@deriving make];;

val make_t : x:int -> ?l:int list -> ?o:int -> ?d:int -> int -> t
let make_t ~x  ?(l= [])  ?o  ?(d= 0)  m = { x; l; o; m; d }
```
