import { Injectable } from '@nestjs/common';
import IqOption from '@mvh/iqoption';

@Injectable()
export class InstrumentsService {
  async resolveInstrumentId(type: 'digital-option' | 'fx-option' | 'auto', ticker: string) {
    IqOption.ws.onOpen = () => IqOption.ws.auth.authenticate();
    await IqOption.ws.connect();

    // Pull instrument list and find EURUSD active_id
    const instr = await IqOption.ws.instrument.get({ type: "digital-option" });
    console.log(instr);

    return "success"
  }
}


