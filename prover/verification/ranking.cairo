from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.math import abs_value

from transaction.utils import (
    update_state,
    write_request_to_output,
    verify_req_signature,
    append_flatend_matrix,
)

from types.requests import VerificationRequest

// *

func get_model_error_rate{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}(model_id: felt) -> felt {
    alloc_locals;

    local num_verifications: felt;
    %{
        verifications = current_request["verifications"][ids.model_id] # List of VerificationRequest
        ids.num_verifications = len(verifications)
    %}

    local verifications: VerificationRequest* = handle_program_input();
    // TODO: Check that all verifications exist in the state and are for the same problem

    // Build the consensus matrix
    let (local empty_matrix: felt**) = alloc();
    let (_, matrix: felt**) = build_consensus_matrix(
        num_verifications,
        verifications,
        0,
        empty_matrix,
        verifications[0].num_test_problems,
        verifications[0].class_confidence,
    );

    // For each verification get error rate and sort the array to get the most accurate models
    local real_results: felt** = get_real_results();
    let error_rate: felt = sum_matrix_error_distances(num_verifications, matrix, real_results);

    return error_rate;
}
