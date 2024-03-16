use std::{collections::HashMap, str::FromStr, sync::Arc};

use num_bigint::BigUint;
use parking_lot::Mutex;
use serde_json::{json, Value};

use crate::{
    trees::superficial_tree::SuperficialTree,
    utils::{crypto_uitls::hash_many, request_types::DataRequest},
};

pub fn execute_rank_models(
    dataset_req: DataRequest,
    state_tree_c: &Arc<Mutex<SuperficialTree>>,
    updated_state_hashes_c: &Arc<Mutex<HashMap<u64, BigUint>>>,
    swap_output_json_c: &Arc<Mutex<Vec<serde_json::Map<String, Value>>>>,
) -> String {
    // TODO: verify the signature
    let request_hash = hash_request(&dataset_req);

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
        serde_json::to_value("dataset").unwrap(),
    );
    json_map.insert(
        String::from("dataset_request"),
        serde_json::to_value(&dataset_req).unwrap(),
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

pub fn hash_request(dataset_req: &DataRequest) -> BigUint {
    let id = BigUint::from_str(&dataset_req.id).unwrap();
    let dataset_commitment = BigUint::from_str(&dataset_req.dataset_commitment).unwrap();
    let problem_id = BigUint::from_str(&dataset_req.problem_id).unwrap();
    let desc_hash = BigUint::from_str(&dataset_req.desc_hash).unwrap();

    let hash_inp = vec![&id, &dataset_commitment, &problem_id, &desc_hash];

    let hash = hash_many(&hash_inp);

    return hash;
}
