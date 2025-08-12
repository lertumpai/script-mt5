export declare class BalanceDto {
    id: number;
    user_id: number;
    type: number;
    amount: number;
    enrolled_amount: number;
    enrolled_sum_amount: number;
    hold_amount: number;
    orders_amount: number;
    currency: string;
    is_fiat: boolean;
    is_marginal: boolean;
    has_deposits: boolean;
    auth_amount: number;
    equivalent: number;
}
export declare class GetBalanceResponseDto {
    success: boolean;
    balances: BalanceDto[];
}
