"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const iqoption_1 = __importDefault(require("@mvh/iqoption"));
let AuthService = class AuthService {
    async login({ identifier, password }) {
        const loginResponse = await iqoption_1.default.http.auth.login({
            identifier,
            password,
        });
        if (loginResponse?.success && loginResponse?.data?.ssid) {
            const sessionResponse = await iqoption_1.default.http.auth.session().catch(() => ({ success: false }));
            if (sessionResponse?.success && sessionResponse?.data?.expires_at) {
                try {
                    iqoption_1.default.http.setCookie(loginResponse.data.ssid, Number(sessionResponse.data.expires_at));
                }
                catch {
                }
            }
        }
        return {
            success: Boolean(loginResponse?.success),
            token: null,
            raw: loginResponse ?? null,
        };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)()
], AuthService);
//# sourceMappingURL=auth.service.js.map