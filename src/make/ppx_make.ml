(* Generated code should depend on the environment in scope as little as
   possible.  E.g. rather than [foo = []] do [match foo with [] ->], to eliminate the
   use of [=], which might be overwritten in the environment.
   It is especially important to not use polymorphic comparisons. *)

   open Ppxlib
   open Ast_builder.Default
   
   module Construct = struct
     (* Additional AST construction helpers *)
   
     let str_item ~loc name body =
       pstr_value ~loc Nonrecursive [ value_binding ~loc ~pat:(pvar ~loc name) ~expr:body ]
     ;;
   
     let sig_item ~loc name typ =
       psig_value
         ~loc
         (value_description ~loc ~name:(Located.mk ~loc name) ~type_:typ ~prim:[])
     ;;
   end
   
   module Create = struct
     let record ~loc pairs =
       pexp_record
         ~loc
         (List.map (fun (name, exp) -> Located.lident ~loc name, exp) pairs)
         None
     ;;
   
     let lambda ~loc patterns body =
       List.fold_right (fun (lab, pat) acc ->
        pexp_fun ~loc lab None pat acc) patterns body
     ;;
   
     let lambda_sig ~loc arg_tys body_ty =
       List.fold_right (fun (lab, arg_ty) acc ->
        ptyp_arrow ~loc lab arg_ty acc) arg_tys body_ty
     ;;
   end
   
   module Inspect = struct
     let field_names label_decls = List.map (fun label_decl -> label_decl.pld_name.txt) label_decls
   end
   
   let check_at_least_one_record ~loc rec_flag tds =
     (match rec_flag with
      | Nonrecursive ->
        Location.raise_errorf ~loc "nonrec is not compatible with the `make' preprocessor"
      | _ -> ());
     let is_record td =
       match td.ptype_kind with
       | Ptype_record _ -> true
       | _ -> false
     in
     if not (List.exists is_record tds)
     then
       Location.raise_errorf
         ~loc
         (match tds with
          | [ _ ] -> "Unsupported use of make (you can only use it on records)."
          | _ ->
            "'with fields' can only be applied on type definitions in which at least one \
             type definition is a record")
   ;;
   
   module Gen_sig = struct
     let apply_type ~loc ~ty_name ~tps = ptyp_constr ~loc (Located.lident ~loc ty_name) tps
     let label_arg name ty = Labelled name, ty
   
     let make_fun ~ty_name ~tps ~loc label_decls =
       let record = apply_type ~loc ~ty_name ~tps in
       let derive_type label_decl =
         let { pld_name = name; pld_type = ty; _ } = label_decl in
         label_arg name.txt ty
       in
       let types = List.map derive_type label_decls in
       let t = Create.lambda_sig ~loc types record in
       let fun_name = "make_" ^ ty_name in
       Construct.sig_item ~loc fun_name t
     ;;

     let record
           ~private_
           ~ty_name
           ~tps
           ~loc
           (label_decls : label_declaration list)
       : signature
       =
       let make_fun = make_fun ~ty_name ~tps ~loc label_decls in
                (match private_ with
                   (* The ['perm] phantom type prohibits first-class fields from mutating or
                      creating private records, so we can expose them (and fold, etc.).
   
                      However, we still can't expose functions that explicitly create private
                      records. *)
                   | Private -> []
                   | Public -> [ make_fun ])
     ;;
   
     let derive_per_td (td : type_declaration) : signature =
       let { ptype_name = { txt = ty_name; loc }
           ; ptype_private = private_
           ; ptype_params
           ; ptype_kind
           ; _
           }
         =
         td
       in
       let tps = List.map (fun (tp, _variance) -> tp) ptype_params in
       match ptype_kind with
       | Ptype_record label_decls ->
         record ~private_ ~ty_name ~tps ~loc label_decls
       | _ -> []
     ;;
   
     let generate ~loc ~path:_ (rec_flag, tds) =
       check_at_least_one_record ~loc rec_flag tds;
       List.concat_map (derive_per_td) tds
     ;;
   end
   
   module Gen_struct = struct
     let label_arg ?label ~loc name =
       let l =
         match label with
         | None -> name
         | Some n -> n
       in
       Labelled l, pvar ~loc name
     ;;
   
     let make_fun ~loc record_name label_decls =
       let names = Inspect.field_names label_decls in
       let create_record = Create.record ~loc (List.map (fun n -> n, evar ~loc n) names) in
       let patterns = List.map (fun x -> label_arg ~loc x) names in
       let derive_lambda = Create.lambda ~loc patterns create_record in
       let fun_name = "make_" ^ record_name in
       Construct.str_item ~loc fun_name derive_lambda
     ;;
   
     let record
           ~private_
           ~record_name
           ~loc
           (label_decls : label_declaration list)
       : structure
       =
       let make = make_fun ~loc record_name label_decls in
       (match private_ with
         | Private -> []
         | Public -> [ make ])
     ;;
   
     let derive_per_td (td : type_declaration) : structure =
       let { ptype_name = { txt = record_name; loc }
           ; ptype_private = private_
           ; ptype_kind
           ; _
           }
         =
         td
       in
       match ptype_kind with
       | Ptype_record label_decls ->
         record ~private_ ~record_name ~loc label_decls
       | _ -> []
     ;;
   
     let generate ~loc ~path:_ (rec_flag, tds) =
       check_at_least_one_record ~loc rec_flag tds;
       List.concat_map (derive_per_td) tds
     ;;
   end

   let make =
    Deriving.add "make"
       ~str_type_decl:
        (Deriving.Generator.make_noarg Gen_struct.generate)
       ~sig_type_decl:
        (Deriving.Generator.make_noarg Gen_sig.generate)
   ;;
