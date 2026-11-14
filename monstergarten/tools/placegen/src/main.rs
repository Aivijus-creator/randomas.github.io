// placegen: JSON instance tree (from the Luau mock) -> Roblox place/model file via rbx_xml.
use rbx_dom_weak::{InstanceBuilder, WeakDom, types::*};
use rbx_reflection::{DataType, PropertyKind};
use serde_json::Value;
use std::collections::HashMap;

fn f(v: &Value) -> f32 { v.as_f64().unwrap_or(0.0) as f32 }

struct Ctx { ids: HashMap<i64, Ref>, pending_refs: Vec<(Ref, String, i64)>, warnings: HashMap<String, usize> }

fn prop_type(class: &str, prop: &str) -> Option<DataType<'static>> {
    let db = rbx_reflection_database::get();
    let mut cls = db.classes.get(class)?;
    loop {
        if let Some(p) = cls.properties.get(prop) {
            // follow aliases to the canonical property
            if let PropertyKind::Alias { alias_for } = &p.kind {
                if let Some(c) = cls.properties.get(alias_for.as_ref()) { return Some(c.data_type.clone()); }
            }
            return Some(p.data_type.clone());
        }
        cls = db.classes.get(cls.superclass.as_ref()?.as_ref())?;
    }
}

fn convert(ctx: &mut Ctx, class: &str, name: &str, tv: &Value) -> Option<Variant> {
    let arr = tv.as_array()?;
    let t = arr[0].as_str()?;
    let v = &arr[1];
    let want = prop_type(class, name);
    let enum_value = |e: &str, item: &str| -> Option<u32> {
        rbx_reflection_database::get().enums.get(e)?.items.get(item).copied()
    };
    let var = match t {
        "s" => match want {
            Some(DataType::Value(VariantType::ContentId)) => Variant::ContentId(ContentId::from(v.as_str()?)),
            _ => Variant::String(v.as_str()?.to_string()),
        },
        "b" => Variant::Bool(v.as_bool()?),
        "f" => {
            let n = v.as_f64()?;
            match want {
                Some(DataType::Value(VariantType::Int32)) => Variant::Int32(n as i32),
                Some(DataType::Value(VariantType::Int64)) => Variant::Int64(n as i64),
                Some(DataType::Value(VariantType::Float64)) => Variant::Float64(n),
                _ => Variant::Float32(n as f32),
            }
        }
        "v3" => { let a = v.as_array()?; Variant::Vector3(Vector3::new(f(&a[0]), f(&a[1]), f(&a[2]))) }
        "v2" => { let a = v.as_array()?; Variant::Vector2(Vector2::new(f(&a[0]), f(&a[1]))) }
        "cf" => {
            let a = v.as_array()?;
            Variant::CFrame(CFrame::new(Vector3::new(f(&a[0]), f(&a[1]), f(&a[2])), Matrix3::new(
                Vector3::new(f(&a[3]), f(&a[4]), f(&a[5])), Vector3::new(f(&a[6]), f(&a[7]), f(&a[8])), Vector3::new(f(&a[9]), f(&a[10]), f(&a[11])))))
        }
        "c3" => {
            let a = v.as_array()?;
            let c = Color3::new(f(&a[0]), f(&a[1]), f(&a[2]));
            match want {
                Some(DataType::Value(VariantType::Color3uint8)) => Variant::Color3uint8(Color3uint8::new((c.r * 255.0).round() as u8, (c.g * 255.0).round() as u8, (c.b * 255.0).round() as u8)),
                _ => Variant::Color3(c),
            }
        }
        "e" => { let a = v.as_array()?; Variant::Enum(Enum::from_u32(enum_value(a[0].as_str()?, a[1].as_str()?)?)) }
        "u2" => { let a = v.as_array()?; Variant::UDim2(UDim2::new(UDim::new(f(&a[0]), f(&a[1]) as i32), UDim::new(f(&a[2]), f(&a[3]) as i32))) }
        "u" => { let a = v.as_array()?; Variant::UDim(UDim::new(f(&a[0]), f(&a[1]) as i32)) }
        "nr" => { let a = v.as_array()?; Variant::NumberRange(NumberRange::new(f(&a[0]), f(&a[1]))) }
        "ns" => { let a = v.as_array()?; Variant::NumberSequence(NumberSequence { keypoints: a.iter().map(|k| { let k = k.as_array().unwrap(); NumberSequenceKeypoint::new(f(&k[0]), f(&k[1]), f(&k[2])) }).collect() }) }
        "cs" => { let a = v.as_array()?; Variant::ColorSequence(ColorSequence { keypoints: a.iter().map(|k| { let k = k.as_array().unwrap(); ColorSequenceKeypoint::new(f(&k[0]), Color3::new(f(&k[1]), f(&k[2]), f(&k[3]))) }).collect() }) }
        _ => return None,
    };
    // drop values whose type cannot match the property (avoids broken files)
    if let Some(DataType::Value(vt)) = &want {
        let ok = var.ty() == *vt || matches!((vt, var.ty()), (VariantType::Color3uint8, VariantType::Color3));
        if !ok { *ctx.warnings.entry(format!("type {}.{} {:?}!={:?}", class, name, var.ty(), vt)).or_insert(0) += 1; return None; }
    }
    if want.is_none() { *ctx.warnings.entry(format!("unknown {}.{}", class, name)).or_insert(0) += 1; return None; }
    Some(var)
}

