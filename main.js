const defaultAmount = 1.25;
let accumulateLoss = 0;
let currentAmount = defaultAmount; // DefaultAmount - assuming 100 as default

// Constants that would be defined in MQL5
const WIN = 'W';
const LOSS = 'L';
const payout = 0.85; // Assuming 80% payout
const actualPayout = 0.87;
let consecutiveWin = 0; // This would be tracked elsewhere
let lossTo10 = 0;

function fix2Number(num) {
    return Number(Number(num).toFixed(2));
}

function calculateAmountMartingaleDivided2() {
   if (accumulateLoss === 0) return defaultAmount; // DefaultAmount

   const nextAmount = fix2Number(((accumulateLoss / 2) + (currentAmount * (1-payout))) / payout)
   return nextAmount < 1 ? defaultAmount : nextAmount; // DefaultAmount
}

const results = [
    LOSS, LOSS, LOSS, WIN, LOSS, LOSS, LOSS, LOSS, LOSS, LOSS, WIN, LOSS, WIN, LOSS, LOSS, LOSS, LOSS, LOSS, LOSS, LOSS, LOSS, WIN
]

function martingaleDivided2() {
    for (const result of results) {
        if (result === WIN) {
            consecutiveWin++;
            if (consecutiveWin <= 1) {
                accumulateLoss = fix2Number(accumulateLoss - currentAmount * actualPayout);

                if (lossTo10 >= 10) {
                    lossTo10 = 0;
                    currentAmount = calculateAmountMartingaleDivided2();
                }
            }
            else {
                accumulateLoss = 0;
                currentAmount = calculateAmountMartingaleDivided2();
            }
        }
        else if (result === LOSS) {
            lossTo10++;
            consecutiveWin = 0;
            accumulateLoss = fix2Number(accumulateLoss + currentAmount);
            currentAmount = calculateAmountMartingaleDivided2();
        }

        console.log("result =", result)
        console.log("lossTo10 =", lossTo10)
        console.log("accumulateLoss", accumulateLoss)
        console.log("nextAmount", currentAmount)
        console.log("nextProfit", fix2Number(currentAmount * actualPayout))
        console.log("nextProfit x 2", fix2Number(currentAmount * actualPayout * 2))
        console.log("if win", fix2Number(fix2Number(currentAmount * actualPayout * 2) - accumulateLoss))
        console.log("================================================")
   }

   console.log(results.length)
}

martingaleDivided2()

