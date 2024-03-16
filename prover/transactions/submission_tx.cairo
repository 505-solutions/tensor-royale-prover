from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess

from transaction.utils import (
    update_state,
    write_request_to_output,
    verify_req_signature,
    push_to_array,
)

from types.requests import ModelSubmissionRequest

func verify_submission_request{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}() {
    alloc_locals;

    let submission_req: ModelSubmissionRequest = handle_program_input();

    let submission_hash = hash_submission_req(submission_req);

    local public_key: felt;
    %{ ids.public_key = int(current_request["public_key"]) %}
    verify_req_signature(submission_hash, public_key);

    local state_idx: felt;
    %{ ids.state_idx = current_request["state_idx"] %}
    update_state(state_idx, submission_hash);

    write_request_to_output(submission_req.id, public_key, submission_hash);

    return ();
}

// * HELPERS =======================================================

func handle_program_input{range_check_ptr}() -> ModelSubmissionRequest {
    alloc_locals;

    // & This is the public on_chain deposit information
    local submission_req: ModelSubmissionRequest;
    %{
        memory[ids.submission_req.address_ + ModelSubmissionRequest.id] = int(current_request["id"])
        memory[ids.submission_req.address_ + ModelSubmissionRequest.model_id] = int(current_request["model_id"])
        memory[ids.submission_req.address_ + ModelSubmissionRequest.user_address] = int(current_request["user_address"])
        memory[ids.submission_req.address_ + ModelSubmissionRequest.model_commitment] = int(current_request["model_commitment"])
        memory[ids.submission_req.address_ + ModelSubmissionRequest.data_id] = int(current_request["data_id"])
        memory[ids.submission_req.address_ + ModelSubmissionRequest.problem_id] = int(current_request["problem_id"])
    %}

    return submission_req;
}

func hash_submission_req{poseidon_ptr: PoseidonBuiltin*}(
    submission_req: ModelSubmissionRequest
) -> felt {
    alloc_locals;

    let (local arr: felt*) = alloc();
    assert arr[0] = submission_req.id;
    assert arr[1] = submission_req.model_id;
    assert arr[2] = submission_req.user_address;
    assert arr[3] = submission_req.model_commitment;
    assert arr[4] = submission_req.data_id;
    assert arr[5] = submission_req.problem_id;

    let (res) = poseidon_hash_many(5, arr);
    return res;
}
