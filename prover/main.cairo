%builtins output pedersen range_check ecdsa poseidon

from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin, HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.merkle_multi_update import merkle_multi_update
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.cairo_keccak.keccak import finalize_keccak
func main{
    output_ptr,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
    poseidon_ptr: PoseidonBuiltin*,
}() {
    alloc_locals;

    local state_dict: DictAccess*;  // Dictionary of updated notes (idx -> note hash)
    %{ ids.state_dict = segments.add() %}
    let state_dict_start = state_dict;

    local req_output_ptr: RequestOutput* = cast(output_ptr, RequestOutput*);

    verify_requests{state_dict=state_dict, req_output_ptr=req_output_ptr}();

    local squashed_state_dict: DictAccess*;
    %{ ids.squashed_state_dict = segments.add() %}
    let (squashed_state_dict_end) = squash_dict(
        dict_accesses=state_dict_start,
        dict_accesses_end=state_dict,
        squashed_dict=squashed_state_dict,
    );
    local squashed_state_dict_len = (squashed_state_dict_end - squashed_state_dict) /
        DictAccess.SIZE;

    // * VERIFY MERKLE TREE UPDATES ***********************
    let tree_depth = 16;
    verify_merkle_tree_updates(
        global_config.dex_state.init_state_root,
        global_config.dex_state.final_state_root,
        squashed_state_dict,
        squashed_state_dict_len,
        tree_depth,
    );

    // * WRITE STATE UPDATES TO THE PROGRAM OUTPUT ******************************
    %{ stored_indexes = {} %}
    let (data_commitment: felt) = write_state_updates_to_output(
        squashed_state_dict,
        squashed_state_dict_len,
        note_updates_start,
        global_config.dex_state.n_output_notes,
        global_config.dex_state.n_output_positions,
        global_config.dex_state.n_output_tabs,
        global_config.dex_state.n_zero_indexes,
    );
    local da_output_ptr: felt* = cast(position_escape_output_ptr, felt*);
    assert da_output_ptr[0] = data_commitment;

    %{ print("da_output_ptr: ", ids.data_commitment) %}

    // * WRITE DEPOSIT AND WITHDRAWAL ACCUMULATED OUTPUTS TO THE PROGRAM OUTPUT ***********
    let deposit_output_len = (l2_deposit_outputs - l2_deposit_outputs_start) /
        DepositTransactionOutput.SIZE;
    let withdraw_output_len = (l2_withdrawal_outputs - l2_withdrawal_outputs_start) /
        WithdrawalTransactionOutput.SIZE;
    write_accumulated_hashes_to_output{
        keccak_ptr=keccak_ptr, accumulated_hashes=accumulated_hashes, global_config=global_config
    }(
        deposit_output_len,
        l2_deposit_outputs_start,
        withdraw_output_len,
        l2_withdrawal_outputs_start,
    );

    // * FINALIZE KECCAK ***************************************************************
    finalize_keccak(keccak_ptr_start=keccak_ptr_start, keccak_ptr_end=keccak_ptr);

    local output_ptr: felt = cast(da_output_ptr + 1, felt);

    %{ print("all good") %}

    return ();
}

func verify_requests{
    poseidon_ptr: PoseidonBuiltin*,
    range_check_ptr,
    ecdsa_ptr: SignatureBuiltin*,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}() {
    alloc_locals;

    if (nondet %{ len(request_input_data) == 0 %} != 0) {
        return ();
    }

    %{
        current_request = request_input_data.pop(0) 
        tx_type = current_request["request_type"]
    %}

    if (nondet %{ tx_type == "swap" %} != 0) {
        %{ current_swap = current_request %}

        execute_swap();

        return execute_requests();
    }

    if (nondet %{ tx_type == "deposit" %} != 0) {
        %{ current_deposit = current_request["deposit"] %}

        verify_deposit();

        return execute_requests();
    }

    if (nondet %{ tx_type == "withdrawal" %} != 0) {
        %{ current_withdrawal = current_request["withdrawal"] %}

        verify_withdrawal();

        return execute_requests();
    } else {
        %{ print("unknown request type: ", current_request) %}
        return execute_requests();
    }
}

func verify_merkle_tree_updates{pedersen_ptr: HashBuiltin*, range_check_ptr}(
    prev_root: felt,
    new_root: felt,
    squashed_state_dict: DictAccess*,
    squashed_state_dict_len: felt,
    state_tree_depth: felt,
) {
    %{
        preimage = program_input["preimage"]
        preimage = {int(k):[int(x) for x in v] for k,v in preimage.items()}
    %}
    merkle_multi_update{hash_ptr=pedersen_ptr}(
        squashed_state_dict, squashed_state_dict_len, state_tree_depth, prev_root, new_root
    );

    return ();
}
//