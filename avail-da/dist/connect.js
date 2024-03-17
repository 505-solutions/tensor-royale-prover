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
const avail_js_sdk_1 = require("avail-js-sdk"); // Global import
const chain_1 = require("avail-js-sdk/chain"); // Modular import
const config_1 = __importDefault(require("./config"));
/**
 * Example to connect to a chain and get the ApiPromise.
 */
const main = () => __awaiter(void 0, void 0, void 0, function* () {
    const api = yield (0, avail_js_sdk_1.initialize)(config_1.default.endpoint);
    const [chain, nodeName, nodeVersion] = yield Promise.all([
        api.rpc.system.chain(),
        api.rpc.system.name(),
        api.rpc.system.version(),
    ]);
    console.log(`Connected to chain ${chain} using ${nodeName} and node version ${nodeVersion} - is connected: ${(0, chain_1.isConnected)()}`);
    yield (0, chain_1.disconnect)();
    process.exit(0);
});
main();
