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
exports.PlaceOrderResponseDto = exports.PlaceOrderDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
class PlaceOrderDto {
    user_balance_id;
    instrument_type;
    instrument_id;
    side;
    action;
    amount;
    leverage;
    limit_price;
    stop_price;
    stop_lose_value;
    stop_lose_kind;
    take_profit_value;
    take_profit_kind;
}
exports.PlaceOrderDto = PlaceOrderDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 1220581410 }),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], PlaceOrderDto.prototype, "user_balance_id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ enum: ['crypto', 'forex', 'cfd', 'digital-option', 'fx-option'] }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], PlaceOrderDto.prototype, "instrument_type", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'EURUSD' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], PlaceOrderDto.prototype, "instrument_id", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ enum: ['buy', 'sell'] }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsIn)(['buy', 'sell']),
    __metadata("design:type", String)
], PlaceOrderDto.prototype, "side", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ enum: ['CALL', 'PUT'], description: 'Optional shortcut. CALL maps to buy, PUT maps to sell' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(['CALL', 'PUT']),
    __metadata("design:type", String)
], PlaceOrderDto.prototype, "action", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '1' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], PlaceOrderDto.prototype, "amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 1, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], PlaceOrderDto.prototype, "leverage", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 0, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], PlaceOrderDto.prototype, "limit_price", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 0, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], PlaceOrderDto.prototype, "stop_price", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 0, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], PlaceOrderDto.prototype, "stop_lose_value", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'percent', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], PlaceOrderDto.prototype, "stop_lose_kind", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 0, required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], PlaceOrderDto.prototype, "take_profit_value", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'percent', required: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], PlaceOrderDto.prototype, "take_profit_kind", void 0);
class PlaceOrderResponseDto {
    success;
    orderId;
    raw;
}
exports.PlaceOrderResponseDto = PlaceOrderResponseDto;
__decorate([
    (0, swagger_1.ApiProperty)(),
    __metadata("design:type", Boolean)
], PlaceOrderResponseDto.prototype, "success", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false }),
    __metadata("design:type", Number)
], PlaceOrderResponseDto.prototype, "orderId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false }),
    __metadata("design:type", Object)
], PlaceOrderResponseDto.prototype, "raw", void 0);
//# sourceMappingURL=place-order.dto.js.map