import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type ResultDocument = HydratedDocument<Result>;

@Schema({ timestamps: true })
export class Result {
  @Prop({ required: true })
  date!: string; // YYYY-MM-DD

  @Prop({ required: true })
  account!: string;

  @Prop({ default: 0 })
  win!: number;

  @Prop({ default: 0 })
  loss!: number;

  @Prop({ default: 0 })
  tie!: number;

  @Prop({ default: 0 })
  maxConsecutiveWin!: number;

  @Prop({ default: 0 })
  maxConsecutiveLoss!: number;

  @Prop({ default: 0 })
  consecutiveWin!: number;

  @Prop({ default: 0 })
  consecutiveLoss!: number;
}

export const ResultSchema = SchemaFactory.createForClass(Result);
ResultSchema.index({ date: 1, account: 1 }, { unique: true });


