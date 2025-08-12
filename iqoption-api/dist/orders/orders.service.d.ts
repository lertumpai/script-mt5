import { Model } from 'mongoose';
import { Order, OrderDocument } from './schemas/order.schema';
import { PlaceOrderDto, PlaceOrderResponseDto } from './dto/place-order.dto';
import { OrderStatusResponseDto } from './dto/get-order.dto';
export declare class OrdersService {
    private readonly orderModel;
    constructor(orderModel: Model<OrderDocument>);
    place(dto: PlaceOrderDto): Promise<PlaceOrderResponseDto>;
    status(orderId: number): Promise<OrderStatusResponseDto>;
    findAll(): import("mongoose").Query<(import("mongoose").FlattenMaps<import("mongoose").Document<unknown, {}, Order, {}, {}> & Order & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    }> & Required<{
        _id: import("mongoose").Types.ObjectId;
    }>)[], import("mongoose").Document<unknown, {}, import("mongoose").Document<unknown, {}, Order, {}, {}> & Order & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    }, {}, {}> & import("mongoose").Document<unknown, {}, Order, {}, {}> & Order & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    } & Required<{
        _id: import("mongoose").Types.ObjectId;
    }>, {}, import("mongoose").Document<unknown, {}, Order, {}, {}> & Order & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    }, "find", {}>;
}
