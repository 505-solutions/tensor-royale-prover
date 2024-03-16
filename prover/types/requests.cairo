struct ProblemRequest {
    id: felt,
    user_address: felt,
    timestamp: felt,
    title: felt,
    reward: felt,
    deadline: felt,
    desc_lines_len: felt,
    desc_lines: felt*,
}

struct DataRequest {
    id: felt,
    dataset_commitment: felt,
    problem_id: felt,
    desc_lines_len: felt,
    desc_lines: felt*,
}

struct ModelSubmissionRequest {
    id: felt,
    user_address: felt,
    model_commitment: felt,
    data_id: felt,
    problem_id: felt,
}

struct VerificationRequest {
    id: felt,
    verifier_address: felt,
    model_idx: felt,
    class_confidence: felt,  // matrix_width (likely small)
    num_test_problems: felt,  // matrix_height (likely large)
    evaluations: felt**,
}
