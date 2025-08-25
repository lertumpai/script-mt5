# Instruments API

This module provides comprehensive functionality for managing and retrieving financial instruments from IQ Option.

## Features

- Get all instruments with filtering options
- Resolve instrument IDs by ticker symbols
- Get instrument details by ID
- Support for multiple instrument types (digital options, FX options, forex, crypto)
- Automatic connection management to IQ Option WebSocket API

## API Endpoints

### 1. Get All Instruments
```
GET /instruments
```

**Query Parameters:**
- `type` (optional): Instrument type filter
  - `digital-option`: Digital options only
  - `fx-option`: FX options only
  - `forex`: Forex instruments only
  - `crypto`: Cryptocurrency instruments only
  - `auto`: All types (default)
- `ticker` (optional): Filter by ticker symbol (e.g., "EURUSD")
- `active` (optional): Filter by active status (default: true)

**Example:**
```bash
GET /instruments?type=forex&ticker=EUR&active=true
```

### 2. Get Available Instrument Types
```
GET /instruments/types
```

Returns a list of supported instrument types.

### 3. Resolve Instrument ID
```
GET /instruments/resolve
```

**Query Parameters:**
- `type` (required): Instrument type to search in
  - `digital-option`: Search in digital options
  - `fx-option`: Search in FX options
  - `auto`: Search in all types (recommended)
- `ticker` (required): Ticker symbol to resolve (e.g., "EURUSD")

**Example:**
```bash
GET /instruments/resolve?type=auto&ticker=EURUSD
```

### 4. Get Instrument by ID
```
GET /instruments/:id
```

**Path Parameters:**
- `id`: Numeric instrument ID

**Example:**
```bash
GET /instruments/12345
```

## Response Models

### InstrumentDto
```typescript
{
  id: number;
  name: string;
  type: string;
  active: boolean;
  description?: string;
  min_amount?: number;
  max_amount?: number;
  precision?: number;
  metadata?: Record<string, any>;
}
```

### ResolvedInstrumentDto
```typescript
{
  id: number;
  ticker: string;
  type: string;
  active: boolean;
  details?: Record<string, any>;
}
```

## Usage Examples

### JavaScript/TypeScript
```typescript
// Get all forex instruments
const forexInstruments = await fetch('/instruments?type=forex');

// Resolve EURUSD instrument ID
const eurusd = await fetch('/instruments/resolve?type=auto&ticker=EURUSD');

// Get instrument by ID
const instrument = await fetch('/instruments/12345');
```

### cURL
```bash
# Get all instruments
curl "http://localhost:3000/instruments"

# Get forex instruments only
curl "http://localhost:3000/instruments?type=forex"

# Resolve EURUSD
curl "http://localhost:3000/instruments/resolve?type=auto&ticker=EURUSD"

# Get instrument by ID
curl "http://localhost:3000/instruments/12345"
```

## Error Handling

The API returns appropriate HTTP status codes:
- `200`: Success
- `404`: Instrument not found
- `500`: Internal server error

## Notes

- The service automatically manages the connection to IQ Option WebSocket API
- Instrument types 'stocks' and 'commodities' are not currently supported by the IQ Option API
- All API calls are asynchronous and return promises
- The service includes comprehensive logging for debugging purposes
