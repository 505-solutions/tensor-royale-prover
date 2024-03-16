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
use tiny_http::{Header, Method, Response, Server};

#[async_std::main]
async fn main() -> std::result::Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let server = Server::http("0.0.0.0:8800").unwrap();

    let state_tree_ = SuperficialTree::new(3);
    let updated_state_hashes_: HashMap<u64, BigUint> = HashMap::new();
    let swap_output_json_: Vec<serde_json::Map<String, Value>> = Vec::new();

    let state_tree = Arc::new(Mutex::new(state_tree_));
    let updated_state_hashes = Arc::new(Mutex::new(updated_state_hashes_));
    let swap_output_json = Arc::new(Mutex::new(swap_output_json_));

    println!("Server started at port 8800");

    for mut request in server.incoming_requests() {
        if *request.method() == Method::Get && request.url() == "/test" {
            let mut response =
                Response::from_string("Greetings from TensorRoyale prover").with_status_code(200);
            add_cors(&mut response);
            request.respond(response)?;
        } else if *request.method() == Method::Post {
            match request.url() {
                "/problem" => {
                    let problem_req: ProblemRequest = serde_json::from_reader(request.as_reader())?;

                    let tx_commitment = execute_problem_request(
                        problem_req,
                        &state_tree,
                        &updated_state_hashes,
                        &swap_output_json,
                    );

                    println!("tx_commitment: {}", tx_commitment);

                    let mut response = Response::from_string(tx_commitment).with_status_code(200);
                    add_cors(&mut response);
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

                    println!("tx_commitment: {}", tx_commitment);

                    let mut response = Response::from_string(tx_commitment).with_status_code(200);
                    add_cors(&mut response);
                    request.respond(response)?;
                }
                "/models" => {
                    let submission_req: ModelSubmissionRequest =
                        serde_json::from_reader(request.as_reader())?;

                    let tx_commitment = execute_submission_request(
                        submission_req,
                        &state_tree,
                        &updated_state_hashes,
                        &swap_output_json,
                    );

                    println!("tx_commitment: {}", tx_commitment);

                    let mut response = Response::from_string(tx_commitment).with_status_code(200);
                    add_cors(&mut response);
                    request.respond(response)?;
                }
                "/results" => {
                    let submission_req: VerificationRequest =
                        serde_json::from_reader(request.as_reader())?;

                    let tx_commitment = execute_verification_request(
                        submission_req,
                        &state_tree,
                        &updated_state_hashes,
                        &swap_output_json,
                    );

                    println!("tx_commitment: {}", tx_commitment);

                    let mut response = Response::from_string(tx_commitment).with_status_code(200);
                    add_cors(&mut response);
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

pub fn add_cors(response: &mut Response<std::io::Cursor<Vec<u8>>>) {
    response
        .add_header(Header::from_bytes(&b"Access-Control-Allow-Origin"[..], &b"*"[..]).unwrap());
    response.add_header(
        Header::from_bytes(
            &b"Access-Control-Allow-Methods"[..],
            &b"GET, POST, OPTIONS"[..],
        )
        .unwrap(),
    );
    response.add_header(
        Header::from_bytes(&b"Access-Control-Allow-Headers"[..], &b"Content-Type"[..]).unwrap(),
    );
}
