from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.math import abs_value
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.usort import usort
from starkware.cairo.common.builtin_poseidon.poseidon import poseidon_hash_many

from transactions.utils import (
    update_state,
    write_request_to_output,
    verify_req_signature,
    append_flatend_matrix,
    RequestOutput,
)

from types.requests import VerificationRequest

from verification.error_rate import build_error_rates_array

// *

func rank_models{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}() {
    alloc_locals;

    local problem_id: felt;
    %{ ids.problem_id = current_request["problem_id"] %}

    let (model_ids_len: felt, model_ids: felt*) = handle_program_input();

    let (local empty_arr: felt*) = alloc();
    let (error_rates_len, error_rates) = build_error_rates_array(
        model_ids_len, model_ids, 0, empty_arr
    );

    let (sorted_error_rates_len: felt, sorted_error_rates: felt*, multiplicities: felt*) = usort(
        error_rates_len, error_rates
    );

    let (local empty_arr: felt*) = alloc();
    let (sorted_models_len, sorted_models) = build_rankings_array(
        model_ids_len,
        model_ids,
        error_rates_len,
        error_rates,
        sorted_error_rates_len,
        sorted_error_rates,
        0,
        empty_arr,
    );

    let (data_commitment) = poseidon_hash_many(sorted_models_len, sorted_models);

    write_request_to_output(problem_id, 0, data_commitment);

    return ();
}

//

func build_rankings_array{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
}(
    model_ids_len: felt,
    model_ids: felt*,
    unsorted_err_rates_len: felt,
    unsorted_err_rates: felt*,
    sorted_err_rates_len: felt,
    sorted_err_rates: felt*,
    sorted_models_len: felt,
    sorted_models: felt*,
) -> (felt, felt*) {
    alloc_locals;

    if (sorted_err_rates_len == 0) {
        return (sorted_models_len, sorted_models);
    }

    let model_id: felt = find_model_id(
        model_ids_len, model_ids, unsorted_err_rates_len, unsorted_err_rates, sorted_err_rates[0]
    );

    assert sorted_models[sorted_models_len] = model_id;

    return build_rankings_array(
        model_ids_len,
        model_ids,
        unsorted_err_rates_len,
        unsorted_err_rates,
        sorted_err_rates_len - 1,
        &sorted_err_rates[1],
        sorted_models_len + 1,
        sorted_models,
    );
}

func find_model_id{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
}(
    model_ids_len: felt,
    model_ids: felt*,
    unsorted_err_rates_len: felt,
    unsorted_err_rates: felt*,
    err_rate: felt,
) -> felt {
    if (unsorted_err_rates[0] == err_rate) {
        return model_ids[0];
    }

    return find_model_id(
        model_ids_len - 1,
        &model_ids[1],
        unsorted_err_rates_len - 1,
        &unsorted_err_rates[1],
        err_rate,
    );
}

func handle_program_input{range_check_ptr}() -> (felt, felt*) {
    alloc_locals;

    local model_ids_len: felt;
    local model_ids: felt*;
    %{
        models_len = len(current_request["model_ids"])
        ids.model_ids_len = models_len

        memory[ids.model_ids.address_] = models_address = segments.add()
        for i in range(models_len):
            memory[models_address + i] = int(current_request["model_ids"][i])
    %}

    return (model_ids_len, model_ids);
}
