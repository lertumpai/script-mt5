import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Result, ResultDocument } from './schemas/result.schema';
import { UpsertResultDto } from './dto/result.dto';

@Injectable()
export class ResultsService {
  constructor(@InjectModel(Result.name) private readonly resultModel: Model<ResultDocument>) {}

  async upsert(dto: UpsertResultDto) {
    const { date, account, ...rest } = dto;
    return this.resultModel.findOneAndUpdate({ date, account }, { $set: { date, account, ...rest } }, { new: true, upsert: true }).lean();
  }

  async findAll(account?: string, date?: string) {
    const filter: any = {};
    if (account) filter.account = account;
    if (date) filter.date = date;

    const rows = await this.resultModel.find(filter).sort({ account: 1, date: -1, createdAt: -1 }).lean();
    const grouped: Record<string, Array<{ date: string; win: number; loss: number; tie: number; maxConsecutiveWin: number; maxConsecutiveLoss: number; consecutiveWin: number; consecutiveLoss: number }>> = {};
    for (const r of rows as any[]) {
      const key = String(r.account);
      if (!grouped[key]) grouped[key] = [];
      grouped[key].push({
        date: String(r.date),
        win: Number(r.win ?? 0),
        loss: Number(r.loss ?? 0),
        tie: Number(r.tie ?? 0),
        maxConsecutiveWin: Number(r.maxConsecutiveWin ?? 0),
        maxConsecutiveLoss: Number(r.maxConsecutiveLoss ?? 0),
        consecutiveWin: Number(r.consecutiveWin ?? 0),
        consecutiveLoss: Number(r.consecutiveLoss ?? 0),
      });
    }
    return grouped;
  }
}


