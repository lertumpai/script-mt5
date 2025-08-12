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
Object.defineProperty(exports, "__esModule", { value: true });
exports.GetBalanceResponseDto = exports.BalanceDto = void 0;
const swagger_1 = require("@nestjs/swagger");
class BalanceDto {
    id;
    user_id;
    type;
    amount;
    enrolled_amount;
    enrolled_sum_amount;
    hold_amount;
    orders_amount;
    currency;
    is_fiat;
    is_marginal;
    has_deposits;
    auth_amount;
    equivalent;
}
exports.BalanceDto = BalanceDto;
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "user_id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '1=REAL, 4=DEMO' }),
    __metadata("design:type", Number)
], BalanceDto.prototype, "type", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "enrolled_amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "enrolled_sum_amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "hold_amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "orders_amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", String)
], BalanceDto.prototype, "currency", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Boolean)
], BalanceDto.prototype, "is_fiat", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Boolean)
], BalanceDto.prototype, "is_marginal", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Boolean)
], BalanceDto.prototype, "has_deposits", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "auth_amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Number)
], BalanceDto.prototype, "equivalent", void 0);
class GetBalanceResponseDto {
    success;
    balances;
}
exports.GetBalanceResponseDto = GetBalanceResponseDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Whether the request was successful' }),
    __metadata("design:type", Boolean)
], GetBalanceResponseDto.prototype, "success", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ type: BalanceDto, isArray: true }),
    __metadata("design:type", Array)
], GetBalanceResponseDto.prototype, "balances", void 0);
//# sourceMappingURL=balance.dto.js.map