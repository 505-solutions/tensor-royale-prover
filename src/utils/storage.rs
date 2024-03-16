// use std::{collections::HashMap, fs, time::SystemTime};

// use num_bigint::BigUint;
// use serde::{Deserialize, Serialize};
// use serde_json::{json, Map, Value};

// use sled::Config;

// use super::request_types::VerificationRequest;

// type StorageResult = std::result::Result<(), Box<dyn std::error::Error>>;

// /// The main storage struct that stores all the data on disk.
// pub struct Storage {
//     pub verification_db: sled::Db,
// }

// impl Storage {
//     pub fn new() -> Self {
//         let dir = fs::read_dir("storage");

//         let config = Config::new().path("./storage/verifications".to_string());
//         let verification_db = config.open().unwrap();

//         Storage { verification_db }
//     }

//     // * FUNDING INFO ————————————————————————————————————————————————————————————————————- //

//     pub fn store_verification(&self, problem_id: u32, verification: VerificationRequest) {
//         let count = self
//             .verification_db
//             .get(problem_id.to_string() + "count")
//             .unwrap();
//         let count: u64 = serde_json::from_slice(&count.unwrap().to_vec()).unwrap();

//         self.verification_db
//             .insert(
//                 problem_id.to_string() + "-" + &count.to_string(),
//                 serde_json::to_vec(&verification).unwrap(),
//             )
//             .unwrap();
//         self.verification_db
//             .insert(problem_id.to_string() + "count", count + 1)
//             .unwrap();
//     }

//     pub fn get_all_verifications(&self, problem_id: u32) -> Vec<VerificationRequest> {
//         let count = self
//             .verification_db
//             .get(problem_id.to_string() + "count")
//             .unwrap();
//         let count: u64 = serde_json::from_slice(&count.unwrap().to_vec()).unwrap();

//         let mut verifications = vec![];
//         for i in 0..count {
//             let verification = self
//                 .verification_db
//                 .get(problem_id.to_string() + "-" + &i.to_string())
//                 .unwrap();

//             let verification: VerificationRequest =
//                 serde_json::from_slice(&verification.unwrap().to_vec()).unwrap();
//             verifications.push(verification);
//         }

//         return verifications;
//     }
// }
