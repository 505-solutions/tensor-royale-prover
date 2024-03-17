use std::{collections::HashMap, str::FromStr, sync::Arc};

use num_bigint::BigUint;
use num_traits::FromPrimitive;
use parking_lot::Mutex;
use serde_json::{json, Value};

use crate::{
    trees::superficial_tree::SuperficialTree,
    utils::{crypto_uitls::hash_many, request_types::VerificationRequest},
};

pub fn execute_verification_request(
    verification_req: VerificationRequest,
    state_tree_c: &Arc<Mutex<SuperficialTree>>,
    updated_state_hashes_c: &Arc<Mutex<HashMap<u64, BigUint>>>,
    swap_output_json_c: &Arc<Mutex<Vec<serde_json::Map<String, Value>>>>,
) -> String {
    // TODO: verify the signature
    let request_hash = hash_request(&verification_req);

    let mut state_tree = state_tree_c.lock();
    let mut updated_state_hashes = updated_state_hashes_c.lock();
    let mut swap_output_json = swap_output_json_c.lock();

    // Get request and update the state
    let zero_idx = state_tree.first_zero_idx();
    state_tree.update_leaf_node(&request_hash, zero_idx);
    updated_state_hashes.insert(zero_idx, request_hash.clone());

    // build json input for prover
    let mut json_map = serde_json::map::Map::new();
    json_map.insert(
        String::from("request_type"),
        serde_json::to_value("model_verification").unwrap(),
    );
    json_map.insert(
        String::from("verification_request"),
        serde_json::to_value(&verification_req).unwrap(),
    );
    json_map.insert(
        String::from("state_index"),
        serde_json::to_value(&zero_idx).unwrap(),
    );
    json_map.insert(
        String::from("signature"),
        serde_json::to_value(json!({"r": 0, "s": 0})).unwrap(),
    );

    swap_output_json.push(json_map);

    return request_hash.to_string();
}

pub fn hash_request(verification_req: &VerificationRequest) -> BigUint {
    let id = BigUint::from_str(&verification_req.id).unwrap();
    let model_id = BigUint::from_str(&verification_req.model_id).unwrap();
    let verifier_address = BigUint::from_str(&verification_req.verifier_address).unwrap();
    let class_confidence = BigUint::from_str(&verification_req.class_confidence).unwrap();
    let num_test_problems = BigUint::from_str(&verification_req.num_test_problems).unwrap();

    let mut hash_inp = vec![
        id,
        model_id,
        verifier_address,
        class_confidence,
        num_test_problems,
    ];
    for eval_line in &verification_req.evaluations {
        for eval in eval_line {
            let e = BigUint::from_u32(*eval).unwrap();
            hash_inp.push(e);
        }
    }

    let hash_inp = hash_inp.iter().collect::<Vec<&BigUint>>();

    let hash = hash_many(&hash_inp);

    return hash;
}
