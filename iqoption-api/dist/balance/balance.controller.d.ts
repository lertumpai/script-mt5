import { BalanceService } from './balance.service';
import { GetBalanceResponseDto } from './dto/balance.dto';
export declare class BalanceController {
    private readonly balanceService;
    constructor(balanceService: BalanceService);
    getBalances(types?: string): Promise<GetBalanceResponseDto>;
}
