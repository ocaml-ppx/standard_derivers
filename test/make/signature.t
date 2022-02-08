---------------------------------------------------
NOTICE: @@ocaml.doc and @@merlin.hide annotations
& `include struct` boilerplate are added by ppxlib.
---------------------------------------------------

Test 1: Given a regular record type a, expose make_a
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test1" > test.mli
  $ driver test.mli 
  type a = {
    x: int ;
    y: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_a : x:int -> y:bool -> a end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 2: Given a nonrec type, throw error
  $ test2="
  > type nonrec b = {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test2" > test.mli
  $ driver test.mli
  File "test.mli", lines 2-4, characters 0-28:
  2 | type nonrec b = {
  3 |   x: int ;
  4 |   y: bool }[@@deriving make]
  Error: nonrec is not compatible with the `make' preprocessor.
  [1]

Test 3: Given a non-record type, throw error
  $ test3="
  > type c = int * int
  > [@@deriving make]"
  $ echo "$test3" > test.mli
  $ driver test.mli
  File "test.mli", lines 2-3, characters 0-17:
  2 | type c = int * int
  3 | [@@deriving make]
  Error: Unsupported use of make (you can only use it on records).
  [1]

Test 4: Given a private type, throw error
  $ test4="
  > type d = private {
  >   x: int ;
  >   y: bool }[@@deriving make]"
  $ echo "$test4" > test.mli
  $ driver test.mli
  File "test.mli", line 2, characters 5-6:
  2 | type d = private {
           ^
  Error: We cannot expose functions that explicitly create private records.
  [1]

Test 5: Given recursive types which are exclusively
record types, expose 1 make function for each record 
  $ test5="
  > type e = {
  >   v: f ;
  >   w: bool }
  > and f = {
  >   x: int ;
  >   mutable y: bool ;
  >   z: e }[@@deriving make]"
  $ echo "$test5" > test.mli
  $ driver test.mli
  type e = {
    v: f ;
    w: bool }
  and f = {
    x: int ;
    mutable y: bool ;
    z: e }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      val make_e : v:f -> w:bool -> e
      val make_f : x:int -> y:bool -> z:e -> f
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 6: Given recursive types with at least one 
record type, expose 1 make function for each type 
  $ test6="
  > type g = int*h
  > and h = {
  >   v: g ;
  >   w: bool }[@@deriving make]"
  $ echo "$test6" > test.mli  
  $ driver test.mli
  type g = (int * h)
  and h = {
    v: g ;
    w: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_h : v:g -> w:bool -> h end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 7: Given recursive types without any record
types, throw error
  $ test7="
  > type i = int*j
  > and j = bool*i [@@deriving make]"
  $ echo "$test7" > test.mli  
  $ driver test.mli
  File "test.mli", lines 2-3, characters 0-32:
  2 | type i = int*j
  3 | and j = bool*i [@@deriving make]
  Error: make can only be applied on type definitions in which at least one type definition is a record.
  [1]

Test 8: Given a record type k with an `option` 
field, expose make_k with a unit at the end
  $ test8="
  > type k = {
  >   x: int ;
  >   y: bool option }[@@deriving make]"
  $ echo "$test8" > test.mli
  $ driver test.mli 
  type k = {
    x: int ;
    y: bool option }[@@deriving make]
  include
    sig [@@@ocaml.warning "-32"] val make_k : x:int -> ?y:bool -> unit -> k end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 9: Given a record type l annotated with `@main` for
one field, expose make_l with the main field at the end
  $ test9="
  > type l = {
  >   x: int [@main] ;
  >   y: bool }[@@deriving make]"
  $ echo "$test9" > test.mli
  $ driver test.mli 
  type l = {
    x: int [@main ];
    y: bool }[@@deriving make]
  include sig [@@@ocaml.warning "-32"] val make_l : y:bool -> x:int -> l end
  [@@ocaml.doc "@inline"][@@merlin.hide ]

Test 10: Given a record type m annotated with `@main` for
more than 1 field, throw error
  $ test10="
  > type m = {
  >   x: int ;
  >   y: bool [@main] ;
  >   z : string [@main]}[@@deriving make]"
  $ echo "$test10" > test.mli
  $ driver test.mli 
  File "test.mli", line 4, characters 2-19:
  4 |   y: bool [@main] ;
        ^^^^^^^^^^^^^^^^^
  Error: Duplicate [@deriving.make.main] annotation
  [1]

Test 11: Given a record type n annotated with 1 option field
and 1 @main field, expose make_n with the main field at the 
end, and without a unit in the signature
  $ test11="
  > type n = {
  >   x: int ;
  >   y: bool [@main] ;
  >   z : string option}[@@deriving make]"
  $ echo "$test11" > test.mli
  $ driver test.mli 
  type n = {
    x: int ;
    y: bool [@main ];
    z: string option }[@@deriving make]
  include
    sig [@@@ocaml.warning "-32"] val make_n : x:int -> ?z:string -> y:bool -> n
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 11: Given a record type n annotated with 1 option field
and 1 @main field, expose make_n with the main field at the 
end, and without a unit in the signature
  $ test12="
  > type n = {
  >   x: int ;
  >   y: bool option [@main] ;
  >   z : string option}[@@deriving make]"
  $ echo "$test12" > test.mli
  $ driver test.mli 
  type n = {
    x: int ;
    y: bool option [@main ];
    z: string option }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      val make_n : x:int -> ?z:string -> y:bool option -> n
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
