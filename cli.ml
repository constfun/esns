open Core.Std
open Core_extended.Std

let rc_path = Filename.expand "~/.secrets"
let rc_key_path = Filename.implode [rc_path; "key"]
let rc_sec_path = Filename.implode [rc_path; "default"]

let filename ~should_exist =
  Command.Spec.Arg_type.create
    (fun filename -> match (Sys.is_file filename), should_exist with
    | `Yes, true | `No, false -> filename
    | `Yes, false ->
      eprintf "'%s' file already exists.\n%!" filename;
      exit 1
    | `No, true | `Unknown, _ ->
      eprintf "'%s' file not found.\n%!" filename;
      exit 1
    )

let with_secrets_file key_path sec_path ~f =
  let key = Crypto.create key_path in
  Crypto.with_file sec_path ~key:key ~f:(fun s ->
    let sec = match String.length s with
    | 0 -> Secrets.create ()
    | _ -> Secrets.of_string s in
    Secrets.to_string (f sec)
  )

let init key_path sec_path =
  Unix.mkdir_p ~perm:0o700 rc_path;
  with_secrets_file key_path sec_path ~f:Fn.id;
  if not (Sys.file_exists_exn ~follow_symlinks:false rc_sec_path)
  then Unix.symlink ~src:(Filename.realpath sec_path) ~dst:rc_sec_path

let import = with_secrets_file ~f:(fun _ ->
  Secrets.of_string (In_channel.input_all stdin))

let export = with_secrets_file ~f:(fun sec ->
  Out_channel.output_string stdout (Secrets.to_string sec);
  sec
  )

let add = with_secrets_file ~f:(fun sec ->
    let secopt = Filename.with_open_temp_file  "add" ".sec" ~write:ignore ~in_dir:rc_path ~f:(fun fname ->
      let editor = match Sys.getenv "EDITOR" with
      | Some e -> e
      | None -> "vim" in
      ignore (Unix.system (sprintf "%s '%s'" editor fname));
      Secrets.parse (In_channel.read_all fname)
    ) in
    match secopt with
    | Some additional_sec -> Secrets.append sec additional_sec
    | None ->
        eprintf "Invalid entry.";
        sec
  )

let with_defaults f =
  let sec_path = Filename.realpath rc_sec_path in
  f rc_key_path sec_path

let () =
  let open Command in
  let init_cmd = basic ~summary:"Create a new secrets file."
    Spec.(empty +> anon ("path" %: filename ~should_exist:false))
    (fun sec_path () -> init rc_key_path sec_path)
  in
  let import_cmd = basic ~summary:"Import secrets from an s-expression."
    Spec.empty
    (fun () -> with_defaults import)
  in
  let export_cmd = basic ~summary:"Export secrets to an s-expression."
    Spec.empty
    (fun () -> with_defaults export)
  in
  let add_cmd = basic ~summary:"Add a new secret using $EDITOR."
    Spec.empty
    (fun () -> with_defaults add)
  in
  run ~version:"0.1.0"
    (group ~summary:"Manage encrypted secrets." [
      "init", init_cmd;
      "add", add_cmd;
      "import", import_cmd;
      "export", export_cmd;
    ])
