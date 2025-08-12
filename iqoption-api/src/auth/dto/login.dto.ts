import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'user@example.com' })
  @IsString()
  @IsNotEmpty()
  identifier!: string;

  @ApiProperty({ example: 'strong_password' })
  @IsString()
  @IsNotEmpty()
  password!: string;

  @ApiPropertyOptional({ description: 'Two-factor authentication code if enabled', example: '123456' })
  @IsString()
  @IsOptional()
  twoFactorCode?: string;
}

export class LoginResponseDto {
  @ApiProperty({ description: 'Whether the login call succeeded' })
  success!: boolean;

  @ApiProperty({ description: 'WebSocket token to be used for subsequent WS auth', nullable: true })
  token!: string | null;

  @ApiProperty({ description: 'Raw response from IQ Option http.auth.login', nullable: true })
  raw!: unknown;
}


