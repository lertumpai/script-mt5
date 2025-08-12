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
Object.defineProperty(exports, "__esModule", { value: true });
exports.BalanceController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const balance_service_1 = require("./balance.service");
const balance_dto_1 = require("./dto/balance.dto");
let BalanceController = class BalanceController {
    balanceService;
    constructor(balanceService) {
        this.balanceService = balanceService;
    }
    async getBalances(types) {
        const parsed = (types ?? '1,4')
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean)
            .map((n) => Number(n))
            .filter((n) => !Number.isNaN(n));
        return this.balanceService.getBalances({ types_ids: parsed.length ? parsed : [1, 4] });
    }
};
exports.BalanceController = BalanceController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'Get balances for given types' }),
    (0, swagger_1.ApiQuery)({ name: 'types', required: false, example: '1,4', description: 'Comma-separated balance type ids: 1=REAL, 4=DEMO' }),
    (0, swagger_1.ApiResponse)({ status: 200, type: balance_dto_1.GetBalanceResponseDto }),
    __param(0, (0, common_1.Query)('types')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BalanceController.prototype, "getBalances", null);
exports.BalanceController = BalanceController = __decorate([
    (0, swagger_1.ApiTags)('balance'),
    (0, common_1.Controller)('balance'),
    __metadata("design:paramtypes", [balance_service_1.BalanceService])
], BalanceController);
//# sourceMappingURL=balance.controller.js.map