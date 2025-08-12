import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type OrderDocument = HydratedDocument<Order>;

@Schema({ timestamps: true })
export class Order {
  @Prop({ required: true })
  userBalanceId!: number;

  @Prop({ required: true, default: 'digital-option', enum: ['digital-option'] })
  instrumentType!: 'digital-option';

  @Prop({ required: true })
  instrumentId!: string;

  @Prop({ required: true, enum: ['buy', 'sell'] })
  side!: 'buy' | 'sell';

  @Prop({ required: true })
  amount!: string;

  @Prop({ default: 1 })
  leverage!: number;

  @Prop({ default: 0 })
  limitPrice!: number;

  @Prop({ default: 0 })
  stopPrice!: number;

  @Prop({ default: 0 })
  stopLoseValue!: number;

  @Prop({ default: 'percent' })
  stopLoseKind!: string;

  @Prop({ default: 0 })
  takeProfitValue!: number;

  @Prop({ default: 'percent' })
  takeProfitKind!: string;

  @Prop()
  brokerOrderId?: number;

  @Prop({ default: 'created' })
  status!: string;

  @Prop({ type: Object })
  rawPlaceResponse?: unknown;
}

export const OrderSchema = SchemaFactory.createForClass(Order);


