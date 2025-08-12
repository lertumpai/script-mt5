import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { BalanceModule } from './balance/balance.module';

@Module({
  imports: [AuthModule, BalanceModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
