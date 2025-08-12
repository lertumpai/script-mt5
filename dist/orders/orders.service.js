"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersService = void 0;
const common_1 = require("@nestjs/common");
const mongoose_1 = require("@nestjs/mongoose");
const mongoose_2 = require("mongoose");
const iqoption_1 = __importDefault(require("@mvh/iqoption"));
const order_schema_1 = require("./schemas/order.schema");
let OrdersService = class OrdersService {
    orderModel;
    constructor(orderModel) {
        this.orderModel = orderModel;
    }
    async place(dto) {
        await iqoption_1.default.http.auth.session().catch(() => undefined);
        const side = dto.action === 'CALL' ? 'buy' : dto.action === 'PUT' ? 'sell' : dto.side;
        if (side !== 'buy' && side !== 'sell') {
            throw new common_1.BadRequestException('Provide either action=CALL|PUT or side=buy|sell');
        }
        const wsPlace = {
            user_balance_id: dto.user_balance_id,
            instrument_type: dto.instrument_type,
            instrument_id: dto.instrument_id,
            side,
            amount: dto.amount,
            leverage: dto.leverage ?? 1,
            limit_price: dto.limit_price ?? 0,
            stop_price: dto.stop_price ?? 0,
            stop_lose_value: dto.stop_lose_value ?? 0,
            stop_lose_kind: dto.stop_lose_kind ?? 'percent',
            take_profit_value: dto.take_profit_value ?? 0,
            take_profit_kind: dto.take_profit_kind ?? 'percent',
        };
        const rawMessages = [];
        return await new Promise((resolve) => {
            iqoption_1.default.ws.onMessage = (json) => {
                const s = JSON.stringify(json);
                rawMessages.push(s);
                const name = json?.name;
                const msg = json?.msg ?? json?.result ?? json?.message ?? json;
                const id = Number(msg?.id ?? msg?.order_id ?? 0);
                if ((name?.toLowerCase().includes('order') || id) && id) {
                    this.orderModel
                        .create({
                        userId: Number(msg?.user_id ?? 0),
                        userBalanceId: dto.user_balance_id,
                        instrumentType: dto.instrument_type,
                        instrumentId: dto.instrument_id,
                        side: wsPlace.side,
                        amount: dto.amount,
                        leverage: dto.leverage ?? 1,
                        limitPrice: dto.limit_price ?? 0,
                        stopPrice: dto.stop_price ?? 0,
                        stopLoseValue: dto.stop_lose_value ?? 0,
                        stopLoseKind: dto.stop_lose_kind ?? 'percent',
                        takeProfitValue: dto.take_profit_value ?? 0,
                        takeProfitKind: dto.take_profit_kind ?? 'percent',
                        brokerOrderId: id,
                        status: String(msg?.status ?? 'created'),
                        rawPlaceResponse: json,
                    })
                        .catch(() => undefined);
                    resolve({ success: true, orderId: id, raw: json });
                }
            };
            iqoption_1.default.ws.onOpen = () => {
                iqoption_1.default.ws.auth.authenticate();
                setTimeout(() => iqoption_1.default.ws.order.place(wsPlace), 50);
            };
            if (!iqoption_1.default.ws.isConnected) {
                iqoption_1.default.ws.connect();
            }
            else {
                iqoption_1.default.ws.order.place(wsPlace);
            }
            setTimeout(() => resolve({ success: false, raw: rawMessages }), 4000);
        });
    }
    async status(orderId) {
        const rawMessages = [];
        return await new Promise((resolve) => {
            iqoption_1.default.ws.onMessage = (json) => {
                rawMessages.push(JSON.stringify(json));
                const msg = json?.msg ?? json?.result ?? json;
                if (Number(msg?.id) === orderId || Number(msg?.order_id) === orderId) {
                    resolve({ success: true, raw: json });
                }
            };
            iqoption_1.default.ws.onOpen = () => {
                iqoption_1.default.ws.auth.authenticate();
                setTimeout(() => iqoption_1.default.ws.order.subscribeState(), 50);
            };
            if (!iqoption_1.default.ws.isConnected) {
                iqoption_1.default.ws.connect();
            }
            else {
                iqoption_1.default.ws.order.subscribeState();
            }
            setTimeout(() => resolve({ success: false, raw: rawMessages }), 4000);
        });
    }
    findAll() {
        return this.orderModel.find().sort({ createdAt: -1 }).lean();
    }
};
exports.OrdersService = OrdersService;
exports.OrdersService = OrdersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, mongoose_1.InjectModel)(order_schema_1.Order.name)),
    __metadata("design:paramtypes", [mongoose_2.Model])
], OrdersService);
//# sourceMappingURL=orders.service.js.map