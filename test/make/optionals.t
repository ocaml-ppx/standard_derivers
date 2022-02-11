---------------------------------------------------
NOTICE: @@ocaml.doc and @@merlin.hide annotations
& `include struct` boilerplate are added by ppxlib.
---------------------------------------------------

Test 1: Given a record type a with an `option` field, 
make_a will accept an optional param and have a unit 
at the end of its signature
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool option }[@@deriving make]"
  $ echo "$test1" > test.ml
  $ driver test.ml
  type a = {
    x: int ;
    y: bool option }[@@deriving make]
  include
    struct
      let _ = fun (_ : a) -> ()
      let make_a ~x  ?y  () = { x; y }
      let _ = make_a
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  $ echo "$test1" > test.mli
  $ driver test.mli 
  type a = {
    x: int ;
    y: bool option }[@@deriving make]
  include
    sig [@@@ocaml.warning "-32"] val make_a : x:int -> ?y:bool -> unit -> a end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 2: Given a record type b annotated with `@main` for
one field, make_b will accept the main field as its last 
parameter
  $ test2="
  > type b = {
  >   x: int [@main] ;
  >   y: bool }[@@deriving make]"
  $ echo "$test2" > test.ml
  $ driver test.ml
  type b = {
    x: int [@main ];
    y: bool }[@@deriving make]
  include
    struct
      let _ = fun (_ : b) -> ()
      let make_b ~y  x = { x; y }
      let _ = make_b
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  $ echo "$test2" > test.mli
  $ driver test.mli 
  type b = {
    x: int [@main ];
    y: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_b : y:bool -> int -> b end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 3: Given a record type c annotated with `@main` for 
more than 1 field, throw error
  $ test3="
  > type c = {
  >   x: int ;
  >   y: bool [@main] ;
  >   z : string [@main]}[@@deriving make]"
  $ echo "$test3" > test.ml
  $ driver test.ml
  File "test.ml", line 5, characters 2-20:
  5 |   z : string [@main]}[@@deriving make]
        ^^^^^^^^^^^^^^^^^^
  Error: Duplicate [@deriving.make.main] annotation
  [1]
  $ echo "$test3" > test.mli
  $ driver test.mli 
  File "test.mli", line 5, characters 2-20:
  5 |   z : string [@main]}[@@deriving make]
        ^^^^^^^^^^^^^^^^^^
  Error: Duplicate [@deriving.make.main] annotation
  [1]

Test 4: Given a record type d with an option field & a
@main field, make_d accepts the main field as the last  
parameter, and does not have a unit in the signature
  $ test4="
  > type d = {
  >   x: int ;
  >   y: bool [@main] ;
  >   z : string option}[@@deriving make]"
  $ echo "$test4" > test.ml
  $ driver test.ml
  type d = {
    x: int ;
    y: bool [@main ];
    z: string option }[@@deriving make]
  include
    struct
      let _ = fun (_ : d) -> ()
      let make_d ~x  ?z  y = { x; y; z }
      let _ = make_d
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  $ echo "$test4" > test.mli
  $ driver test.mli 
  type d = {
    x: int ;
    y: bool [@main ];
    z: string option }[@@deriving make]
  include
    sig [@@@ocaml.warning "-32"] val make_d : x:int -> ?z:string -> bool -> d
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 5: Given record type e with 2 option fields, one 
of which is also annotated with @main, make_e accepts 
the main field as the last param, which is of type 
`option` but is not optional
  $ test5="
  > type e = {
  >   x: int ;
  >   y: bool option [@main] ;
  >   z : string option}[@@deriving make]"
  $ echo "$test5" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type e = {
    x: int ;
    y: bool option [@main ];
    z: string option }[@@deriving make]
  include struct let make_e ~x  ?z  y = { x; y; z } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]
  $ echo "$test5" > test.mli
  $ driver test.mli 
  type e = {
    x: int ;
    y: bool option [@main ];
    z: string option }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      val make_e : x:int -> ?z:string -> bool option -> e
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

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
