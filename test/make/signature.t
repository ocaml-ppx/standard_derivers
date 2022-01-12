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