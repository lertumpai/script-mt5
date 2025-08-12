import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { BalanceService } from './balance.service';
import { GetBalanceResponseDto } from './dto/balance.dto';

@ApiTags('balance')
@Controller('balance')
export class BalanceController {
  constructor(private readonly balanceService: BalanceService) {}

  @Get()
  @ApiOperation({ summary: 'Get balances for given types' })
  @ApiQuery({ name: 'types', required: false, example: '1,4', description: 'Comma-separated balance type ids: 1=REAL, 4=DEMO' })
  @ApiResponse({ status: 200, type: GetBalanceResponseDto })
  async getBalances(@Query('types') types?: string): Promise<GetBalanceResponseDto> {
    const parsed = (types ?? '1,4')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean)
      .map((n) => Number(n))
      .filter((n) => !Number.isNaN(n));
    return this.balanceService.getBalances({ types_ids: parsed.length ? parsed : [1, 4] });
  }
}


