import { Injectable } from '@nestjs/common';
import IqOption from '@mvh/iqoption';

@Injectable()
export class InstrumentsService {
  async resolveInstrumentId(type: 'digital-option' | 'fx-option' | 'auto', ticker: string) {
    await IqOption.http.auth.session().catch(() => undefined);

    const messages: any[] = [];
    const tryOnce = (t: 'digital-option' | 'fx-option') =>
      new Promise<string | null>((resolve) => {
        let done = false;
        const stopAt = Date.now() + 6000;
        const handle = (json: unknown) => {
          try {
            messages.push(json);
            const name = (json as any)?.name as string | undefined;
            const msg = (json as any)?.msg ?? (json as any)?.result ?? json;
            const instruments = (msg as any)?.instruments as any[] | undefined;
            if (name?.toLowerCase().includes('instrument') && Array.isArray(instruments)) {
              const found = instruments.find((i) => String((i as any)?.ticker).toUpperCase() === ticker.toUpperCase());
              if (found?.id) {
                done = true;
                resolve(String(found.id));
              }
            }
          } catch {}
          if (!done && Date.now() > stopAt) resolve(null);
        };
        IqOption.ws.onMessage = handle;
        IqOption.ws.onOpen = () => {
          IqOption.ws.auth.authenticate();
          setTimeout(() => IqOption.ws.instrument.get({ type: t as any }), 50);
        };
        if (!IqOption.ws.isConnected) IqOption.ws.connect();
        else IqOption.ws.instrument.get({ type: t as any });
      });

    const resolved =
      type === 'auto' ? (await tryOnce('digital-option')) ?? (await tryOnce('fx-option')) : await tryOnce(type);

    return { success: Boolean(resolved), instrument_id: resolved, raw: messages };
  }
}


