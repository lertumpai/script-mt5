import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsIn, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class PlaceOrderDto {
  @ApiProperty({ example: 1220581410 })
  @IsNumber()
  user_balance_id!: number;

  @ApiProperty({ enum: ['crypto', 'forex', 'cfd', 'digital-option', 'fx-option'] })
  @IsString()
  instrument_type!: 'crypto' | 'forex' | 'cfd' | 'digital-option' | 'fx-option';

  @ApiProperty({ example: 'EURUSD' })
  @IsString()
  instrument_id!: string;

  @ApiPropertyOptional({ enum: ['buy', 'sell'] })
  @IsOptional()
  @IsIn(['buy', 'sell'])
  side?: 'buy' | 'sell';

  @ApiPropertyOptional({ enum: ['CALL', 'PUT'], description: 'Optional shortcut. CALL maps to buy, PUT maps to sell' })
  @IsOptional()
  @IsEnum(['CALL', 'PUT'])
  action?: 'CALL' | 'PUT';

  @ApiProperty({ example: '1' })
  @IsString()
  amount!: string;

  @ApiProperty({ example: 1, required: false })
  @IsOptional()
  @IsNumber()
  leverage?: number;

  @ApiProperty({ example: 0, required: false })
  @IsOptional()
  @IsNumber()
  limit_price?: number;

  @ApiProperty({ example: 0, required: false })
  @IsOptional()
  @IsNumber()
  stop_price?: number;

  @ApiProperty({ example: 0, required: false })
  @IsOptional()
  @IsNumber()
  @Min(0)
  stop_lose_value?: number;

  @ApiProperty({ example: 'percent', required: false })
  @IsOptional()
  @IsString()
  stop_lose_kind?: string;

  @ApiProperty({ example: 0, required: false })
  @IsOptional()
  @IsNumber()
  take_profit_value?: number;

  @ApiProperty({ example: 'percent', required: false })
  @IsOptional()
  @IsString()
  take_profit_kind?: string;
}

export class PlaceOrderResponseDto {
  @ApiProperty()
  success!: boolean;

  @ApiProperty({ required: false })
  orderId?: number;

  @ApiProperty({ required: false })
  raw?: unknown;
}


