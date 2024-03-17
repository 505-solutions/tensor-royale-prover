"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const avail_js_sdk_1 = require("avail-js-sdk");
const config_1 = __importDefault(require("./config"));
/**
 * Example to submit data and retrieve the data from the block.
 */
const main = () => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const data = "0x69111111111111111111111111111111111111111111111111111111111111111111111111111";
        const api = yield (0, avail_js_sdk_1.initialize)(config_1.default.endpoint);
        const keyring = (0, avail_js_sdk_1.getKeyringFromSeed)(config_1.default.seed);
        const options = { app_id: config_1.default.appId, nonce: -1 };
        yield api.tx.dataAvailability
            .submitData(data)
            .signAndSend(keyring, options, ({ status, events, txHash }) => __awaiter(void 0, void 0, void 0, function* () {
            if (status.isInBlock) {
                // Print inclusion data
                console.log(`Transaction included at blockHash ${status.asInBlock}`);
                events.forEach(({ event: { data, method, section } }) => {
                    console.log(`\t' ${section}.${method}:: ${data}`);
                });
                // Print input
                const data = yield (0, avail_js_sdk_1.extractData)(api, status.asInBlock.toString(), txHash.toString());
                console.log(`Data submitted: ${data}`);
                process.exit(0);
            }
        }));
    }
    catch (err) {
        console.error(err);
        process.exit(1);
    }
});
main();
