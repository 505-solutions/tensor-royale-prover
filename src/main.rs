use std::collections::HashMap;
use std::sync::mpsc;
use std::sync::Arc;

use num_bigint::BigUint;
use parking_lot::Mutex;
use serde_json::Value;
use tensor_royale_prover::requests::problem_request::execute_problem_request;
use tensor_royale_prover::trees::superficial_tree::SuperficialTree;
use tensor_royale_prover::utils::request_types::ProblemRequest;
use tide::prelude::*;
use tide::Request;

#[async_std::main]
async fn main() -> tide::Result<()> {
    let mut state_tree_ = SuperficialTree::new(3);
    let mut updated_state_hashes_: HashMap<u64, BigUint> = HashMap::new();
    let mut swap_output_json_: Vec<serde_json::Map<String, Value>> = Vec::new();

    let state_tree = Arc::new(Mutex::new(state_tree_));
    let updated_state_hashes = Arc::new(Mutex::new(updated_state_hashes_));
    let swap_output_json = Arc::new(Mutex::new(swap_output_json_));

    // let (tx, rx) = mpsc::channel();

    let mut app = tide::new();
    // app.at("/problems").post(|mut req: Request<()>| async {
    //     let problem_req: ProblemRequest = req.body_json().await.unwrap();

    //     let state_tree_c = state_tree.clone();
    //     let updated_state_hashes_c = updated_state_hashes.clone();
    //     let swap_output_json_c = swap_output_json.clone();

    //     execute_problem_request(
    //         problem_req,
    //         state_tree_c,
    //         updated_state_hashes_c,
    //         swap_output_json_c,
    //     );

    //     return Ok::<String, tide::Error>(format!("problem request submitted sucessfully").into());
    // });
    let state_tree_clone = state_tree.clone();
    app.listen("127.0.0.1:4000").await?;

    println!("Listeing on port 4000!");
    Ok(())
}

// async fn order_shoes(mut req: Request<()>) -> tide::Result {
//     // Spawn a new thread and move the transmitter into it
//     thread::spawn(move || {
//         // Send data to the receiver
//         tx.send("Hello from the spawned thread!").unwrap();
//     });

//     // Receive the message in the main thread
//     let received = rx.recv().unwrap();
//     println!("Received: {}", received);

//     Ok(format!("Hello, {}! I've put in an order for {} shoes", 1, 1).into())
// }
