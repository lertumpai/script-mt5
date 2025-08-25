import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsString } from 'class-validator';

export class ResolveInstrumentDto {
  @ApiProperty({
    description: 'Type of instrument to resolve',
    enum: ['digital-option', 'fx-option', 'auto'],
    example: 'auto'
  })
  @IsEnum(['digital-option', 'fx-option', 'auto'])
  type: 'digital-option' | 'fx-option' | 'auto';

  @ApiProperty({
    description: 'Ticker symbol to resolve (e.g., EURUSD, BTCUSD)',
    example: 'EURUSD'
  })
  @IsString()
  ticker: string;
}

export class ResolvedInstrumentDto {
  @ApiProperty({ description: 'Resolved instrument ID' })
  id: number;

  @ApiProperty({ description: 'Instrument ticker' })
  ticker: string;

  @ApiProperty({ description: 'Instrument type' })
  type: string;

  @ApiProperty({ description: 'Whether the instrument is active' })
  active: boolean;

  @ApiProperty({ description: 'Additional instrument details' })
  details?: Record<string, any>;
}
