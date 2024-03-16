struct ProblemRequest {
    id: felt,
    user_address: felt,
    timestamp: felt,
    title: felt,
    reward: felt,
    deadline: felt,
    desc_hash: felt,
}

struct DataRequest {
    id: felt,
    dataset_commitment: felt,
    problem_id: felt,
    desc_hash: felt,
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
    model_id: felt,
    verifier_address: felt,
    class_confidence: felt,  // matrix_width (likely small)
    num_test_problems: felt,  // matrix_height (likely large)
    evaluations: felt**,
}

// ******************************
