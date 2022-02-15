(* Generated code should depend on the environment in scope as little as
   possible.  E.g. rather than [foo = []] do [match foo with [] ->], to 
   eliminate the use of [=], which might be overwritten in the environment.
   It is especially important to not use polymorphic comparisons. *)

   open Ppxlib
   open Ast_builder.Default
   
   module Annotations = struct 
    let default_attr = 
      Attribute.declare 
        "standard_derivers.make.default" 
        Attribute.Context.label_declaration
        Ast_pattern.(single_expr_payload __)
        (fun expr -> expr)
    ;;

    let main_attr = 
      Attribute.declare 
        "standard_derivers.make.main" 
        Attribute.Context.label_declaration
        Ast_pattern.(pstr nil)
        ()
    ;;

    let find_main labels =
      List.fold_left (fun (main_label, labels) ({ pld_loc; _ } as label) ->
          match Attribute.get main_attr label, main_label with
          | Some _, Some _ -> Location.raise_errorf ~loc:pld_loc "Duplicate [@deriving.%s.main] annotation" "make"
          | Some _, None -> Some label, labels
          | None, _ -> main_label, label :: labels)
          (None, []) labels
    ;;
   end

   module Check = struct
    let is_derivable ~loc rec_flag tds =
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

    let is_public ~private_ ~loc = 
      (match private_ with
            | Private -> Location.raise_errorf ~loc "We cannot expose functions that explicitly create private records."
            | Public -> () )
    ;;

    let is_optional labels = List.exists (fun (name, _) -> match name with 
    | Optional _ -> true
    | _ -> false) labels
    ;;
  end

   module Construct = struct
     (* Additional AST construction helpers *)
   
     let apply_type ~loc ~ty_name ~tps = 
      ptyp_constr ~loc (Located.lident ~loc ty_name) tps
     ;;

     let lambda ~loc patterns body =
      List.fold_left (fun acc (lab, pat) ->
       pexp_fun ~loc lab None pat acc) body patterns
     ;;
  
     let lambda_sig ~loc arg_tys body_ty =
      List.fold_left (fun acc (lab, arg_ty) ->
       ptyp_arrow ~loc lab arg_ty acc) body_ty arg_tys 
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
  
   module Gen_sig = struct
     let label_arg label_decl =
       let { pld_name = name; pld_type = ty; _ } = label_decl in
      match (Attribute.get Annotations.default_attr label_decl),  ty with
      (* @default -> Optional  *)
      | Some _, _ -> Optional name.txt, ty
      (* option type -> Optional *)
      | _, [%type: [%t? a'] option] -> Optional name.txt, a'
      (* regular field -> Labelled *)
      | _ -> Labelled name.txt, ty
     ;;
     
     let create_make_sig ~loc ~ty_name ~tps label_decls =
       let record = Construct.apply_type ~loc ~ty_name ~tps in
       let main_arg, label_decls = Annotations.find_main label_decls in
       let derive_type label_decl = label_arg label_decl in
       let types = List.map derive_type label_decls in
       let add_unit types = (
         Nolabel, 
         Ast_helper.Typ.constr ~loc { txt = Lident "unit"; loc } []
        )::types in
       let types = match main_arg with 
        | Some { pld_type ; _ } 
            -> (Nolabel, pld_type)::types
        | None when Check.is_optional types -> add_unit types
        | None -> types
       in
       let t = Construct.lambda_sig ~loc types record in
       let fun_name = "make_" ^ ty_name in
       Construct.sig_item ~loc fun_name t
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
         Check.is_public ~private_ ~loc ;
         let derived_item = create_make_sig ~loc ~ty_name ~tps label_decls in
        [ derived_item ]
       | _ -> []
     ;;
   
     let generate ~loc ~path:_ (rec_flag, tds) =
       Check.is_derivable ~loc rec_flag tds;
       List.concat_map (derive_per_td) tds
     ;;
   end
   
   module Gen_struct = struct
     let label_arg ~loc label_decl =
      let{ pld_name = name; pld_type = ty; _ } = label_decl in
         match (Attribute.get Annotations.default_attr label_decl), ty with
         | Some _ , _
         | _, [%type: [%t? _] option] -> Optional name.txt, pvar ~loc name.txt
         | _ -> Labelled name.txt, pvar ~loc name.txt
     ;;
   
     let create_make_fun ~loc ~record_name label_decls =
      let field_labels = List.map (fun { pld_name = n; _ } -> n.txt, evar ~loc n.txt) label_decls in
       let main_arg, label_decls = Annotations.find_main label_decls in
       let derive_pattern label_decl = label_arg ~loc label_decl in 
       let patterns = List.map derive_pattern label_decls in
       let add_unit patterns = (Nolabel, punit ~loc)::patterns in
       let patterns = match main_arg with 
        | Some { pld_name = { txt = name ; _ } ; _ } 
            -> (Nolabel, pvar ~loc name)::patterns
        | None when Check.is_optional patterns -> add_unit patterns
        | None -> patterns
       in
       let create_record = Construct.record ~loc field_labels in
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
       Check.is_derivable ~loc rec_flag tds;
       List.concat_map (derive_per_td) tds
     ;;
   end

   let make =
     let attributes = 
      (Attribute.T Annotations.default_attr)::[Attribute.T Annotations.main_attr] 
     in
    Deriving.add "make"
       ~str_type_decl:
        (Deriving.Generator.make_noarg 
          ~attributes
          Gen_struct.generate)
       ~sig_type_decl:
        (Deriving.Generator.make_noarg 
          ~attributes  
          Gen_sig.generate)
   ;;
