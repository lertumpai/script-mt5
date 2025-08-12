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
    // Ensure session and profile
    const session = await IqOption.http.auth.session().catch(() => ({ success: false } as any));
    const profile = await IqOption.http.profile.get().catch(() => ({ success: false } as any));

    const side = dto.action === 'CALL' ? 'buy' : dto.action === 'PUT' ? 'sell' : dto.side;
    if (side !== 'buy' && side !== 'sell') {
      throw new BadRequestException('Provide either action=CALL|PUT or side=buy|sell');
    }

    // Resolve digital-option instrument id by subscribing instruments with user group
    let instrumentId: string | undefined = dto.instrument_id;
    const providedLooksLikeTicker = instrumentId && /^[A-Za-z]{6,}$/i.test(instrumentId) && !instrumentId.includes('-');
    const targetTicker = providedLooksLikeTicker ? instrumentId!.toUpperCase() : 'EURUSD';

    if (!instrumentId || providedLooksLikeTicker) {
      const user_group_id = Number((profile as any)?.data?.user_group_id ?? 0);
      const is_regulated = Boolean((profile as any)?.data?.is_regulated ?? false);
      instrumentId = await new Promise<string | undefined>((resolve) => {
        let done = false;
        const stopAt = Date.now() + 6000;
        const handle = (json: unknown) => {
          try {
            const name = (json as any)?.name as string | undefined;
            const msg = (json as any)?.msg ?? (json as any)?.result ?? json;
            const instruments = (msg as any)?.instruments as any[] | undefined;
            if (name?.toLowerCase().includes('instrument') && Array.isArray(instruments)) {
              const found = instruments.find((i) => String((i as any)?.ticker ?? '').toUpperCase() === targetTicker);
              if (found?.id) {
                done = true;
                resolve(String(found.id));
              }
            }
          } catch {}
          if (!done && Date.now() > stopAt) resolve(undefined);
        };
        IqOption.ws.onMessage = handle;
        IqOption.ws.onOpen = () => {
          IqOption.ws.auth.authenticate();
          setTimeout(
            () =>
              IqOption.ws.instrument.subscribe({
                type: 'digital-option' as any,
                ...(user_group_id ? { user_group_id } : {}),
                ...(is_regulated ? { is_regulated: true as any } : {}),
              }),
            50,
          );
        };
        if (!IqOption.ws.isConnected) IqOption.ws.connect();
        else
          IqOption.ws.instrument.subscribe({
            type: 'digital-option' as any,
            ...(user_group_id ? { user_group_id } : {}),
            ...(is_regulated ? { is_regulated: true as any } : {}),
          });
      });
    }

    if (!instrumentId) {
      throw new BadRequestException('Unable to resolve instrument_id for EURUSD under digital-option. Provide instrument_id explicitly.');
    }

    // Normalize balance id using profile if needed
    const balanceId = Number(dto.user_balance_id) || Number((profile as any)?.data?.balance_id);

    // Build and send order (digital-option)
    const wsPlace = {
      user_balance_id: balanceId,
      instrument_type: 'digital-option',
      instrument_id: instrumentId,
      side,
      amount: dto.amount,
    } as any;

    const rawMessages: string[] = [];
    return await new Promise<PlaceOrderResponseDto>((resolve) => {
      IqOption.ws.onMessage = (json) => {
        const s = JSON.stringify(json);
        rawMessages.push(s);
        const name = (json as any)?.name as string | undefined;
        const msg = (json as any)?.msg ?? (json as any)?.result ?? (json as any)?.message ?? json;
        const id = Number((msg as any)?.id ?? (msg as any)?.order_id ?? 0);
        if ((name?.toLowerCase().includes('order') || id) && id) {
          // Save order
          this.orderModel
            .create({
              userBalanceId: balanceId,
              instrumentType: 'digital-option',
              instrumentId: instrumentId,
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
              status: String((msg as any)?.status ?? 'created'),
              rawPlaceResponse: json,
            })
            .catch(() => undefined);

          resolve({ success: true, orderId: id, raw: json });
        }
        // capture explicit error for debugging
        if (name === 'order-placed-temp' && (json as any)?.status && (json as any)?.status !== 200) {
          resolve({ success: false, raw: rawMessages });
        }
      };

      IqOption.ws.onOpen = () => {
        IqOption.ws.auth.authenticate();
        setTimeout(() => IqOption.ws.order.place(wsPlace), 150);
      };
      if (!IqOption.ws.isConnected) IqOption.ws.connect();
      else IqOption.ws.order.place(wsPlace);

      setTimeout(() => resolve({ success: false, raw: rawMessages }), 5000);
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


