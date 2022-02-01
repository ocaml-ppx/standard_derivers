(* Generated code should depend on the environment in scope as little as
   possible.  E.g. rather than [foo = []] do [match foo with [] ->], to 
   eliminate the use of [=], which might be overwritten in the environment.
   It is especially important to not use polymorphic comparisons. *)

   open Ppxlib
   open Ast_builder.Default
   
   module Construct = struct
     (* Additional AST construction helpers *)
   
     let apply_type ~loc ~ty_name ~tps = 
      ptyp_constr ~loc (Located.lident ~loc ty_name) tps
     ;;

     let lambda ~loc patterns body =
      List.fold_right (fun (lab, pat) acc ->
       pexp_fun ~loc lab None pat acc) patterns body
     ;;
  
     let lambda_sig ~loc arg_tys body_ty =
      List.fold_right (fun (lab, arg_ty) acc ->
       ptyp_arrow ~loc lab arg_ty acc) arg_tys body_ty
     ;;

     let record ~loc pairs =
      pexp_record
        ~loc
        (List.map (fun (name, exp) -> Located.lident ~loc name, exp) pairs)
        None
     ;;

     let sig_item ~loc name typ =
      psig_value ~loc (value_description ~loc ~name:(Located.mk ~loc name) ~type_:typ ~prim:[])
    ;;
    
     let str_item ~loc name body =
       pstr_value ~loc Nonrecursive [ value_binding ~loc ~pat:(pvar ~loc name) ~expr:body ]
     ;;
   end

   module Check = struct
    let derivable ~loc rec_flag tds =
      (match rec_flag with
       | Nonrecursive ->
         Location.raise_errorf ~loc "nonrec is not compatible with the `make' preprocessor."
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
             "make can only be applied on type definitions in which at least one \
              type definition is a record.")
    ;;
  end
  
   module Gen_sig = struct
     let label_arg name ty = match ty with 
     (* a' option               -> ?name        , a' *)
     | [%type: [%t? a'] option] -> Optional name, a'
     | _ -> Labelled name, ty
   
     let change_last_type ~loc types has_option = match has_option with 
     | true -> types @ [ Nolabel, Ast_helper.Typ.constr ~loc { txt = Lident "unit"; loc } [] ]
     | _ -> types

     let create_make_sig ~loc ~ty_name ~tps label_decls =
       let record = Construct.apply_type ~loc ~ty_name ~tps in
       let derive_type label_decl =
         let { pld_name = name; pld_type = ty; _ } = label_decl in
         label_arg name.txt ty
       in
       let types = List.map derive_type label_decls in
       let has_option = List.exists ( fun (name, _) -> match name with 
        | Optional _ -> true
        | _ -> false) types
       in
       let types = change_last_type ~loc types has_option in
       let t = Construct.lambda_sig ~loc types record in
       let fun_name = "make_" ^ ty_name in
       Construct.sig_item ~loc fun_name t
     ;;
   
     let check_public ~private_ ~loc = 
      (match private_ with
            | Private -> Location.raise_errorf ~loc "We cannot expose functions that explicitly create private records."
            | Public -> () )

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
         check_public ~private_ ~loc ;
         let derived_item = create_make_sig ~loc ~ty_name ~tps label_decls in
        [ derived_item ]
       | _ -> []
     ;;
   
     let generate ~loc ~path:_ (rec_flag, tds) =
       Check.derivable ~loc rec_flag tds;
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
   
     let create_make_fun ~loc ~record_name label_decls =
       let names = List.map (fun label_decl -> label_decl.pld_name.txt) label_decls in
       let create_record = Construct.record ~loc (List.map (fun n -> n, evar ~loc n) names) in
       let patterns = List.map (fun x -> label_arg ~loc x) names in
       let derive_lambda = Construct.lambda ~loc patterns create_record in
       let fun_name = "make_" ^ record_name in
       Construct.str_item ~loc fun_name derive_lambda
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
        (match private_ with
        | Private -> []
        | Public -> let derived_item = create_make_fun ~loc ~record_name label_decls in
        [ derived_item ])
       | _ -> []
     ;;
   
     let generate ~loc ~path:_ (rec_flag, tds) =
       Check.derivable ~loc rec_flag tds;
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
