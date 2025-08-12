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
exports.BalanceService = void 0;
const common_1 = require("@nestjs/common");
const iqoption_1 = __importDefault(require("@mvh/iqoption"));
let BalanceService = class BalanceService {
    static DEFAULT_TYPES = [1, 4];
    async getBalances(options) {
        const session = await iqoption_1.default.http.auth.session().catch(() => ({ success: false }));
        if (!session?.success) {
            return { success: false, balances: [] };
        }
        const types = Array.isArray(options?.types_ids) && options.types_ids.length ? options.types_ids : [1, 4];
        return await new Promise((resolve) => {
            const collected = [];
            iqoption_1.default.ws.onMessage = (json) => {
                try {
                    const msgString = JSON.stringify(json);
                    collected.push(msgString);
                    const name = json?.name;
                    const payload = json?.msg ?? json?.message ?? json;
                    const maybeBalancesArray = Array.isArray(payload) ? payload : payload?.balances;
                    const balancesFound = Array.isArray(maybeBalancesArray)
                        ? maybeBalancesArray
                        : Array.isArray(payload?.result?.balances)
                            ? payload?.result?.balances
                            : null;
                    if (balancesFound && balancesFound.length >= 0) {
                        const filtered = balancesFound.filter((b) => (types?.length ? types.includes(Number(b?.type)) : true));
                        const normalized = filtered.map((b) => ({
                            id: Number(b?.id ?? 0),
                            user_id: Number(b?.user_id ?? 0),
                            type: Number(b?.type ?? 0),
                            amount: Number(b?.amount ?? 0),
                            enrolled_amount: Number(b?.enrolled_amount ?? 0),
                            enrolled_sum_amount: Number(b?.enrolled_sum_amount ?? 0),
                            hold_amount: Number(b?.hold_amount ?? 0),
                            orders_amount: Number(b?.orders_amount ?? 0),
                            currency: String(b?.currency ?? ''),
                            is_fiat: Boolean(b?.is_fiat ?? false),
                            is_marginal: Boolean(b?.is_marginal ?? false),
                            has_deposits: Boolean(b?.has_deposits ?? false),
                            auth_amount: Number(b?.auth_amount ?? 0),
                            equivalent: Number(b?.equivalent ?? 0),
                        }));
                        resolve({ success: true, balances: normalized });
                        for (const raw of collected) {
                            try {
                                iqoption_1.default.ws.removeReceivedMessage(raw);
                            }
                            catch {
                            }
                        }
                    }
                }
                catch {
                }
            };
            iqoption_1.default.ws.onOpen = () => {
                iqoption_1.default.ws.auth.authenticate();
                setTimeout(() => iqoption_1.default.ws.balance.get({ types_ids: types }), 50);
            };
            if (!iqoption_1.default.ws.isConnected) {
                iqoption_1.default.ws.connect();
            }
            else {
                iqoption_1.default.ws.balance.get({ types_ids: types });
            }
            setTimeout(() => resolve({ success: false, balances: [] }), 4000);
        });
    }
};
exports.BalanceService = BalanceService;
exports.BalanceService = BalanceService = __decorate([
    (0, common_1.Injectable)()
], BalanceService);
//# sourceMappingURL=balance.service.js.map