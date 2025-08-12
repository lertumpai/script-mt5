import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import IqOption from '@mvh/iqoption';
import { Order, OrderDocument } from './schemas/order.schema';
import { PlaceOrderDto, PlaceOrderResponseDto } from './dto/place-order.dto';
import { OrderStatusResponseDto } from './dto/get-order.dto';

@Injectable()
export class OrdersService {
  constructor(@InjectModel(Order.name) private readonly orderModel: Model<OrderDocument>) {}

  async place(dto: PlaceOrderDto): Promise<PlaceOrderResponseDto> {
    // Ensure ws session
    await IqOption.http.auth.session().catch(() => undefined);

    const side = dto.action === 'CALL' ? 'buy' : dto.action === 'PUT' ? 'sell' : dto.side;
    if (side !== 'buy' && side !== 'sell') {
      throw new BadRequestException('Provide either action=CALL|PUT or side=buy|sell');
    }

    const wsPlace = {
      user_balance_id: dto.user_balance_id,
      instrument_type: 'digital-option',
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
    } as any;

    const rawMessages: string[] = [];
    return await new Promise<PlaceOrderResponseDto>((resolve) => {
      IqOption.ws.onMessage = (json) => {
        const s = JSON.stringify(json);
        rawMessages.push(s);
        // Detect order placement response: look for message name containing 'order' and id
        const name = (json as any)?.name as string | undefined;
        const msg = (json as any)?.msg ?? (json as any)?.result ?? (json as any)?.message ?? json;
        const id = Number((msg as any)?.id ?? (msg as any)?.order_id ?? 0);
        if ((name?.toLowerCase().includes('order') || id) && id) {
          // Save order to DB
          this.orderModel
            .create({
              userId: Number((msg as any)?.user_id ?? 0),
              userBalanceId: dto.user_balance_id,
              instrumentType: 'digital-option',
              instrumentId: dto.instrument_id,
              side: (wsPlace as any).side,
              amount: dto.amount,
              leverage: dto.leverage ?? 1,
              limitPrice: dto.limit_price ?? 0,
              stopPrice: dto.stop_price ?? 0,
              stopLoseValue: dto.stop_lose_value ?? 0,
              stopLoseKind: dto.stop_lose_kind ?? 'percent',
              takeProfitValue: dto.take_profit_value ?? 0,
              takeProfitKind: dto.take_profit_kind ?? 'percent',
              brokerOrderId: id,
              status: String((msg as any)?.status ?? 'created'),
              rawPlaceResponse: json,
            })
            .catch(() => undefined);

          resolve({ success: true, orderId: id, raw: json });
        }
      };

      IqOption.ws.onOpen = () => {
        IqOption.ws.auth.authenticate();
        setTimeout(() => IqOption.ws.order.place(wsPlace), 50);
      };

      if (!IqOption.ws.isConnected) {
        IqOption.ws.connect();
      } else {
        IqOption.ws.order.place(wsPlace);
      }

      setTimeout(() => resolve({ success: false, raw: rawMessages }), 4000);
    });
  }

  async status(orderId: number): Promise<OrderStatusResponseDto> {
    // WS subscribe to order state/changed then fetch
    const rawMessages: string[] = [];
    return await new Promise<OrderStatusResponseDto>((resolve) => {
      IqOption.ws.onMessage = (json) => {
        rawMessages.push(JSON.stringify(json));
        const msg = (json as any)?.msg ?? (json as any)?.result ?? json;
        if (Number(msg?.id) === orderId || Number(msg?.order_id) === orderId) {
          resolve({ success: true, raw: json });
        }
      };

      IqOption.ws.onOpen = () => {
        IqOption.ws.auth.authenticate();
        setTimeout(() => IqOption.ws.order.subscribeState(), 50);
      };

      if (!IqOption.ws.isConnected) {
        IqOption.ws.connect();
      } else {
        IqOption.ws.order.subscribeState();
      }

      setTimeout(() => resolve({ success: false, raw: rawMessages }), 4000);
    });
  }

  findAll() {
    return this.orderModel.find().sort({ createdAt: -1 }).lean();
  }
}


