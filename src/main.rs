use std::{collections::HashMap, sync::Arc};

use num_bigint::BigUint;
use parking_lot::lock_api::Mutex;
use serde_json::Value;
use tensor_royale_prover::{
    requests::{
        data_request::execute_data_request, problem_request::execute_problem_request,
        submission_request::execute_submission_request,
        verification_request::execute_verification_request,
    },
    trees::superficial_tree::SuperficialTree,
    utils::request_types::{
        DataRequest, ModelSubmissionRequest, ProblemRequest, VerificationRequest,
    },
};
use tiny_http::{Method, Response, Server};

#[derive(serde::Deserialize)]
struct MyType {
    pub name: String,
    pub legs: u32,
}

#[async_std::main]
async fn main() -> std::result::Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let server = Server::http("0.0.0.0:8800").unwrap();

    let mut state_tree_ = SuperficialTree::new(3);
    let mut updated_state_hashes_: HashMap<u64, BigUint> = HashMap::new();
    let mut swap_output_json_: Vec<serde_json::Map<String, Value>> = Vec::new();

    let state_tree = Arc::new(Mutex::new(state_tree_));
    let updated_state_hashes = Arc::new(Mutex::new(updated_state_hashes_));
    let swap_output_json = Arc::new(Mutex::new(swap_output_json_));

    for mut request in server.incoming_requests() {
        // println!(
        //     "received request! method: {:?}, url: {:?}, headers: {:?}",
        //     request.method(),
        //     request.url(),
        //     request.headers()
        // );

        // println!("received request! method: {:?}, url: {:?}", request.url());

        if *request.method() == Method::Post {
            match request.url() {
                "/problem" => {
                    let problem_req: ProblemRequest = serde_json::from_reader(request.as_reader())?;

                    let tx_commitment = execute_problem_request(
                        problem_req,
                        &state_tree,
                        &updated_state_hashes,
                        &swap_output_json,
                    );

                    let response = Response::from_string(tx_commitment).with_status_code(200);
                    request.respond(response)?;
                }
                "/dataset" => {
                    let data_req: DataRequest = serde_json::from_reader(request.as_reader())?;

                    let tx_commitment = execute_data_request(
                        data_req,
                        &state_tree,
                        &updated_state_hashes,
                        &swap_output_json,
                    );

                    let response = Response::from_string(tx_commitment).with_status_code(200);
                    request.respond(response)?;
                }
                "/submission" => {
                    let submission_req: ModelSubmissionRequest =
                        serde_json::from_reader(request.as_reader())?;

                    let tx_commitment = execute_submission_request(
                        submission_req,
                        &state_tree,
                        &updated_state_hashes,
                        &swap_output_json,
                    );

                    let response = Response::from_string(tx_commitment).with_status_code(200);
                    request.respond(response)?;
                }
                "/verification" => {
                    let submission_req: VerificationRequest =
                        serde_json::from_reader(request.as_reader())?;

                    let tx_commitment = execute_verification_request(
                        submission_req,
                        &state_tree,
                        &updated_state_hashes,
                        &swap_output_json,
                    );

                    let response = Response::from_string(tx_commitment).with_status_code(200);
                    request.respond(response)?;
                }
                _ => {
                    let response = Response::from_string("Not Found").with_status_code(404);
                    request.respond(response)?;
                }
            }
        }
    }

    Ok(())
}
