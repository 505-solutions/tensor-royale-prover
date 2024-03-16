from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, SignatureBuiltin
from starkware.cairo.common.dict_access import DictAccess

from transactions.utils import (
    update_state,
    write_request_to_output,
    verify_req_signature,
    push_to_array,
    RequestOutput
)

from types.requests import DataRequest

func verify_dataset_request{
    poseidon_ptr: PoseidonBuiltin*,
    ecdsa_ptr: SignatureBuiltin*,
    range_check_ptr,
    state_dict: DictAccess*,
    req_output_ptr: RequestOutput*,
}() {
    alloc_locals;

    let dataset_req: DataRequest = handle_program_input();

    let dataset_hash = hash_dataset_req(dataset_req);

    local public_key: felt;
    %{ ids.public_key = int(current_request["public_key"]) %}
    verify_req_signature(dataset_hash, public_key);

    local state_idx: felt;
    %{ ids.state_idx = current_request["state_idx"] %}
    update_state(state_idx, dataset_hash);

    write_request_to_output(dataset_req.id, public_key, dataset_hash);

    return ();
}

// * HELPERS =======================================================

func handle_program_input{range_check_ptr}() -> DataRequest {
    alloc_locals;

    // & This is the public on_chain deposit information
    local dataset_req: DataRequest;
    %{
        data_request = current_request["data_request"]
        memory[ids.dataset_req.address_ + DataRequest.id] = int(data_request["id"])
        memory[ids.dataset_req.address_ + DataRequest.dataset_commitment] = int(data_request["dataset_commitment"])
        memory[ids.dataset_req.address_ + DataRequest.problem_id] = int(data_request["problem_id"])
        memory[ids.dataset_req.address_ + DataRequest.desc_hash] = int(data_request["desc_hash"])

        # desc_lines = current_request["desc_lines"]

        # memory[ids.desc_lines_len] = len(desc_lines)
        # memory[ids.desc_lines] = desc_lines_addr = segments.add()
        # for i in range(len(desc_lines)):
        #     memory[desc_lines_addr + i] = int(desc_lines[i])
    %}

    return dataset_req;
}

func hash_dataset_req{poseidon_ptr: PoseidonBuiltin*}(dataset_req: DataRequest) -> felt {
    alloc_locals;

    let (local arr: felt*) = alloc();
    assert arr[0] = dataset_req.id;
    assert arr[1] = dataset_req.dataset_commitment;
    assert arr[2] = dataset_req.problem_id;
    assert arr[3] = dataset_req.desc_hash;

    let (res) = poseidon_hash_many(4, arr);
    return res;
}
