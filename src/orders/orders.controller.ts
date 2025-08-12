import { Body, Controller, Get, HttpCode, HttpStatus, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiBody, ApiOkResponse, ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { PlaceOrderDto, PlaceOrderResponseDto } from './dto/place-order.dto';
import { OrderStatusResponseDto } from './dto/get-order.dto';

@ApiTags('orders')
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Place an order (CALL=buy, PUT=sell)' })
  @ApiBody({ type: PlaceOrderDto })
  @ApiOkResponse({ type: PlaceOrderResponseDto })
  place(@Body() body: PlaceOrderDto): Promise<PlaceOrderResponseDto> {
    return this.ordersService.place(body);
  }

  @Get(':id/status')
  @ApiOperation({ summary: 'Check order status by order id' })
  @ApiParam({ name: 'id', example: 123456789 })
  @ApiOkResponse({ type: OrderStatusResponseDto })
  status(@Param('id', ParseIntPipe) id: number): Promise<OrderStatusResponseDto> {
    return this.ordersService.status(id);
  }

  @Get()
  @ApiOperation({ summary: 'List all stored orders' })
  list() {
    return this.ordersService.findAll();
  }
}


