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

func build_error_rates_array{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
}(model_ids_len: felt, model_ids: felt*, err_rates_len: felt, err_rates: felt*) -> (felt, felt*) {
    alloc_locals;

    if (model_ids_len == 0) {
        return (err_rates_len, err_rates);
    }

    let error_rate = get_model_error_rate(model_ids[0]);

    assert err_rates[err_rates_len] = error_rate;

    return build_error_rates_array(model_ids_len - 1, &model_ids[1], err_rates_len + 1, err_rates);
}

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

// * GET ERROR RATE HELPERS ==============================================

func build_consensus_matrix{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}(
    num_verifications: felt,
    verifications: VerificationRequest*,
    matrix_len: felt,
    matrix: felt**,
    num_rows: felt,
    num_columns: felt,
) -> (felt, felt**) {
    alloc_locals;

    if (matrix_len == num_rows) {
        return (matrix_len, matrix);
    }

    // for x in row:
    //     for y in row:
    //        matrix[x][y] = get_matrix_element_median(num_verifications, verifications, x, y)

    let (local arr: felt*) = alloc();
    let (_, row: felt*) = build_ith_row(
        num_verifications, verifications, matrix_len, num_columns, arr, alloc
    );

    assert matrix[matrix_len] = row;

    return build_consensus_matrix(
        num_verifications, verifications, matrix_len + 1, matrix, num_rows, num_columns
    );
}

// * GET ERROR RATE HELPERS ==============================================

func sum_matrix_error_distances{range_check_ptr}(
    matrix_len: felt, matrix: felt**, row_length: felt, real_results: felt**, error_sum: felt
) -> felt {
    alloc_locals;

    if (matrix_len == 0) {
        return error_sum;
    }

    let row_error_sum: felt = sum_row_error_distances(row_length, matrix[0], real_results[0], 0);

    return sum_matrix_error_distances(
        matrix_len - 1, &matrix[1], row_length, error_sum + row_error_sum
    );
}

func sum_row_error_distances{range_check_ptr}(
    row_len: felt, row: felt*, real_results: felt*, error_sum: felt
) -> (felt, felt*) {
    alloc_locals;

    if (arr_len == 0) {
        return error_sum;
    }

    let err_dist = abs_value(row[0] - real_results[0]);

    return sum_row_error_distances(row_len - 1, &row[1], &real_results[1], error_sum + err_dist);
}

// * BUILD MATRIX HELPERS ================================================

func build_ith_row{range_check_ptr}(
    num_verifications: felt,
    verifications: VerificationRequest*,
    i: felt,
    row_length: felt,
    arr_len: felt,
    arr: felt*,
) -> (felt, felt*) {
    alloc_locals;

    if (arr_len == row_length) {
        return (arr_len, arr);
    }

    let median: felt = get_matrix_element_median(num_verifications, verifications, i, arr_len);

    arr[arr_len] = median;

    return build_ith_row(num_verifications, verifications, i, row_length, arr_len + 1, arr);
}

func get_matrix_element_median{range_check_ptr}(
    num_verifications: felt, verifications: VerificationRequest*, i: felt, j: felt
) -> felt {
    alloc_locals;

    // TODO: Implement logic
    let rand: VerificationRequest = verifications[num_verifications / 2];

    return rand.evaluations[i][j];
}

func sort_models_by_error_rate{range_check_ptr}(
    num_verifications: felt, verifications: VerificationRequest*, i: felt, j: felt
) -> felt {
    alloc_locals;

    // TODO: Implement logic
    let rand: VerificationRequest = verifications[num_verifications / 2];

    return rand.evaluations[i][j];
}

// * PROGRAM INPUT ================================================
func handle_program_input{range_check_ptr}() -> (felt, VerificationRequest*) {
    alloc_locals;

    // & This is the public on_chain deposit information

    local verifications_len: felt;
    local verifications: VerificationRequest*;
    %{
        verifications = current_request["verifications"]
        memory[ids.verifications_len] = len(verifications)
        memory[ids.verifications] = verifications_addr = segments.add()
        for i in range(len(verifications)):
            current_request = verifications[i]
            memory[verifications_addr + i*ids.VerificationRequest.SIZE + VerificationRequest.id] = int(current_request["id"])
            memory[verifications_addr + i*ids.VerificationRequest.SIZE  + VerificationRequest.verifier_address] = int(current_request["verifier_address"])
            memory[verifications_addr + i*ids.VerificationRequest.SIZE  + VerificationRequest.class_confidence] = int(current_request["class_confidence"])
            memory[verifications_addr + i*ids.VerificationRequest.SIZE  + VerificationRequest.num_test_problems] = int(current_request["num_test_problems"])

            rows_len = len(current_request["evaluations"])
            columns_len = len(current_request["evaluations"][0])
            for i in range(rows_len):
                for j in range(columns_len):
                    matrix_addr_start = i*ids.VerificationRequest.SIZE + VerificationRequest.evaluations
                    memory[verifications_addr + matrix_addr_start + i*columns_len + j] = int(current_request["evaluations"][i][j])
    %}

    return verification_req;
}

func get_real_results{range_check_ptr}() -> (felt, VerificationRequest*) {
    alloc_locals;

    // & This is the public on_chain deposit information

    local real_results_len: felt;
    local real_results: felt**;
    %{
        real_results = current_request["real_results"]

        rows_len = len(current_request["real_results"])
        columns_len = len(current_request["real_results"][0])
        for i in range(rows_len):
            for j in range(columns_len):
                memory[ids.real_results.address_ + i*columns_len + j] = int(current_request["real_results"][i][j])
    %}

    return verification_req;
}
