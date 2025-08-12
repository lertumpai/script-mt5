import { HydratedDocument } from 'mongoose';
export type OrderDocument = HydratedDocument<Order>;
export declare class Order {
    userId: number;
    userBalanceId: number;
    instrumentType: string;
    instrumentId: string;
    side: 'buy' | 'sell';
    amount: string;
    leverage: number;
    limitPrice: number;
    stopPrice: number;
    stopLoseValue: number;
    stopLoseKind: string;
    takeProfitValue: number;
    takeProfitKind: string;
    brokerOrderId?: number;
    status: string;
    rawPlaceResponse?: unknown;
}
export declare const OrderSchema: import("mongoose").Schema<Order, import("mongoose").Model<Order, any, any, any, import("mongoose").Document<unknown, any, Order, any, {}> & Order & {
    _id: import("mongoose").Types.ObjectId;
} & {
    __v: number;
}, any>, {}, {}, {}, {}, import("mongoose").DefaultSchemaOptions, Order, import("mongoose").Document<unknown, {}, import("mongoose").FlatRecord<Order>, {}, import("mongoose").ResolveSchemaOptions<import("mongoose").DefaultSchemaOptions>> & import("mongoose").FlatRecord<Order> & {
    _id: import("mongoose").Types.ObjectId;
} & {
    __v: number;
}>;
