import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { ResultsService } from './results.service';
import { ResultGroupDto, UpsertResultDto } from './dto/result.dto';

@ApiTags('results')
@Controller('results')
export class ResultsController {
  constructor(private readonly resultsService: ResultsService) {}

  @Post('upsert')
  @ApiOperation({ summary: 'Upsert a daily result by date+account' })
  upsert(@Body() dto: UpsertResultDto) {
    return this.resultsService.upsert(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List results' })
  @ApiQuery({ name: 'account', required: false })
  @ApiQuery({ name: 'date', required: false, description: 'YYYY-MM-DD' })
  @ApiOperation({ summary: 'List results grouped by account and ordered by date desc' })
  list(@Query('account') account?: string, @Query('date') date?: string) {
    return this.resultsService.findAll(account, date);
  }
}


