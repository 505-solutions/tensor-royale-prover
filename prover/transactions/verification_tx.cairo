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
    %{ ids.public_key = int(current_request["public_key"]) if "public_key" in current_request else 0 %}
    verify_req_signature(verification_hash, public_key);

    local state_idx: felt;
    %{ ids.state_idx = current_request["state_index"] %}
    update_state(state_idx, verification_hash);

    write_request_to_output(verification_req.id, public_key, verification_hash);

    return ();
}

// * HELPERS =======================================================

func handle_program_input{range_check_ptr}() -> VerificationRequest {
    alloc_locals;

    local verification_req: VerificationRequest;
    %{
        verification_request = current_request["verification_request"]
        memory[ids.verification_req.address_ + ids.VerificationRequest.id] = int(verification_request["id"])
        memory[ids.verification_req.address_ + ids.VerificationRequest.verifier_address] = int(verification_request["verifier_address"])
        memory[ids.verification_req.address_ + ids.VerificationRequest.class_confidence] = int(verification_request["class_confidence"])
        memory[ids.verification_req.address_ + ids.VerificationRequest.num_test_problems] = int(verification_request["num_test_problems"])

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
