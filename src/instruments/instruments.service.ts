import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import IqOption from '@mvh/iqoption';
import { GetInstrumentsDto, InstrumentDto, InstrumentType, ResolveInstrumentDto, ResolvedInstrumentDto } from './dto';

@Injectable()
export class InstrumentsService {
  private readonly logger = new Logger(InstrumentsService.name);
  private isConnected = false;

  constructor() {
    this.initializeConnection();
  }

  private async initializeConnection() {
    try {
      if (!this.isConnected) {
        // Set up event handlers before connecting
        IqOption.ws.onOpen = () => {
          this.logger.log('WebSocket connection opened');
          // Don't authenticate immediately - wait for connection to be ready
        };

        IqOption.ws.onClose = () => {
          this.logger.log('WebSocket connection closed');
          this.isConnected = false;
        };

        // Connect to WebSocket
        await IqOption.ws.connect();
        
        // Wait a bit for connection to stabilize
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        this.isConnected = true;
        this.logger.log('Successfully connected to IQ Option WebSocket');
      }
    } catch (error) {
      this.logger.error('Failed to connect to IQ Option', error);
      // Don't throw error, just log it
      this.isConnected = false;
    }
  }

  private async ensureConnection() {
    this.logger.log('ensureConnection called, isConnected:', this.isConnected);
    if (!this.isConnected) {
      this.logger.log('Initializing connection...');
      await this.initializeConnection();
      this.logger.log('Connection initialization complete, isConnected:', this.isConnected);
    }
  }

  async getInstruments(query: GetInstrumentsDto): Promise<InstrumentDto[]> {
    try {
      this.logger.log('getInstruments called with query:', query);
      await this.ensureConnection();

      // For now, always return mock data to test the endpoint
      this.logger.warn('Using mock data for development');
      const mockData = this.getMockInstruments(query);
      this.logger.log('Returning mock data:', mockData);
      return mockData;

    } catch (error) {
      this.logger.error('Failed to get instruments', error);
      throw error;
    }
  }

  async resolveInstrumentId(query: ResolveInstrumentDto): Promise<ResolvedInstrumentDto> {
    try {
      await this.ensureConnection();

      // For now, use mock data for development
      this.logger.warn('Using mock data for resolve endpoint');
      return this.resolveMockInstrument(query);

    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error('Failed to resolve instrument ID', error);
      throw error;
    }
  }

  async getInstrumentById(id: number): Promise<InstrumentDto> {
    try {
      await this.ensureConnection();

      // For now, use mock data for development
      this.logger.warn('Using mock data for getInstrumentById endpoint');
      return this.getMockInstrumentById(id);

    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error('Failed to get instrument by ID', error);
      throw error;
    }
  }

  private findInstrumentByTicker(instruments: any[], ticker: string): any {
    return instruments.find(instr => 
      instr.name?.toLowerCase() === ticker.toLowerCase() ||
      instr.ticker?.toLowerCase() === ticker.toLowerCase() ||
      instr.symbol?.toLowerCase() === ticker.toLowerCase()
    );
  }

  private mapInstruments(rawInstruments: any[], type: string): InstrumentDto[] {
    return rawInstruments.map(instr => ({
      id: instr.id || instr.active_id,
      name: instr.name || instr.ticker || instr.symbol || 'Unknown',
      type,
      active: instr.active !== false,
      description: instr.description || instr.name,
      min_amount: instr.min_amount,
      max_amount: instr.max_amount,
      precision: instr.precision,
      metadata: {
        ...instr,
        original_type: type
      }
    }));
  }

  private mapResolvedInstrument(instrument: any, type: string): ResolvedInstrumentDto {
    return {
      id: instrument.id || instrument.active_id,
      ticker: instrument.name || instrument.ticker || instrument.symbol,
      type,
      active: instrument.active !== false,
      details: {
        ...instrument,
        original_type: type
      }
    };
  }

  async getAvailableTypes(): Promise<string[]> {
    return [
      'digital-option',
      'fx-option', 
      'forex',
      'crypto'
    ];
  }

  private getMockInstruments(query: GetInstrumentsDto): InstrumentDto[] {
    const mockInstruments: InstrumentDto[] = [
      {
        id: 1,
        name: 'EURUSD',
        type: 'forex',
        active: true,
        description: 'Euro / US Dollar',
        min_amount: 1,
        max_amount: 10000,
        precision: 5,
        metadata: { mock: true }
      },
      {
        id: 2,
        name: 'GBPUSD',
        type: 'forex',
        active: true,
        description: 'British Pound / US Dollar',
        min_amount: 1,
        max_amount: 10000,
        precision: 5,
        metadata: { mock: true }
      },
      {
        id: 3,
        name: 'BTCUSD',
        type: 'crypto',
        active: true,
        description: 'Bitcoin / US Dollar',
        min_amount: 1,
        max_amount: 5000,
        precision: 2,
        metadata: { mock: true }
      }
    ];

    // Apply filters
    let filtered = mockInstruments;
    
    if (query.type && query.type !== InstrumentType.AUTO) {
      filtered = filtered.filter(instr => instr.type === query.type);
    }
    
    if (query.ticker) {
      filtered = filtered.filter(instr => 
        instr.name.toLowerCase().includes(query.ticker!.toLowerCase())
      );
    }
    
    if (query.active !== undefined) {
      filtered = filtered.filter(instr => instr.active === query.active);
    }

    return filtered;
  }

  private resolveMockInstrument(query: ResolveInstrumentDto): ResolvedInstrumentDto {
    const { type, ticker } = query;
    
    // Mock instrument data
    const mockInstruments = [
      { id: 1, ticker: 'EURUSD', type: 'forex', active: true },
      { id: 2, ticker: 'GBPUSD', type: 'forex', active: true },
      { id: 3, ticker: 'BTCUSD', type: 'crypto', active: true }
    ];

    // Find instrument by ticker
    const instrument = mockInstruments.find(instr => 
      instr.ticker.toLowerCase() === ticker.toLowerCase()
    );

    if (!instrument) {
      throw new NotFoundException(`Instrument with ticker ${ticker} not found`);
    }

    return {
      id: instrument.id,
      ticker: instrument.ticker,
      type: instrument.type,
      active: instrument.active,
      details: { mock: true, original_type: type }
    };
  }

  private getMockInstrumentById(id: number): InstrumentDto {
    // Mock instrument data
    const mockInstruments = [
      {
        id: 1,
        name: 'EURUSD',
        type: 'forex',
        active: true,
        description: 'Euro / US Dollar',
        min_amount: 1,
        max_amount: 10000,
        precision: 5,
        metadata: { mock: true }
      },
      {
        id: 2,
        name: 'GBPUSD',
        type: 'forex',
        active: true,
        description: 'British Pound / US Dollar',
        min_amount: 1,
        max_amount: 10000,
        precision: 5,
        metadata: { mock: true }
      },
      {
        id: 3,
        name: 'BTCUSD',
        type: 'crypto',
        active: true,
        description: 'Bitcoin / US Dollar',
        min_amount: 1,
        max_amount: 5000,
        precision: 2,
        metadata: { mock: true }
      }
    ];

    const instrument = mockInstruments.find(instr => instr.id === id);
    
    if (!instrument) {
      throw new NotFoundException(`Instrument with ID ${id} not found`);
    }

    return instrument;
  }
}


