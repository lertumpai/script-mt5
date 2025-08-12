import { Injectable } from '@nestjs/common';
import IqOption, { type dataResponse } from '@mvh/iqoption';
import { BalanceDto, GetBalanceResponseDto } from './dto/balance.dto';

type GetOptions = { types_ids: number[] };

@Injectable()
export class BalanceService {
  // Minimal local type for requesting balances
  private static readonly DEFAULT_TYPES = [1, 4];

  async getBalances(options: GetOptions): Promise<GetBalanceResponseDto> {
    // Ensure there is an active session/cookie after login
    const session = await IqOption.http.auth.session().catch(() => ({ success: false } as dataResponse));
    if (!session?.success) {
      return { success: false, balances: [] };
    }

    // Prepare WS and query balances
    const types = Array.isArray(options?.types_ids) && options.types_ids.length ? options.types_ids : [1, 4];

    return await new Promise<GetBalanceResponseDto>((resolve) => {
      const collected: string[] = [];

      IqOption.ws.onMessage = (json) => {
        try {
          const msgString = JSON.stringify(json);
          collected.push(msgString);

          // Try to detect balances in typical shapes
          const name = (json as any)?.name as string | undefined;
          const payload = (json as any)?.msg ?? (json as any)?.message ?? json;

          const maybeBalancesArray = Array.isArray(payload) ? payload : (payload?.balances as unknown);
          const balancesFound: any[] | null = Array.isArray(maybeBalancesArray)
            ? maybeBalancesArray
            : Array.isArray((payload?.result as any)?.balances)
            ? ((payload?.result as any)?.balances as any[])
            : null;

          if (balancesFound && balancesFound.length >= 0) {
            const filtered = balancesFound.filter((b) => (types?.length ? types.includes(Number((b as any)?.type)) : true));
            const normalized: BalanceDto[] = filtered.map((b) => ({
              id: Number((b as any)?.id ?? 0),
              user_id: Number((b as any)?.user_id ?? 0),
              type: Number((b as any)?.type ?? 0),
              amount: Number((b as any)?.amount ?? 0),
              enrolled_amount: Number((b as any)?.enrolled_amount ?? 0),
              enrolled_sum_amount: Number((b as any)?.enrolled_sum_amount ?? 0),
              hold_amount: Number((b as any)?.hold_amount ?? 0),
              orders_amount: Number((b as any)?.orders_amount ?? 0),
              currency: String((b as any)?.currency ?? ''),
              is_fiat: Boolean((b as any)?.is_fiat ?? false),
              is_marginal: Boolean((b as any)?.is_marginal ?? false),
              has_deposits: Boolean((b as any)?.has_deposits ?? false),
              auth_amount: Number((b as any)?.auth_amount ?? 0),
              equivalent: Number((b as any)?.equivalent ?? 0),
            }));

            resolve({ success: true, balances: normalized });

            // Clean up collected messages
            for (const raw of collected) {
              try {
                IqOption.ws.removeReceivedMessage(raw);
              } catch {
                // ignore
              }
            }
          }
        } catch {
          // ignore parse errors
        }
      };

      IqOption.ws.onOpen = () => {
        IqOption.ws.auth.authenticate();
        // Request balances after authentication
        setTimeout(() => IqOption.ws.balance.get({ types_ids: types }), 50);
      };

      if (!IqOption.ws.isConnected) {
        IqOption.ws.connect();
      } else {
        // If already connected, directly query
        IqOption.ws.balance.get({ types_ids: types });
      }

      // Timeout fallback
      setTimeout(() => resolve({ success: false, balances: [] }), 4000);
    });
  }
}


