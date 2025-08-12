"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const ws_1 = __importDefault(require("ws"));
if (typeof globalThis.WebSocket === 'undefined') {
    globalThis.WebSocket = ws_1.default;
}
//# sourceMappingURL=polyfills.js.map