fn attr_value(tv: &Value) -> Option<Variant> {
    let arr = tv.as_array()?;
    let v = &arr[1];
    Some(match arr[0].as_str()? {
        "s" => Variant::String(v.as_str()?.to_string()),
        "b" => Variant::Bool(v.as_bool()?),
        "f" => Variant::Float64(v.as_f64()?),
        "v3" => { let a = v.as_array()?; Variant::Vector3(Vector3::new(f(&a[0]), f(&a[1]), f(&a[2]))) }
        "c3" => { let a = v.as_array()?; Variant::Color3(Color3::new(f(&a[0]), f(&a[1]), f(&a[2]))) }
        "cf" => { let a = v.as_array()?; Variant::CFrame(CFrame::new(Vector3::new(f(&a[0]), f(&a[1]), f(&a[2])), Matrix3::new(
            Vector3::new(f(&a[3]), f(&a[4]), f(&a[5])), Vector3::new(f(&a[6]), f(&a[7]), f(&a[8])), Vector3::new(f(&a[9]), f(&a[10]), f(&a[11]))))) }
        _ => return None,
    })
}

fn build(ctx: &mut Ctx, dom: &mut WeakDom, parent: Ref, node: &Value) {
    let class = node["c"].as_str().unwrap_or("Folder");
    let mut b = InstanceBuilder::new(class).with_name(node["n"].as_str().unwrap_or(class));
    if let Some(props) = node["p"].as_object() {
        for (k, tv) in props {
            if tv[0].as_str() == Some("ref") { continue; }
            if let Some(v) = convert(ctx, class, k, tv) { b = b.with_property(k.as_str(), v); }
        }
    }
    if let Some(attrs) = node["a"].as_object() {
        let mut at = Attributes::new();
        for (k, tv) in attrs { if let Some(v) = attr_value(tv) { at.insert(k.clone(), v); } }
        if !attrs.is_empty() { b = b.with_property("Attributes", at); }
    }
    if let Some(tags) = node["t"].as_array() {
        if !tags.is_empty() {
            let mut tg = Tags::new();
            for t in tags { tg.push(t.as_str().unwrap_or("")); }
            b = b.with_property("Tags", tg);
        }
    }
    let r = dom.insert(parent, b);
    if let Some(id) = node["id"].as_i64() { ctx.ids.insert(id, r); }
    if let Some(props) = node["p"].as_object() {
        for (k, tv) in props {
            if tv[0].as_str() == Some("ref") { if let Some(id) = tv[1].as_i64() { ctx.pending_refs.push((r, k.clone(), id)); } }
        }
    }
    if let Some(kids) = node["k"].as_array() { for k in kids { build(ctx, dom, r, k); } }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let json: Value = serde_json::from_str(&std::fs::read_to_string(&args[1]).unwrap()).unwrap();
    let mut dom = WeakDom::new(InstanceBuilder::new("DataModel"));
    let root = dom.root_ref();
    let mut ctx = Ctx { ids: HashMap::new(), pending_refs: vec![], warnings: HashMap::new() };
    for svc in json.as_array().unwrap() { build(&mut ctx, &mut dom, root, svc); }
    for (inst, prop, id) in std::mem::take(&mut ctx.pending_refs) {
        if let Some(target) = ctx.ids.get(&id) { dom.get_by_ref_mut(inst).unwrap().properties.insert(prop.as_str().into(), Variant::Ref(*target)); }
    }
    let children: Vec<Ref> = dom.root().children().to_vec();
    let out = std::fs::File::create(&args[2]).unwrap();
    rbx_xml::to_writer_default(std::io::BufWriter::new(out), &dom, &children).unwrap();
    let mut w: Vec<_> = ctx.warnings.into_iter().collect();
    w.sort();
    for (k, n) in w { eprintln!("warn: {} x{}", k, n); }
    eprintln!("ok: {} instances", dom.descendants().count());
}
