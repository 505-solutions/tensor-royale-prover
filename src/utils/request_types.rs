use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct ProblemRequest {
    pub id: String,
    pub user_address: String,
    pub timestamp: u32,
    pub title: String,
    pub reward: String,
    pub deadline: u32,
    pub desc_hash: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DataRequest {
    pub id: String,
    pub dataset_commitment: String,
    pub problem_id: String,
    pub desc_hash: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ModelSubmissionRequest {
    pub id: String,
    pub user_address: String,
    pub model_commitment: String,
    pub data_id: String,
    pub problem_id: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VerificationRequest {
    pub id: String,
    pub verifier_address: String,
    pub class_confidence: u32,  // matrix_width (likely small)
    pub num_test_problems: u32, // matrix_height (likely large)
    pub evaluations: Vec<Vec<u32>>,
}

// * Serializations * //

// use serde::ser::{Serialize, SerializeStruct, Serializer};

// impl Serialize for ProblemRequest {
//     fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
//     where
//         S: Serializer,
//     {
//         let mut note = serializer.serialize_struct("ProblemRequest", 6)?;

//         note.serialize_field("id", &self.id.to_string())?;
//         note.serialize_field("user_address", &self.user_address)?;
//         note.serialize_field("timestamp", &self.timestamp)?;
//         note.serialize_field("title", &self.title)?;
//         note.serialize_field("reward", &self.reward.to_string())?;
//         note.serialize_field("deadline", &self.deadline)?;
//         note.serialize_field("desc_hash", &self.desc_hash)?;

//         return note.end();
//     }
// }

// impl Serialize for DataRequest {
//     fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
//     where
//         S: Serializer,
//     {
//         let mut note = serializer.serialize_struct("DataRequest", 4)?;

//         note.serialize_field("id", &self.id.to_string())?;
//         note.serialize_field("dataset_commitment", &self.dataset_commitment)?;
//         note.serialize_field("problem_id", &self.problem_id)?;
//         note.serialize_field("desc_hash", &self.desc_hash)?;

//         return note.end();
//     }
// }

// impl Serialize for ModelSubmissionRequest {
//     fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
//     where
//         S: Serializer,
//     {
//         let mut note = serializer.serialize_struct("ModelSubmissionRequest", 5)?;

//         note.serialize_field("id", &self.id.to_string())?;
//         note.serialize_field("user_address", &self.user_address)?;
//         note.serialize_field("model_commitment", &self.model_commitment)?;
//         note.serialize_field("data_id", &self.data_id)?;
//         note.serialize_field("problem_id", &self.problem_id)?;

//         return note.end();
//     }
// }

// impl Serialize for VerificationRequest {
//     fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
//     where
//         S: Serializer,
//     {
//         let mut note = serializer.serialize_struct("VerificationRequest", 5)?;

//         note.serialize_field("id", &self.id.to_string())?;
//         note.serialize_field("verifier_address", &self.verifier_address)?;
//         note.serialize_field("class_confidence", &self.class_confidence)?;
//         note.serialize_field("num_test_problems", &self.num_test_problems)?;
//         note.serialize_field("evaluations", &self.evaluations)?;

//         return note.end();
//     }
// }
