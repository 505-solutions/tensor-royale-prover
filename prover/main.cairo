%builtins output pedersen range_check ecdsa poseidon

from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin, HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.merkle_multi_update import merkle_multi_update
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.math_cmp import is_not_zero

from transactions.data_tx import verify_dataset_request
from transactions.problem_tx import verify_problem_request
from transactions.submission_tx import verify_submission_request
from transactions.verification_tx import verify_verification_request

from verification.ranking import rank_models

from transactions.utils import RequestOutput
from types.requests import ProblemRequest, DataRequest, ModelSubmissionRequest, VerificationRequest

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

    %{ request_input_data = program_input["swap_output_json"] %}
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

    local init_state_root: felt;
    local final_state_root: felt;
    %{
        ids.init_state_root = int(program_input["prev_state_root"])
        ids.final_state_root = int(program_input["new_state_root"])
    %}

    verify_merkle_tree_updates(
        init_state_root, final_state_root, squashed_state_dict, squashed_state_dict_len, tree_depth
    );

    local output_ptr: felt = cast(req_output_ptr, felt);

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
        req_type = current_request["request_type"]
    %}

    if (nondet %{ req_type == "problem" %} != 0) {
        verify_problem_request();

        return verify_requests();
    }

    if (nondet %{ req_type == "dataset" %} != 0) {
        verify_dataset_request();

        return verify_requests();
    }

    if (nondet %{ req_type == "model_submission" %} != 0) {
        verify_submission_request();

        return verify_requests();
    }
    if (nondet %{ req_type == "verification" %} != 0) {
        verify_verification_request();

        return verify_requests();
    }
    if (nondet %{ req_type == "rank_models" %} != 0) {
        rank_models();

        return verify_requests();
    } else {
        %{ print("unknown request type: ", current_request) %}
        return verify_requests();
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
        preimage = program_input["preimage_json"]
        preimage = {int(k):[int(x) for x in v] for k,v in preimage.items()}
    %}
    // merkle_multi_update{hash_ptr=pedersen_ptr}(
    //     squashed_state_dict, squashed_state_dict_len, state_tree_depth, prev_root, new_root
    // );

    return ();
}
//
