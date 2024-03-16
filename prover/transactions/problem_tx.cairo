from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess

from transaction.utils import (
    update_state,
    write_request_to_output,
    verify_req_signature,
    push_to_array,
)

from types.requests import ProblemRequest

func verify_problem_request{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}() {
    alloc_locals;

    let problem_req: ProblemRequest = handle_program_input();

    let problem_hash = hash_problem_req(problem_req);

    local public_key: felt;
    %{ ids.public_key = int(current_request["public_key"]) %}
    verify_req_signature(problem_hash, public_key);

    local state_idx: felt;
    %{ ids.state_idx = current_request["state_idx"] %}
    update_state(state_idx, problem_hash);

    write_request_to_output(problem_req.id, public_key, problem_hash);

    return ();
}

// * HELPERS =======================================================

func handle_program_input{range_check_ptr}() -> ProblemRequest {
    alloc_locals;

    // & This is the public on_chain deposit information
    local problem_req: ProblemRequest;
    %{
        memory[ids.problem_req.address_ + ProblemRequest.user_address] = int(current_request["user_address"])
        memory[ids.problem_req.address_ + ProblemRequest.timestamp] = int(current_request["timestamp"])
        memory[ids.problem_req.address_ + ProblemRequest.title] = int(current_request["title"])
        memory[ids.problem_req.address_ + ProblemRequest.id] = int(current_request["id"])
        memory[ids.problem_req.address_ + ProblemRequest.payment] = int(current_request["payment"])
        memory[ids.problem_req.address_ + ProblemRequest.deadline] = int(current_request["deadline"])
        memory[ids.problem_req.address_ + ProblemRequest.desc_hash] = int(current_request["desc_hash"])

        # desc_lines = current_request["desc_lines"]

        # memory[ids.desc_lines_len] = len(desc_lines)
        # memory[ids.desc_lines] = desc_lines_addr = segments.add()
        # for i in range(len(desc_lines)):
        #     memory[desc_lines_addr + i] = int(desc_lines[i])
    %}

    return problem_req;
}

func hash_problem_req{poseidon_ptr: PoseidonBuiltin*}(problem_req: ProblemRequest) -> felt {
    alloc_locals;

    let (local arr: felt*) = alloc();
    assert arr[0] = problem_req.user_address;
    assert arr[1] = problem_req.timestamp;
    assert arr[2] = problem_req.title;
    assert arr[3] = problem_req.id;
    assert arr[4] = problem_req.payment;
    assert arr[5] = problem_req.deadline;
    assert arr[6] = problem_req.desc_hash;

    let (res) = poseidon_hash_many(7, arr);
    return res;
}
