import { Controller, Get, Query, Param, ParseIntPipe } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiTags, ApiParam, ApiResponse } from '@nestjs/swagger';
import { InstrumentsService } from './instruments.service';
import { GetInstrumentsDto, InstrumentDto, ResolveInstrumentDto, ResolvedInstrumentDto } from './dto';

@ApiTags('instruments')
@Controller('instruments')
export class InstrumentsController {
  constructor(private readonly instrumentsService: InstrumentsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all instruments with optional filtering' })
  @ApiQuery({ name: 'type', enum: ['digital-option', 'fx-option', 'forex', 'crypto', 'auto'], required: false })
  @ApiQuery({ name: 'ticker', example: 'EURUSD', required: false })
  @ApiQuery({ name: 'active', example: true, required: false })
  @ApiResponse({ status: 200, description: 'List of instruments', type: [InstrumentDto] })
  async getInstruments(@Query() query: GetInstrumentsDto): Promise<InstrumentDto[]> {
    return this.instrumentsService.getInstruments(query);
  }

  @Get('types')
  @ApiOperation({ summary: 'Get available instrument types' })
  @ApiResponse({ status: 200, description: 'List of available instrument types', type: [String] })
  async getAvailableTypes(): Promise<string[]> {
    return this.instrumentsService.getAvailableTypes();
  }

  @Get('resolve')
  @ApiOperation({ summary: 'Resolve instrument_id by ticker for a given type (use type=auto to try both)' })
  @ApiQuery({ name: 'type', enum: ['digital-option', 'fx-option', 'auto'], required: false })
  @ApiQuery({ name: 'ticker', example: 'EURUSD', required: true })
  @ApiResponse({ status: 200, description: 'Resolved instrument information', type: ResolvedInstrumentDto })
  @ApiResponse({ status: 404, description: 'Instrument not found' })
  async resolve(@Query() query: ResolveInstrumentDto): Promise<ResolvedInstrumentDto> {
    return this.instrumentsService.resolveInstrumentId(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get instrument by ID' })
  @ApiParam({ name: 'id', description: 'Instrument ID', type: Number })
  @ApiResponse({ status: 200, description: 'Instrument information', type: InstrumentDto })
  @ApiResponse({ status: 404, description: 'Instrument not found' })
  async getInstrumentById(@Param('id', ParseIntPipe) id: number): Promise<InstrumentDto> {
    return this.instrumentsService.getInstrumentById(id);
  }
}


