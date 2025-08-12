import { GetBalanceResponseDto } from './dto/balance.dto';
type GetOptions = {
    types_ids: number[];
};
export declare class BalanceService {
    private static readonly DEFAULT_TYPES;
    getBalances(options: GetOptions): Promise<GetBalanceResponseDto>;
}
export {};
