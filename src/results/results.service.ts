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
    const match: any = {};
    if (account) match.account = account;
    if (date) match.date = date;
    return this.resultModel
      .aggregate([
        { $match: match },
        { $sort: { account: 1, date: -1, createdAt: -1 } },
        {
          $group: {
            _id: '$account',
            results: {
              $push: {
                date: '$date',
                win: '$win',
                loss: '$loss',
                tie: '$tie',
                maxConsecutiveWin: '$maxConsecutiveWin',
                maxConsecutiveLoss: '$maxConsecutiveLoss',
                consecutiveWin: '$consecutiveWin',
                consecutiveLoss: '$consecutiveLoss',
              },
            },
          },
        },
        { $project: { _id: 0, account: '$_id', results: 1 } },
        { $sort: { account: 1 } },
      ])
      .exec();
  }
}


