import { ApiProperty } from '@nestjs/swagger';

export class BalanceDto {
  @ApiProperty()
  id!: number;
  @ApiProperty()
  user_id!: number;
  @ApiProperty({ description: '1=REAL, 4=DEMO' })
  type!: number;
  @ApiProperty()
  amount!: number;
  @ApiProperty()
  enrolled_amount!: number;
  @ApiProperty()
  enrolled_sum_amount!: number;
  @ApiProperty()
  hold_amount!: number;
  @ApiProperty()
  orders_amount!: number;
  @ApiProperty()
  currency!: string;
  @ApiProperty()
  is_fiat!: boolean;
  @ApiProperty()
  is_marginal!: boolean;
  @ApiProperty()
  has_deposits!: boolean;
  @ApiProperty()
  auth_amount!: number;
  @ApiProperty()
  equivalent!: number;
}

export class GetBalanceResponseDto {
  @ApiProperty({ description: 'Whether the request was successful' })
  success!: boolean;

  @ApiProperty({ type: BalanceDto, isArray: true })
  balances!: BalanceDto[];
}


