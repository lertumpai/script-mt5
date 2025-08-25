import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

export enum InstrumentType {
  DIGITAL_OPTION = 'digital-option',
  FX_OPTION = 'fx-option',
  FOREX = 'forex',
  CRYPTO = 'crypto',
  AUTO = 'auto'
}

export class GetInstrumentsDto {
  @ApiProperty({
    description: 'Type of instrument to retrieve',
    enum: InstrumentType,
    required: false,
    default: InstrumentType.AUTO
  })
  @IsOptional()
  @IsEnum(InstrumentType)
  type?: InstrumentType = InstrumentType.AUTO;

  @ApiProperty({
    description: 'Filter instruments by ticker (e.g., EURUSD, BTCUSD)',
    required: false,
    example: 'EURUSD'
  })
  @IsOptional()
  @IsString()
  ticker?: string;

  @ApiProperty({
    description: 'Filter instruments by active status',
    required: false,
    default: true
  })
  @IsOptional()
  active?: boolean = true;
}

export class InstrumentDto {
  @ApiProperty({ description: 'Unique identifier for the instrument' })
  id: number;

  @ApiProperty({ description: 'Instrument name/ticker' })
  name: string;

  @ApiProperty({ description: 'Instrument type' })
  type: string;

  @ApiProperty({ description: 'Whether the instrument is currently active' })
  active: boolean;

  @ApiProperty({ description: 'Instrument description' })
  description?: string;

  @ApiProperty({ description: 'Minimum order amount' })
  min_amount?: number;

  @ApiProperty({ description: 'Maximum order amount' })
  max_amount?: number;

  @ApiProperty({ description: 'Instrument precision' })
  precision?: number;

  @ApiProperty({ description: 'Additional metadata' })
  metadata?: Record<string, any>;
}
