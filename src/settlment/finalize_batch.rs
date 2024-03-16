use async_std::path::Path;
use num_bigint::BigUint;
use parking_lot::Mutex;
use rayon::iter::{IntoParallelIterator, ParallelIterator};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::{collections::HashMap, sync::Arc, time::SystemTime};

use crate::trees::{superficial_tree::SuperficialTree, Tree};

/// Gets all the relevant info for this batch and stores it in a struct
/// to be used by _transition_state. It also resets all the relevant state
/// variables so that the next batch can begin.
pub fn finalize_batch(
    state_tree: &Arc<Mutex<SuperficialTree>>,
    updated_state_hashes: &Arc<Mutex<HashMap<u64, BigUint>>>,
    swap_output_json: &Arc<Mutex<Vec<serde_json::Map<String, Value>>>>,
    // main_storage: &Arc<Mutex<MainStorage>>,
) {
    let state_tree = state_tree.clone();
    let mut state_tree = state_tree.lock();
    state_tree.update_zero_idxs();

    // let main_storage = main_storage.clone();
    // let mut main_storage_m = main_storage.lock();

    // ? Update the merkle trees and get the new roots and preimages
    let updated_state_hashes = updated_state_hashes.lock();
    let (prev_state_root, new_state_root, preimage_json) =
        update_trees(updated_state_hashes.clone()).unwrap();

    // ? Construct the global state and config
    let global_expiration_timestamp = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .expect("Time went backwards")
        .as_secs() as u32;

    let swap_output_json = serde_json::to_value(&(*swap_output_json.lock())).unwrap();
    let preimage_json = serde_json::to_value(&preimage_json).unwrap();
    let prev_state_root = serde_json::to_value(&prev_state_root).unwrap();
    let new_state_root = serde_json::to_value(&new_state_root).unwrap();
    let global_expiration_timestamp = serde_json::to_value(&global_expiration_timestamp).unwrap();

    let mut output_json = serde_json::Map::new();
    output_json.insert(String::from("swap_output_json"), swap_output_json);
    output_json.insert(String::from("preimage_json"), preimage_json);
    output_json.insert(String::from("prev_state_root"), prev_state_root);
    output_json.insert(String::from("new_state_root"), new_state_root);
    output_json.insert(
        String::from("global_expiration_timestamp"),
        global_expiration_timestamp,
    );

    let path = Path::new("../../prover/batch_input.json");
    std::fs::write(path, serde_json::to_string(&output_json).unwrap()).unwrap();

    println!("Transaction batch finalized successfully!");
}

// * =========================================== * //
// & TREE UPDATES ------------------------------ & //
pub fn update_trees(
    updated_state_hashes: HashMap<u64, BigUint>,
) -> Result<(BigUint, BigUint, Map<String, Value>), String> {
    // * UPDATE SPOT TREES  -------------------------------------------------------------------------------------
    let mut updated_root_hashes: HashMap<u64, BigUint> = HashMap::new(); // the new roots of all tree partitions

    let mut preimage_json: Map<String, Value> = Map::new();

    // ? use the newly generated roots to update the state tree
    let (prev_spot_root, new_spot_root) =
        tree_partition_update(updated_root_hashes, &mut preimage_json, u32::MAX)?;

    Ok((prev_spot_root, new_spot_root, preimage_json))
}

fn tree_partition_update(
    updated_state_hashes: HashMap<u64, BigUint>,
    preimage_json: &mut Map<String, Value>,
    tree_depth: u32,
) -> Result<(BigUint, BigUint), String> {
    let mut batch_init_tree = Tree::from_disk(tree_depth).unwrap();

    let prev_root = batch_init_tree.root.clone();

    batch_init_tree.batch_transition_updates(&updated_state_hashes, preimage_json);

    let new_root = batch_init_tree.root.clone();

    // ? Store the new tree to disk
    batch_init_tree.store_to_disk().unwrap();

    Ok((prev_root, new_root))
}
