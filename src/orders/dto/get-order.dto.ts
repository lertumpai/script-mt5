import { ApiProperty } from '@nestjs/swagger';

export class OrderStatusResponseDto {
  @ApiProperty()
  success!: boolean;

  @ApiProperty({ required: false })
  raw?: unknown;
}


