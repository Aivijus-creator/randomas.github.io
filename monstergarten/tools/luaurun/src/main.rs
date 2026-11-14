use mlua::{Lua, Result};
fn main() -> Result<()> {
    let lua = Lua::new();
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().map(|s| s.as_str()) == Some("--run") {
        let g = lua.globals();
        g.set("__readfile", lua.create_function(|_, p: String| Ok(std::fs::read_to_string(&p).ok()))?)?;
        g.set("__writefile", lua.create_function(|_, (p, c): (String, mlua::String)| { std::fs::write(&p, c.as_bytes()).ok(); Ok(()) })?)?;
        g.set("__isdir", lua.create_function(|_, p: String| Ok(std::path::Path::new(&p).is_dir()))?)?;
        g.set("__isfile", lua.create_function(|_, p: String| Ok(std::path::Path::new(&p).is_file()))?)?;
        g.set("__listdir", lua.create_function(|_, p: String| {
            let mut v = vec![];
            if let Ok(rd) = std::fs::read_dir(&p) { for e in rd.flatten() { v.push(e.file_name().to_string_lossy().to_string()); } }
            v.sort(); Ok(v)
        })?)?;
        g.set("__compile", lua.create_function(|l, (src, name): (String, String)| {
            match l.load(&src).set_name(name).into_function() { Ok(f) => Ok((Some(f), None)), Err(e) => Ok((None, Some(e.to_string()))) }
        })?)?;
        let src = std::fs::read_to_string(&args[1]).unwrap();
        let r = lua.load(&src).set_name(args[1].as_str()).exec();
        if let Err(e) = r { eprintln!("{}", e); std::process::exit(1) }
        return Ok(());
    }
    let mut bad = 0;
    for path in args {
        let src = std::fs::read_to_string(&path).unwrap();
        if let Err(e) = lua.load(&src).set_name(path.as_str()).into_function() { println!("{}", e); bad += 1; }
    }
    if bad > 0 { std::process::exit(1) }
    Ok(())
}
