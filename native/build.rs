use lib_flutter_rust_bridge_codegen::*;

const RUST_INPUT: &str = "src/api.rs";
const DART_OUTPUT: &str = "../lib/src/native/bridge_generated.dart";
const DART_DECL_OUTPUT: &str = "../lib/src/native/bridge_definitions.dart";
// const C_OUTPUT: &str = "../ios/Runner/bridge_generated.h";

fn main() {
    // Only rerun when the API file changes.
    println!("cargo:rerun-if-changed={}", RUST_INPUT);
    let configs = config_parse(RawOpts {
        rust_input: vec![RUST_INPUT.to_string()],
        dart_output: vec![DART_OUTPUT.to_string()],
        dart_decl_output: Option::Some(DART_DECL_OUTPUT.to_string()),
        verbose: true,
        wasm: false,
        
        
        ..Default::default()
    });
    if let Ok(symbols) = get_symbols_if_no_duplicates(&configs) {
        for config in &configs {
            frb_codegen(config, &symbols).unwrap();
        }
    }
}