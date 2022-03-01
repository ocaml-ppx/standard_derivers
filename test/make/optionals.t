---------------------------------------------------
NOTICE: @@ocaml.doc and @@merlin.hide annotations
& `include struct` boilerplate are added by ppxlib.
---------------------------------------------------
The `-deriving-keep-w32 both` flag added after the 
driver removes anonymous functions of the type: 
-   let _ = fun (_ : t) -> ()
-   let _ = make_t
which are automatically added by ppxlib.
---------------------------------------------------

Test 1: Given a record type `a` with an `option` field, 
make_a will accept an optional param and have a unit at
the end of its signature
  $ test1="
  > type a = {
  >   x: int ;
  >   y: bool option }[@@deriving make]"
  $ echo "$test1" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type a = {
    x: int ;
    y: bool option }[@@deriving make]
  include struct let make_a ~x  ?y  () = { x; y } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]
  $ echo "$test1" > test.mli
  $ driver test.mli 
  type a = {
    x: int ;
    y: bool option }[@@deriving make]
  include
    sig [@@@ocaml.warning "-32"] val make_a : x:int -> ?y:bool -> unit -> a end
  [@@ocaml.doc "@inline"][@@merlin.hide ]


Test 2: Given a record type b with an option field & a
@main field, make_b accepts the main field as the last  
parameter, and does not have a unit in the signature
  $ test2="
  > type b = {
  >   x: int ;
  >   y: bool [@main] ;
  >   z : string option}[@@deriving make]"
  $ echo "$test2" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type b = {
    x: int ;
    y: bool [@main ];
    z: string option }[@@deriving make]
  include struct let make_b ~x  ?z  y = { x; y; z } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]
  $ echo "$test2" > test.mli
  $ driver test.mli 
  type b = {
    x: int ;
    y: bool [@main ];
    z: string option }[@@deriving make]
  include
    sig [@@@ocaml.warning "-32"] val make_b : x:int -> ?z:string -> bool -> b
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 3: Given record type c with 2 option fields, one 
of which is also annotated with @main, make_c accepts 
the main field as the last param, which is of type 
`option` but is not optional
  $ test3="
  > type c = {
  >   x: int ;
  >   y: bool option [@main] ;
  >   z : string option}[@@deriving make]"
  $ echo "$test3" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type c = {
    x: int ;
    y: bool option [@main ];
    z: string option }[@@deriving make]
  include struct let make_c ~x  ?z  y = { x; y; z } end[@@ocaml.doc "@inline"]
  [@@merlin.hide ]
  $ echo "$test3" > test.mli
  $ driver test.mli 
  type c = {
    x: int ;
    y: bool option [@main ];
    z: string option }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      val make_c : x:int -> ?z:string -> bool option -> c
    end[@@ocaml.doc "@inline"][@@merlin.hide ]

Test 4: Given a record type `d` with a `list` field, 
make_d will accept an optional param with default value 
`[]` and will have a unit at the end of its signature
  $ test4="
  > type d = {
  >   x: int list ;
  >   y: bool }[@@deriving make]"
  $ echo "$test4" > test.mli
  $ driver test.mli
  type d = {
    x: int list ;
    y: bool }[@@deriving make]
  include
    sig
      [@@@ocaml.warning "-32"]
      val make_d : ?x:int list -> y:bool -> unit -> d
    end[@@ocaml.doc "@inline"][@@merlin.hide ]
  $ echo "$test4" > test.ml
  $ driver -deriving-keep-w32 both test.ml
  type d = {
    x: int list ;
    y: bool }[@@deriving make]
  include struct let make_d ?(x= [])  ~y  () = { x; y } end[@@ocaml.doc
                                                             "@inline"]
  [@@merlin.hide ]
