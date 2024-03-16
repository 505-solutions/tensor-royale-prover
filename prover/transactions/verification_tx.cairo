from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess

from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.builtin_poseidon.poseidon import poseidon_hash_many

from transactions.utils import (
    update_state,
    write_request_to_output,
    verify_req_signature,
    append_flatend_matrix,
    RequestOutput,
)

from types.requests import VerificationRequest

func verify_verification_request{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}() {
    alloc_locals;

    let verification_req: VerificationRequest = handle_program_input();

    let verification_hash = hash_verification_req(verification_req);

    local public_key: felt;
    %{ ids.public_key = int(current_request["public_key"]) %}
    verify_req_signature(verification_hash, public_key);

    local state_idx: felt;
    %{ ids.state_idx = current_request["state_idx"] %}
    update_state(state_idx, verification_hash);

    write_request_to_output(verification_req.id, public_key, verification_hash);

    return ();
}

// * HELPERS =======================================================

func handle_program_input{range_check_ptr}() -> VerificationRequest {
    alloc_locals;

    local verification_req: VerificationRequest;
    %{
        memory[ids.verification_req.address_ + VerificationRequest.id] = int(current_request["id"])
        memory[ids.verification_req.address_ + VerificationRequest.verifier_address] = int(current_request["verifier_address"])
        memory[ids.verification_req.address_ + VerificationRequest.class_confidence] = int(current_request["class_confidence"])
        memory[ids.verification_req.address_ + VerificationRequest.num_test_problems] = int(current_request["num_test_problems"])

        rows_len = len(current_request["evaluations"])
        columns_len = len(current_request["evaluations"][0])
        memory[ids.verification_req.address_ + VerificationRequest.evaluations] = matrix_addr = segments.add()
        for i in range(rows_len):
            for j in range(columns_len):
                memory[matrix_addr + i*columns_len + j] = int(current_request["evaluations"][i][j])
    %}

    return verification_req;
}

func hash_verification_req{poseidon_ptr: PoseidonBuiltin*}(
    verification_req: VerificationRequest
) -> felt {
    alloc_locals;

    let (local arr: felt*) = alloc();
    assert arr[0] = verification_req.id;
    assert arr[1] = verification_req.verifier_address;
    assert arr[2] = verification_req.class_confidence;
    assert arr[3] = verification_req.num_test_problems;

    let (base_arr_len, base_arr) = append_flatend_matrix(
        4,
        arr,
        verification_req.class_confidence,
        verification_req.num_test_problems,
        verification_req.evaluations,
    );

    let (res) = poseidon_hash_many(base_arr_len, base_arr);
    return res;
}
