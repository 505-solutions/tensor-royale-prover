// use std::convert::Infallible;
// use std::net::SocketAddr;

// use bytes::{Buf, Bytes};
// use http::{header, Method, StatusCode};
// use http_body_util::combinators::BoxBody;
// use http_body_util::{BodyExt, Full};
// use hyper::server::conn::http1;
// use hyper::service::service_fn;
// use hyper::{Request, Response};
// use serde_json::json;
// use tensor_royale_prover::utils::request_types::ProblemRequest;
// use tokio::net::TcpListener;

// // use futures::TryStreamExt as _; // for stream to_bytes

// use serde::ser;

// // type GenericError = Box<dyn std::error::Error + Send + Sync>;
// // type Result<T> = std::result::Result<T, GenericError>;
// // type BoxBody = http_body_util::combinators::BoxBody<Bytes, hyper::Error>;

// // fn serialize_request<T>(req: Request<T>) -> Result<Response<BoxBody<Bytes, hyper::Error>>, hyper::Error>
// // where
// //     T: ser::Serialize,
// // {
// //     let (parts, body) = req.into_parts();
// //     let body = serde_json::to_vec(&body)?;
// //     Ok(Request::from_parts(parts, body))
// // }

// async fn hello(req: Request<impl hyper::body::Body>) -> Result<Response<BoxBody<Bytes, hyper::Error>>, hyper::Error> {
//     match (req.method(), req.uri().path()) {
//         (&Method::GET, "/") => {
//             let mut ok = Response::default();
//             *ok.status_mut() = StatusCode::OK;
//             println!("default GET route hit");
//             Ok(ok)
//         }
//         (&Method::POST, "/problem") => {
//             let mut ok = Response::default();
//             *ok.status_mut() = StatusCode::OK;
//             println!("problem POST route hit");

//             Ok(ok)
//         }
//         (&Method::POST, "/data") => {
//             // let mut ok = Response::default();
//             // *ok.status_mut() = StatusCode::OK;
//             println!("dataset POST route hit");

//            // To protect our server, reject requests with bodies larger than
//             // 64kbs of data.
//             let max = req.body().size_hint().upper().unwrap_or(u64::MAX);

//             let whole_body = req.collect().await?.to_bytes();

//             let reversed_body = whole_body.iter().rev().cloned().collect::<Vec<u8>>();
//             Ok(Response::new(full(reversed_body)))

//             // let res2 = Response::new(Full::new(
//             //     json!({
//             //         "status": "ok",
//             //         "message": "dataset received"
//             //     })
//             //     .to_string()
//             //     .into(),
//             // ));

//             let mut ok = Response::default();
//             *ok.status_mut() = StatusCode::OK;
//             Ok(ok)
//         }
//         (&Method::POST, "/modelsubmission") => {
//             let mut ok = Response::default();
//             *ok.status_mut() = StatusCode::OK;
//             println!("model submission POST route hit");
//             Ok(ok)
//         }
//         (&Method::POST, "/verification") => {
//             let mut ok = Response::default();
//             *ok.status_mut() = StatusCode::OK;
//             println!("verification POST route hit");
//             Ok(ok)
//         }
//         _ => {
//             let mut not_found = Response::default();
//             *not_found.status_mut() = StatusCode::NOT_FOUND;
//             Ok(not_found)
//         }
//     }
// }

// #[tokio::main]
// pub async fn main() -> std::result::Result<(), Box<dyn std::error::Error + Send + Sync>> {
//     // This address is localhost
//     let addr: SocketAddr = ([127, 0, 0, 1], 4000).into();

//     // Bind to the port and listen for incoming TCP connections
//     let listener = TcpListener::bind(addr).await?;
//     println!("Listening on http://{}", addr);
//     loop {
//         let (tcp, _) = listener.accept().await?;
//         let io = TokioIo::new(tcp);

//         tokio::task::spawn(async move {
//             if let Err(err) = http1::Builder::new()
//                 .timer(TokioTimer::default())
//                 // .serve_connection(io, serv''ice_fn(hello))
//                 .await
//             {
//                 println!("Error serving connection: {:?}", err);
//             }
//         });
//     }
// }
