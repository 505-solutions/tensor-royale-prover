from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.builtin_poseidon.poseidon import poseidon_hash_many

from transactions.utils import (
    update_state,
    write_request_to_output,
    verify_req_signature,
    push_to_array,
    RequestOutput,
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
    %{ ids.public_key = int(current_request["public_key"]) if "public_key" in current_request else 0 %}
    verify_req_signature(submission_hash, public_key);

    local state_idx: felt;
    %{ ids.state_idx = current_request["state_index"] %}
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
        submission_request = current_request["submission_request"]
        memory[ids.submission_req.address_ + ids.ModelSubmissionRequest.id] = int(submission_request["id"])
        memory[ids.submission_req.address_ + ids.ModelSubmissionRequest.user_address] = int(submission_request["author"])
        memory[ids.submission_req.address_ + ids.ModelSubmissionRequest.model_commitment] = int(submission_request["model"])
        memory[ids.submission_req.address_ + ids.ModelSubmissionRequest.data_id] = int(submission_request["data_id"])
    %}

    return submission_req;
}

func hash_submission_req{poseidon_ptr: PoseidonBuiltin*}(
    submission_req: ModelSubmissionRequest
) -> felt {
    alloc_locals;

    let (local arr: felt*) = alloc();
    assert arr[0] = submission_req.id;
    assert arr[1] = submission_req.id;
    assert arr[2] = submission_req.user_address;
    assert arr[3] = submission_req.model_commitment;
    assert arr[4] = submission_req.data_id;

    let (res) = poseidon_hash_many(5, arr);
    return res;
}
