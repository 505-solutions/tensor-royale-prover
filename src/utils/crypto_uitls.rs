use std::str::FromStr;

use num_bigint::BigUint;
use starknet::core::{
    crypto::{
        compute_hash_on_elements, ecdsa_verify, pedersen_hash, poseidon_hash, poseidon_hash_many,
        Signature as StarknetSignature,
    },
    types::FieldElement,
};
// use starknet::

pub fn pedersen(a: &BigUint, b: &BigUint) -> BigUint {
    let left = FieldElement::from_dec_str(&a.to_string()).unwrap();
    let right = FieldElement::from_dec_str(&b.to_string()).unwrap();

    let res = pedersen_hash(&left, &right);

    let hash = BigUint::from_str(&res.to_string()).unwrap();

    return hash;
}

pub fn pedersen_on_vec(arr: &Vec<&BigUint>) -> BigUint {
    let input = arr
        .iter()
        .map(|el| FieldElement::from_dec_str(&el.to_string()).unwrap())
        .collect::<Vec<FieldElement>>();
    let input: &[FieldElement] = &input.as_slice();

    let res = compute_hash_on_elements(input);

    let hash = BigUint::from_str(&res.to_string()).unwrap();

    return hash;
}

pub fn hash(a: &BigUint, b: &BigUint) -> BigUint {
    let left = FieldElement::from_dec_str(&a.to_string()).unwrap();
    let right = FieldElement::from_dec_str(&b.to_string()).unwrap();

    let res = poseidon_hash(left, right);

    let hash = BigUint::from_str(&res.to_string()).unwrap();

    return hash;
}

pub fn hash_many(arr: &Vec<&BigUint>) -> BigUint {
    let input = arr
        .iter()
        .map(|el| FieldElement::from_dec_str(&el.to_string()).unwrap())
        .collect::<Vec<FieldElement>>();
    let input: &[FieldElement] = &input.as_slice();

    let res = poseidon_hash_many(input);

    let hash = BigUint::from_str(&res.to_string()).unwrap();

    return hash;
}

pub fn verify(stark_key: &BigUint, msg_hash: &BigUint, signature: &Signature) -> bool {
    match ecdsa_verify(
        &FieldElement::from_dec_str(&stark_key.to_string()).unwrap(),
        &FieldElement::from_dec_str(&msg_hash.to_string()).unwrap(),
        &signature.to_starknet_signature(),
    ) {
        Ok(valid) => {
            return valid;
        }
        Err(_) => {
            return false;
        }
    }
}

// * STRUCTS ======================================================================================

use serde::{
    ser::{Serialize, SerializeStruct, SerializeTuple, Serializer},
    Deserialize, Deserializer,
};

#[derive(Debug, Clone)]
pub struct Signature {
    pub r: String,
    pub s: String,
}

// * SERIALIZE * //
impl Serialize for Signature {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut sig = serializer.serialize_tuple(2)?;

        sig.serialize_element(&self.r)?;
        sig.serialize_element(&self.s)?;

        return sig.end();
    }
}

impl Signature {
    fn to_starknet_signature(&self) -> StarknetSignature {
        return StarknetSignature {
            r: FieldElement::from_dec_str(&self.r.to_string()).unwrap(),
            s: FieldElement::from_dec_str(&self.s.to_string()).unwrap(),
        };
    }
}

impl<'de> Deserialize<'de> for Signature {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let tup = <(String, String)>::deserialize(deserializer)?;

        Ok(Signature { r: tup.0, s: tup.1 })
    }
}
