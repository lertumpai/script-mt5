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
    // Ensure ws session and get profile for defaults
    const session = await IqOption.http.auth.session().catch(() => ({ success: false } as any));
    const profile = await IqOption.http.profile.get().catch(() => ({ success: false } as any));

    const side = dto.action === 'CALL' ? 'buy' : dto.action === 'PUT' ? 'sell' : dto.side;
    if (side !== 'buy' && side !== 'sell') {
      throw new BadRequestException('Provide either action=CALL|PUT or side=buy|sell');
    }

    // Determine balance id: if invalid or equals user_id, fallback to current profile balance_id
    const postedBalanceId = Number(dto.user_balance_id);
    const userId = Number((profile as any)?.data?.user_id ?? 0);
    const currentBalanceId = Number((profile as any)?.data?.balance_id ?? postedBalanceId);
    const user_balance_id = postedBalanceId && postedBalanceId !== userId ? postedBalanceId : currentBalanceId;

    // If instrument_id looks like a plain ticker (e.g., EURUSD), try to resolve for digital-option
    let instrument_id = dto.instrument_id;
    const looksLikeTicker = instrument_id && /^[A-Z]{6,}$/i.test(instrument_id) && !instrument_id.includes('-');
    if (!instrument_id || looksLikeTicker) {
      try {
        const resolved = await new Promise<string | null>((resolve) => {
          let done = false;
          const handle = (json: unknown) => {
            try {
              const msg = (json as any)?.msg ?? (json as any)?.result ?? json;
              const instruments = (msg as any)?.instruments as any[] | undefined;
              if (Array.isArray(instruments)) {
                const found = instruments.find((i) => String((i as any)?.ticker).toUpperCase() === (instrument_id || '').toUpperCase());
                if (found?.id) {
                  done = true;
                  resolve(String(found.id));
                }
              }
            } catch {}
          };
          IqOption.ws.onMessage = handle;
          IqOption.ws.onOpen = () => {
            IqOption.ws.auth.authenticate();
            setTimeout(() => IqOption.ws.instrument.get({ type: 'digital-option' as any }), 50);
          };
          if (!IqOption.ws.isConnected) IqOption.ws.connect();
          else IqOption.ws.instrument.get({ type: 'digital-option' as any });
          setTimeout(() => !done && resolve(null), 2000);
        });
        if (resolved) instrument_id = resolved;
      } catch {}
    }

    const wsPlace = {
      user_balance_id,
      instrument_type: 'digital-option',
      instrument_id,
      side,
      amount: dto.amount,
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
              instrumentType: 'binary-option',
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


