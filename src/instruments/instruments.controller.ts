import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { InstrumentsService } from './instruments.service';

@ApiTags('instruments')
@Controller('instruments')
export class InstrumentsController {
  constructor(private readonly instrumentsService: InstrumentsService) {}

  @Get('resolve')
  @ApiOperation({ summary: 'Resolve instrument_id by ticker for a given type (use type=auto to try both)' })
  @ApiQuery({ name: 'type', enum: ['digital-option', 'fx-option', 'auto'], required: false })
  @ApiQuery({ name: 'ticker', example: 'EURUSD', required: true })
  resolve(@Query('type') type: 'digital-option' | 'fx-option' | 'auto' = 'auto', @Query('ticker') ticker: string) {
    return this.instrumentsService.resolveInstrumentId(type, ticker);
  }
}


