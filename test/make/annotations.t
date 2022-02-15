---------------------------------------------------
NOTICE: @@ocaml.doc and @@merlin.hide annotations
& `include struct` boilerplate are added by ppxlib.
---------------------------------------------------

Test 1: Given a record type a annotated with `@main` for
one field, make_a will accept the main field as its last 
parameter
  $ test1="
  > type a = {
  >   x: int [@main] ;
  >   y: bool }[@@deriving make]"
  $ echo "$test1" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type a = {
    x: int [@main ];
    y: bool }[@@deriving make]
  include struct let make_a ~y  x = { x; y } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]
  $ echo "$test1" > test.mli
  $ driver test.mli 
  type a = {
    x: int [@main ];
    y: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_a : y:bool -> int -> a end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 2: Given a record type b annotated with `@main` for 
more than 1 field, throw error
  $ test2="
  > type b = {
  >   x: int ;
  >   y: bool [@main] ;
  >   z : string [@main]}[@@deriving make]"
  $ echo "$test2" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  File "test.ml", line 5, characters 2-20:
  5 |   z : string [@main]}[@@deriving make]
        ^^^^^^^^^^^^^^^^^^
  Error: Duplicate [@deriving.make.main] annotation
  [1]
  $ echo "$test2" > test.mli
  $ driver test.mli 
  File "test.mli", line 5, characters 2-20:
  5 |   z : string [@main]}[@@deriving make]
        ^^^^^^^^^^^^^^^^^^
  Error: Duplicate [@deriving.make.main] annotation
  [1]


Test 3: @default makes the field optional
  $ test3="
  > type c = {
  >   x: int [@default 5];
  >   y: bool }[@@deriving make]"
  $ echo "$test3" > test.mli
  $ driver test.mli 
  type c = {
    x: int [@default 5];
    y: bool }[@@deriving make]
  include
    sig [@@@ocaml.warning "-32"] val make_c : ?x:int -> y:bool -> unit -> c end
  [@@ocaml.doc "@inline"][@@merlin.hide ]
  $ echo "$test3" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type c = {
    x: int [@default 5];
    y: bool }[@@deriving make]
  include struct let make_c ?x  ~y  () = { x; y } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]


Test 6: Testing ppxlib: Unexpected attribute payload 
  $ test6="
  > type l = {
  >   x: int [@main 5] ;
  >   y: bool }[@@deriving make]"
  $ echo "$test6" > test.mli
  $ driver test.mli 
  File "test.mli", line 3, characters 16-17:
  3 |   x: int [@main 5] ;
                      ^
  Error: [] expected
  [1]

Test 7: Testing ppxlib: Unrecognized annotation
  $ test7="
  > type l = {
  >   x: int [@mein 5] ;
  >   y: bool }[@@deriving make]"
  $ echo "$test7" > test.mli
  $ driver -check test.mli 
  File "test.mli", line 3, characters 11-15:
  3 |   x: int [@mein 5] ;
                 ^^^^
  Error: Attribute `mein' was not used
  [1]
