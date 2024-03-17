from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin, HashBuiltin
from starkware.cairo.common.dict import dict_new, dict_write, dict_update, dict_squash, dict_read
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.signature import verify_ecdsa_signature

func update_state{state_dict: DictAccess*}(state_idx: felt, leaf_hash: felt) {
    // * We assume that we can only add values and not remove them !!!

    // * --- --- --- --- ---
    let state_dict_ptr = state_dict;
    assert state_dict_ptr.key = state_idx;
    assert state_dict_ptr.prev_value = 0;
    assert state_dict_ptr.new_value = leaf_hash;

    let state_dict = state_dict + DictAccess.SIZE;

    return ();
}

// * WRITE TO OUTPUT =========================================

struct RequestOutput {
    id: felt,
    user_pub_key: felt,
    request_hash: felt,
}

func write_request_to_output{
    poseidon_ptr: PoseidonBuiltin*, range_check_ptr, req_output_ptr: RequestOutput*
}(request_id: felt, user_pub_key: felt, request_hash: felt) {
    alloc_locals;

    // & batched_note_info format: | deposit_id (64 bits) | token (32 bits) | amount (64 bits) |
    // & --------------------------  deposit_id => chain id (32 bits) | identifier (32 bits) |
    let output: RequestOutput* = req_output_ptr;
    assert output.id = request_id;
    assert output.user_pub_key = user_pub_key;
    assert output.request_hash = request_hash;

    let req_output_ptr = req_output_ptr + RequestOutput.SIZE;

    return ();
}

// * VERIFY SIGNATURE =========================================

func verify_req_signature{ecdsa_ptr: SignatureBuiltin*}(problem_hash: felt, user_pub_key: felt) {
    alloc_locals;

    local sig_r: felt;
    local sig_s: felt;
    %{
        # ids.sig_r = int(signature[0]) 
        # ids.sig_s = int(signature[1])
    %}

    // verify_ecdsa_signature(
    //     message=problem_hash, public_key=user_pub_key, signature_r=sig_r, signature_s=sig_s
    // );

    return ();
}

// * ==========================================================

func append_flatend_matrix(
    base_arr_len: felt, base_arr: felt*, matrix_width: felt, matrix_height: felt, matrix: felt**
) -> (felt, felt*) {
    if (matrix_height == 0) {
        return (base_arr_len, base_arr);
    }

    let row: felt* = matrix[0];
    let (base_arr_len, base_arr) = push_to_array(base_arr_len, base_arr, matrix_width, row);

    return append_flatend_matrix(
        base_arr_len, base_arr, matrix_width, matrix_height - 1, &matrix[1]
    );
}

func push_to_array(base_arr_len: felt, base_arr: felt*, addition_len: felt, addition: felt*) -> (
    felt, felt*
) {
    if (addition_len == 0) {
        return (base_arr_len, base_arr);
    }

    assert base_arr[base_arr_len] = addition[0];

    return push_to_array(base_arr_len + 1, base_arr, addition_len - 1, &addition[1]);
}
