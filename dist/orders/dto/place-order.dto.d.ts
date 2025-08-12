export declare class PlaceOrderDto {
    user_balance_id: number;
    instrument_id: string;
    side?: 'buy' | 'sell';
    action?: 'CALL' | 'PUT';
    amount: string;
    leverage?: number;
    limit_price?: number;
    stop_price?: number;
    stop_lose_value?: number;
    stop_lose_kind?: string;
    take_profit_value?: number;
    take_profit_kind?: string;
}
export declare class PlaceOrderResponseDto {
    success: boolean;
    orderId?: number;
    raw?: unknown;
}
