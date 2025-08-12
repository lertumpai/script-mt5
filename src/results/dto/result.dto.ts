import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Matches, Min } from 'class-validator';

export class UpsertResultDto {
  @ApiProperty({ example: '2025-08-12', description: 'YYYY-MM-DD' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date!: string;

  @ApiProperty({ example: 'demo-1220581411' })
  @IsString()
  account!: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  win?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  loss?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  tie?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxConsecutiveWin?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  maxConsecutiveLoss?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  consecutiveWin?: number;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  consecutiveLoss?: number;
}

export class ResultResponseDto {
  @ApiProperty()
  id!: string;
  @ApiProperty()
  date!: string;
  @ApiProperty()
  account!: string;
  @ApiProperty()
  win!: number;
  @ApiProperty()
  loss!: number;
  @ApiProperty()
  tie!: number;
  @ApiProperty()
  maxConsecutiveWin!: number;
  @ApiProperty()
  maxConsecutiveLoss!: number;
  @ApiProperty()
  consecutiveWin!: number;
  @ApiProperty()
  consecutiveLoss!: number;
}


