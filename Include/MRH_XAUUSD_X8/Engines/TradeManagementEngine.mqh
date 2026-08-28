#ifndef MRH_TRADE_MANAGEMENT_ENGINE_MQH
#define MRH_TRADE_MANAGEMENT_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

#include <Trade/Trade.mqh>

class CTradeManagementEngine
{
private:
   CSharedMemory* m_memory;
CTrade m_trade;

public:
   CTradeManagementEngine()
   {
      m_memory = NULL;
   }

  bool Init(CSharedMemory* memory)
{
   m_memory = memory;

   if(m_memory == NULL)
   {
      MRH_Log("TRADE_MANAGER", "ERROR", "SharedMemory is NULL");
      return false;
   }

   m_trade.SetAsyncMode(false);

   MRH_Log("TRADE_MANAGER", "INIT", "Initialized with SharedMemory");
   return true;
}

   void UpdateTradeStateMemory()
   {
      if(m_memory == NULL)
         return;

      if(m_memory.Trade.State == TRADE_ACTIVE ||
         m_memory.Trade.State == TRADE_BE ||
         m_memory.Trade.State == TRADE_PARTIAL ||
         m_memory.Trade.State == TRADE_CLOSED)
      {
         return;
      }

      if(m_memory.Risk.RiskApproved &&
         m_memory.Execution.EntrySignal &&
         m_memory.Execution.State == EXECUTION_READY)
      {
         m_memory.Trade.State = TRADE_ACTIVE;

         MRH_Log("TRADE_MANAGEMENT_ENGINE",
                 "STATE",
                 "Virtual trade state activated");

         return;
      }

      m_memory.Trade.State = TRADE_NONE;
   }

   void CalculateCurrentRR()
{
   if(m_memory == NULL)
      return;

   m_memory.Trade.CurrentRR = 0.0;

   if(m_memory.Trade.State != TRADE_ACTIVE &&
      m_memory.Trade.State != TRADE_BE &&
      m_memory.Trade.State != TRADE_PARTIAL)
   {
      return;
   }

   // STEP130A-3 - Live MT5 position is the source of truth
   if(!PositionSelect(_Symbol))
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130A_RR_BLOCKED",
              "No live position found for RR calculation");
      return;
   }

   double entry = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl    = PositionGetDouble(POSITION_SL);
   long positionType = PositionGetInteger(POSITION_TYPE);

   if(entry <= 0.0 || sl <= 0.0)
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130A_RR_BLOCKED",
              "Live Entry or SL is invalid");
      return;
   }

   double riskDistance = MathAbs(entry - sl);

   if(riskDistance <= 0.0)
      return;

   double currentPrice = 0.0;

   if(positionType == POSITION_TYPE_BUY)
   {
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      m_memory.Trade.CurrentRR =
         (currentPrice - entry) / riskDistance;
   }
   else if(positionType == POSITION_TYPE_SELL)
   {
      currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      m_memory.Trade.CurrentRR =
         (entry - currentPrice) / riskDistance;
   }
   else
   {
      return;
   }

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "STEP130A_LIVE_RR",
           "Entry=" + DoubleToString(entry, _Digits) +
           " | SL=" + DoubleToString(sl, _Digits) +
           " | CurrentPrice=" + DoubleToString(currentPrice, _Digits) +
           " | RiskDistance=" + DoubleToString(riskDistance, _Digits) +
           " | LiveRR=" + DoubleToString(m_memory.Trade.CurrentRR, 2));
}
  void ManageBreakEven()
{
   if(m_memory == NULL)
      return;

   // Break Even فقط بعد از Partial Close واقعی
   if(m_memory.Trade.State != TRADE_PARTIAL)
      return;

   if(!m_memory.Trade.PartialClosed)
      return;

   if(m_memory.Trade.BreakEvenActivated)
      return;

   if(m_memory.Trade.CurrentRR < m_memory.Trade.BreakEvenRR)
      return;

   if(!PositionSelect(_Symbol))
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130C_BE_FAILED",
              "Live position not found");
      return;
   }

   ulong ticket = (ulong)PositionGetInteger(POSITION_TICKET);

   double liveEntry = PositionGetDouble(POSITION_PRICE_OPEN);
   double liveSL    = PositionGetDouble(POSITION_SL);
   double liveTP    = PositionGetDouble(POSITION_TP);

   if(liveEntry <= 0.0)
      return;

   double breakEvenSL = NormalizeDouble(liveEntry, _Digits);

   ResetLastError();

   bool result =
      m_trade.PositionModify(ticket, breakEvenSL, liveTP);

   int  lastError = GetLastError();
   uint retcode   = m_trade.ResultRetcode();

   if(!result)
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130C_BE_FAILED",
              "Ticket=" + IntegerToString((long)ticket) +
              " | OldSL=" + DoubleToString(liveSL, _Digits) +
              " | RequestedSL=" + DoubleToString(breakEvenSL, _Digits) +
              " | LastError=" + IntegerToString(lastError) +
              " | Retcode=" + IntegerToString((int)retcode) +
              " | Description=" + m_trade.ResultRetcodeDescription());
      return;
   }

   // تأیید تغییر واقعی SL از خود پوزیشن MT5
   if(!PositionSelectByTicket(ticket))
      return;

   double actualSL = PositionGetDouble(POSITION_SL);

   bool breakEvenConfirmed =
      MathAbs(actualSL - breakEvenSL) <= (_Point * 2.0);

   if(!breakEvenConfirmed)
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130C_BE_NOT_CONFIRMED",
              "RequestedSL=" + DoubleToString(breakEvenSL, _Digits) +
              " | ActualSL=" + DoubleToString(actualSL, _Digits));
      return;
   }

   m_memory.Trade.BreakEvenActivated = true;
   m_memory.Trade.State = TRADE_BE;

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "STEP130C_BE_CONFIRMED",
           "Real Break Even confirmed"
           " | Ticket=" + IntegerToString((long)ticket) +
           " | Entry=" + DoubleToString(liveEntry, _Digits) +
           " | OldSL=" + DoubleToString(liveSL, _Digits) +
           " | ActualSL=" + DoubleToString(actualSL, _Digits) +
           " | Retcode=" + IntegerToString((int)retcode));
}

  void ManagePartialClose()
{
   if(m_memory == NULL)
      return;

   // STEP130A - Live position audit
   if(!PositionSelect(_Symbol))
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130A_POSITION_NOT_FOUND",
              "No live position found");

      return;
   }

   double liveEntry   = PositionGetDouble(POSITION_PRICE_OPEN);
   double liveSL      = PositionGetDouble(POSITION_SL);
   double liveVolume  = PositionGetDouble(POSITION_VOLUME);
   ulong  ticket      = (ulong)PositionGetInteger(POSITION_TICKET);
   long   positionType = PositionGetInteger(POSITION_TYPE);

   double livePrice = 0.0;
   double liveRR    = 0.0;

   if(positionType == POSITION_TYPE_BUY)
      livePrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   else if(positionType == POSITION_TYPE_SELL)
      livePrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   else
      return;

   double liveRiskDistance = MathAbs(liveEntry - liveSL);

   if(liveRiskDistance > 0.0)
   {
      if(positionType == POSITION_TYPE_BUY)
         liveRR = (livePrice - liveEntry) / liveRiskDistance;
      else
         liveRR = (liveEntry - livePrice) / liveRiskDistance;
   }

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "STEP130A_LIVE_AUDIT",
           "PositionFound=TRUE" +
           " | InternalState=" +
           IntegerToString((int)m_memory.Trade.State) +
           " | InternalRR=" +
           DoubleToString(m_memory.Trade.CurrentRR, 2) +
           " | PartialTarget=" +
           DoubleToString(m_memory.Trade.PartialCloseRR, 2) +
           " | InternalEntry=" +
           DoubleToString(m_memory.Execution.EntryPrice, _Digits) +
           " | InternalSL=" +
           DoubleToString(m_memory.Execution.StopLoss, _Digits) +
           " | LiveEntry=" +
           DoubleToString(liveEntry, _Digits) +
           " | LiveSL=" +
           DoubleToString(liveSL, _Digits) +
           " | LivePrice=" +
           DoubleToString(livePrice, _Digits) +
           " | LiveRR=" +
           DoubleToString(liveRR, 2) +
           " | LiveVolume=" +
           DoubleToString(liveVolume, 2));

   if(m_memory.Trade.State != TRADE_ACTIVE &&
      m_memory.Trade.State != TRADE_BE)
   {
      return;
   }

   if(m_memory.Trade.PartialClosed)
      return;

   if(m_memory.Trade.CurrentRR < m_memory.Trade.PartialCloseRR)
      return;

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(minLot <= 0.0 || lotStep <= 0.0)
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130A_PARTIAL_FAILED",
              "Invalid broker volume settings");

      return;
   }

   // Close exactly 50 percent, normalized to broker lot step
   double closeVolume =
      MathFloor((liveVolume * 0.50) / lotStep) * lotStep;

   closeVolume = NormalizeDouble(closeVolume, 2);

   double remainingVolume = liveVolume - closeVolume;

   if(closeVolume < minLot)
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130A_PARTIAL_BLOCKED",
              "Close volume is below broker minimum"
              " | LiveVolume=" + DoubleToString(liveVolume, 2) +
              " | CloseVolume=" + DoubleToString(closeVolume, 2) +
              " | MinLot=" + DoubleToString(minLot, 2));

      return;
   }

   if(remainingVolume < minLot)
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130A_PARTIAL_BLOCKED",
              "Remaining volume would be below broker minimum"
              " | LiveVolume=" + DoubleToString(liveVolume, 2) +
              " | CloseVolume=" + DoubleToString(closeVolume, 2) +
              " | RemainingVolume=" +
              DoubleToString(remainingVolume, 2));

      return;
   }

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "STEP130A_PARTIAL_TRIGGER",
           "Ticket=" + IntegerToString((long)ticket) +
           " | LiveRR=" + DoubleToString(liveRR, 2) +
           " | VolumeBefore=" + DoubleToString(liveVolume, 2) +
           " | VolumeToClose=" + DoubleToString(closeVolume, 2));

  // STEP130B - Partial close request audit
ResetLastError();

ENUM_ACCOUNT_MARGIN_MODE marginMode =
   (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);

bool result =
   m_trade.PositionClosePartial(ticket, closeVolume);

int  lastError = GetLastError();
uint retcode   = m_trade.ResultRetcode();

if(result)
{
   bool positionStillExists = PositionSelectByTicket(ticket);
   double actualRemainingVolume = 0.0;

   if(positionStillExists)
      actualRemainingVolume = PositionGetDouble(POSITION_VOLUME);

   bool volumeReduced =
      positionStillExists &&
      actualRemainingVolume < liveVolume &&
      MathAbs(actualRemainingVolume - remainingVolume) <= lotStep;

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "STEP130B_PARTIAL_VERIFY",
           "Symbol=" + _Symbol +
           " | Ticket=" + IntegerToString((long)ticket) +
           " | PositionStillExists=" +
           (positionStillExists ? "TRUE" : "FALSE") +
           " | VolumeBefore=" + DoubleToString(liveVolume, 2) +
           " | RequestedClose=" + DoubleToString(closeVolume, 2) +
           " | ExpectedRemaining=" +
           DoubleToString(remainingVolume, 2) +
           " | ActualRemaining=" +
           DoubleToString(actualRemainingVolume, 2) +
           " | VolumeReduced=" +
           (volumeReduced ? "TRUE" : "FALSE") +
           " | Deal=" +
           IntegerToString((long)m_trade.ResultDeal()) +
           " | Order=" +
           IntegerToString((long)m_trade.ResultOrder()) +
           " | Retcode=" + IntegerToString((int)retcode) +
           " | Description=" + m_trade.ResultRetcodeDescription());

   if(volumeReduced)
   {
      m_memory.Trade.PartialClosed = true;
      m_memory.Trade.State = TRADE_PARTIAL;

      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130B_PARTIAL_CONFIRMED",
              "Real position volume reduction confirmed");
   }
   else
   {
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "STEP130B_PARTIAL_NOT_CONFIRMED",
              "Trade request returned success but live volume reduction was not confirmed");
   }
}


else
{
// STEP130C - Print the actual CTrade request/result on local failure
m_trade.PrintRequest();
m_trade.PrintResult();
   double volumeMin =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double volumeMax =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   double volumeStep =
      SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   long tradeMode =
      SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "STEP130B_PARTIAL_REQUEST_FAILED",
           "Symbol=" + _Symbol +
           " | Ticket=" + IntegerToString((long)ticket) +
           " | Result=FALSE" +
           " | LastError=" + IntegerToString(lastError) +
           " | Retcode=" + IntegerToString((int)retcode) +
           " | Description=" + m_trade.ResultRetcodeDescription() +
           " | MarginMode=" + IntegerToString((int)marginMode) +
           " | SymbolTradeMode=" + IntegerToString((int)tradeMode) +
           " | LiveVolume=" + DoubleToString(liveVolume, 2) +
           " | CloseVolume=" + DoubleToString(closeVolume, 2) +
           " | RemainingVolume=" + DoubleToString(remainingVolume, 2) +
           " | MinLot=" + DoubleToString(volumeMin, 2) +
           " | MaxLot=" + DoubleToString(volumeMax, 2) +
           " | LotStep=" + DoubleToString(volumeStep, 2));
}
}
   void ManageTrailingStop()
   {
      if(m_memory == NULL)
         return;

      if(m_memory.Trade.State != TRADE_PARTIAL &&
         m_memory.Trade.State != TRADE_BE)
      {
         return;
      }

      if(!m_memory.Trade.TrailingStopActivated &&
         m_memory.Trade.CurrentRR >= m_memory.Trade.PartialCloseRR)
      {
         m_memory.Trade.TrailingStopActivated = true;

         MRH_Log("TRADE_MANAGEMENT_ENGINE",
                 "TRAILING_STOP",
                 "Trailing Stop activated");
      }
   }

   void ManageFinalExit()
   {
      if(m_memory == NULL)
         return;

      if(m_memory.Trade.State != TRADE_ACTIVE &&
         m_memory.Trade.State != TRADE_BE &&
         m_memory.Trade.State != TRADE_PARTIAL)
      {
         return;
      }

      if(m_memory.Trade.CurrentRR <= -1.0)
      {
         m_memory.Trade.State = TRADE_CLOSED;
         m_memory.Trade.ExitReason = EXIT_STOPLOSS;

         MRH_Log("TRADE_MANAGEMENT_ENGINE",
                 "EXIT",
                 "Trade closed by Stop Loss");
      }
   }
void PopulateTradeOutcomeOnClose()
{
   if(m_memory == NULL)
      return;

   if(m_memory.Trade.State != TRADE_CLOSED)
      return;

   // if(m_memory.Trade.CloseTime > 0)
//    return;

   double entry = m_memory.Execution.EntryPrice;
   double sl    = m_memory.Execution.StopLoss;

   if(entry <= 0.0 || sl <= 0.0)
      return;

   double closePrice = iClose(_Symbol, _Period, 1);
   double riskDistance = MathAbs(entry - sl);

   if(riskDistance <= 0.0)
      return;

   m_memory.Trade.ClosePrice = closePrice;
   m_memory.Trade.CloseTime  = TimeCurrent();
   
  if(m_memory.Trade.TradeTicket == 0)
{
   m_memory.Trade.TradeTicket =
      (ulong)m_memory.Trade.CloseTime * 1000000 +
      (ulong)MathRound(m_memory.Trade.ClosePrice * 100.0);
}
   
   if(m_memory.Structure.Bias == BIAS_BULLISH)
      m_memory.Trade.FinalRR = (closePrice - entry) / riskDistance;
   else if(m_memory.Structure.Bias == BIAS_BEARISH)
      m_memory.Trade.FinalRR = (entry - closePrice) / riskDistance;
   else
      m_memory.Trade.FinalRR = 0.0;

   if(m_memory.Structure.Bias == BIAS_BULLISH)
   m_memory.Trade.FinalProfit = closePrice - entry;
else if(m_memory.Structure.Bias == BIAS_BEARISH)
   m_memory.Trade.FinalProfit = entry - closePrice;
else
   m_memory.Trade.FinalProfit = 0.0;

   if(m_memory.Trade.FinalRR > 0.0)
      m_memory.Trade.Outcome = TRADE_OUTCOME_WIN;
   else if(m_memory.Trade.FinalRR < 0.0)
      m_memory.Trade.Outcome = TRADE_OUTCOME_LOSS;
   else
      m_memory.Trade.Outcome = TRADE_OUTCOME_BREAKEVEN;
      
      m_memory.Trade.LossCause = MRH_LOSS_CAUSE_NONE;

if(m_memory.Trade.Outcome == TRADE_OUTCOME_LOSS)
{
   if(m_memory.Trade.ExitReason == EXIT_STOPLOSS)
      m_memory.Trade.LossCause = MRH_LOSS_CAUSE_STOPLOSS;
   else if(m_memory.OB.Invalidated)
      m_memory.Trade.LossCause = MRH_LOSS_CAUSE_OB_INVALIDATION;
   else if(m_memory.Structure.State == STRUCTURE_TRANSITION)
      m_memory.Trade.LossCause = MRH_LOSS_CAUSE_STRUCTURE_FLIP;
   else if(!m_memory.Liquidity.SweepDetected)
      m_memory.Trade.LossCause = MRH_LOSS_CAUSE_LIQUIDITY_FAILURE;
   else if(m_memory.Execution.Confidence < 50.0)
      m_memory.Trade.LossCause = MRH_LOSS_CAUSE_WEAK_EXECUTION;
   else
      m_memory.Trade.LossCause = MRH_LOSS_CAUSE_UNKNOWN;
}

m_memory.Trade.WinCause = MRH_WIN_CAUSE_NONE;

if(m_memory.Trade.Outcome == TRADE_OUTCOME_WIN)
{
   if(m_memory.Trade.ExitReason == EXIT_TAKEPROFIT)
      m_memory.Trade.WinCause = MRH_WIN_CAUSE_TAKEPROFIT;
   else if(m_memory.Liquidity.TargetLiquidity > 0.0)
      m_memory.Trade.WinCause = MRH_WIN_CAUSE_LIQUIDITY_TARGET;
   else if(m_memory.OB.Valid && m_memory.OB.Mitigated && !m_memory.OB.Invalidated)
      m_memory.Trade.WinCause = MRH_WIN_CAUSE_OB_REACTION;
   else if(m_memory.Structure.State == STRUCTURE_TRENDING)
      m_memory.Trade.WinCause = MRH_WIN_CAUSE_STRUCTURE_CONTINUATION;
   else if(m_memory.Execution.ConfluenceScore >= 80.0)
      m_memory.Trade.WinCause = MRH_WIN_CAUSE_HIGH_CONFLUENCE;
   else
      m_memory.Trade.WinCause = MRH_WIN_CAUSE_UNKNOWN;
}

      GenerateTradeLabel();

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "OUTCOME",
           "Outcome populated"
           " | FinalRR=" + DoubleToString(m_memory.Trade.FinalRR, 2) +
           " | ClosePrice=" + DoubleToString(m_memory.Trade.ClosePrice, _Digits) +
           " | TradeLabel=" + m_memory.Trade.TradeLabel +
           " | LossCause=" + IntegerToString((int)m_memory.Trade.LossCause) +
           " | WinCause=" + IntegerToString((int)m_memory.Trade.WinCause));
           
}

void GenerateTradeLabel()

{
   if(m_memory == NULL)
      return;

   switch(m_memory.Trade.Outcome)
   {
      case TRADE_OUTCOME_WIN:
         m_memory.Trade.TradeLabel = "WIN";
         break;

      case TRADE_OUTCOME_LOSS:
         m_memory.Trade.TradeLabel = "LOSS";
         break;

      case TRADE_OUTCOME_BREAKEVEN:
         m_memory.Trade.TradeLabel = "BREAKEVEN";
         break;

      default:
         m_memory.Trade.TradeLabel = "UNLABELED";
         break;
   }
   
      if(m_memory.Trade.TradeLabel == "WIN")
      m_memory.Trade.AdvancedLabel = "GOOD_WIN";

   else if(m_memory.Trade.TradeLabel == "LOSS")
      m_memory.Trade.AdvancedLabel = "NORMAL_LOSS";

   else if(m_memory.Trade.TradeLabel == "BREAKEVEN")
      m_memory.Trade.AdvancedLabel = "BREAKEVEN";

   else
      m_memory.Trade.AdvancedLabel = "UNCLASSIFIED";
      
      if(m_memory.Trade.AdvancedLabel == "GOOD_WIN")
   m_memory.Trade.LabelQuality = "HIGH_QUALITY";

else if(m_memory.Trade.AdvancedLabel == "NORMAL_LOSS")
   m_memory.Trade.LabelQuality = "MEDIUM_QUALITY";

else if(m_memory.Trade.AdvancedLabel == "BREAKEVEN")
   m_memory.Trade.LabelQuality = "LOW_QUALITY";

else
   m_memory.Trade.LabelQuality = "UNKNOWN";
   if(m_memory.Trade.LabelQuality == "HIGH_QUALITY")
   m_memory.Trade.DynamicQualityLabel = "STRONG_SETUP";

else if(m_memory.Trade.LabelQuality == "MEDIUM_QUALITY")
   m_memory.Trade.DynamicQualityLabel = "AVERAGE_SETUP";

else if(m_memory.Trade.LabelQuality == "LOW_QUALITY")
   m_memory.Trade.DynamicQualityLabel = "WEAK_SETUP";

else
   m_memory.Trade.DynamicQualityLabel = "UNRATED";
   
      // STEP54 - Outcome Labeling Audit Layer
   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "LABEL_AUDIT",
           "Outcome=" + IntegerToString((int)m_memory.Trade.Outcome) +
           " | TradeLabel=" + m_memory.Trade.TradeLabel +
           " | AdvancedLabel=" + m_memory.Trade.AdvancedLabel +
           " | LabelQuality=" + m_memory.Trade.LabelQuality +
           " | DynamicQualityLabel=" + m_memory.Trade.DynamicQualityLabel);
}

void UpdateSetupPerformance()
{
   if(m_memory == NULL)
      return;

   if(m_memory.Trade.State != TRADE_CLOSED)
      return;

   if(m_memory.Trade.Outcome == TRADE_OUTCOME_UNKNOWN)
      return;

   if(m_memory.Execution.ExecutionGrade == "A_SETUP")
   {
      double previousCount = (double)m_memory.ASetupPerformance.TotalTrades;

      m_memory.ASetupPerformance.TotalTrades++;

      if(m_memory.Trade.Outcome == TRADE_OUTCOME_WIN)
         m_memory.ASetupPerformance.Wins++;
      else if(m_memory.Trade.Outcome == TRADE_OUTCOME_LOSS)
         m_memory.ASetupPerformance.Losses++;
      else if(m_memory.Trade.Outcome == TRADE_OUTCOME_BREAKEVEN)
         m_memory.ASetupPerformance.Breakevens++;

      if(m_memory.ASetupPerformance.TotalTrades > 0)
         m_memory.ASetupPerformance.WinRate =
            ((double)m_memory.ASetupPerformance.Wins /
             (double)m_memory.ASetupPerformance.TotalTrades) * 100.0;

      m_memory.ASetupPerformance.AverageRR =
         ((m_memory.ASetupPerformance.AverageRR * previousCount) +
          m_memory.Trade.FinalRR) /
         (double)m_memory.ASetupPerformance.TotalTrades;

      m_memory.ASetupPerformance.AverageProfit =
         ((m_memory.ASetupPerformance.AverageProfit * previousCount) +
          m_memory.Trade.FinalProfit) /
         (double)m_memory.ASetupPerformance.TotalTrades;

      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "SETUP_PERFORMANCE",
              "Setup=A_SETUP" +
              " | Total=" + IntegerToString(m_memory.ASetupPerformance.TotalTrades) +
              " | Wins=" + IntegerToString(m_memory.ASetupPerformance.Wins) +
              " | Losses=" + IntegerToString(m_memory.ASetupPerformance.Losses) +
              " | BE=" + IntegerToString(m_memory.ASetupPerformance.Breakevens) +
              " | WinRate=" + DoubleToString(m_memory.ASetupPerformance.WinRate, 2) +
              " | AvgRR=" + DoubleToString(m_memory.ASetupPerformance.AverageRR, 2) +
              " | AvgProfit=" + DoubleToString(m_memory.ASetupPerformance.AverageProfit, 2));
   }
   else if(m_memory.Execution.ExecutionGrade == "B_SETUP")
   {
      double previousCount = (double)m_memory.BSetupPerformance.TotalTrades;

      m_memory.BSetupPerformance.TotalTrades++;

      if(m_memory.Trade.Outcome == TRADE_OUTCOME_WIN)
         m_memory.BSetupPerformance.Wins++;
      else if(m_memory.Trade.Outcome == TRADE_OUTCOME_LOSS)
         m_memory.BSetupPerformance.Losses++;
      else if(m_memory.Trade.Outcome == TRADE_OUTCOME_BREAKEVEN)
         m_memory.BSetupPerformance.Breakevens++;

      if(m_memory.BSetupPerformance.TotalTrades > 0)
         m_memory.BSetupPerformance.WinRate =
            ((double)m_memory.BSetupPerformance.Wins /
             (double)m_memory.BSetupPerformance.TotalTrades) * 100.0;

      m_memory.BSetupPerformance.AverageRR =
         ((m_memory.BSetupPerformance.AverageRR * previousCount) +
          m_memory.Trade.FinalRR) /
         (double)m_memory.BSetupPerformance.TotalTrades;

      m_memory.BSetupPerformance.AverageProfit =
         ((m_memory.BSetupPerformance.AverageProfit * previousCount) +
          m_memory.Trade.FinalProfit) /
         (double)m_memory.BSetupPerformance.TotalTrades;

      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "SETUP_PERFORMANCE",
              "Setup=B_SETUP" +
              " | Total=" + IntegerToString(m_memory.BSetupPerformance.TotalTrades) +
              " | Wins=" + IntegerToString(m_memory.BSetupPerformance.Wins) +
              " | Losses=" + IntegerToString(m_memory.BSetupPerformance.Losses) +
              " | BE=" + IntegerToString(m_memory.BSetupPerformance.Breakevens) +
              " | WinRate=" + DoubleToString(m_memory.BSetupPerformance.WinRate, 2) +
              " | AvgRR=" + DoubleToString(m_memory.BSetupPerformance.AverageRR, 2) +
              " | AvgProfit=" + DoubleToString(m_memory.BSetupPerformance.AverageProfit, 2));
   }
}

void UpdateHistoricalSetupConfidence()
{
   if(m_memory == NULL)
      return;

   double confidence = 0.0;
   string confidenceClass = "NO_HISTORY";
   bool ready = false;

   if(m_memory.Execution.ExecutionGrade == "A_SETUP")
   {
      if(m_memory.ASetupPerformance.TotalTrades >= 10)
      {
         confidence = m_memory.ASetupPerformance.WinRate;
         ready = true;
      }
   }
   else if(m_memory.Execution.ExecutionGrade == "B_SETUP")
   {
      if(m_memory.BSetupPerformance.TotalTrades >= 10)
      {
         confidence = m_memory.BSetupPerformance.WinRate;
         ready = true;
      }
   }

   if(!ready)
   {
      confidence = 0.0;
      confidenceClass = "INSUFFICIENT_HISTORY";
   }
   else if(confidence >= 70.0)
      confidenceClass = "HIGH_HISTORICAL_CONFIDENCE";
   else if(confidence >= 55.0)
      confidenceClass = "MEDIUM_HISTORICAL_CONFIDENCE";
   else if(confidence >= 40.0)
      confidenceClass = "LOW_HISTORICAL_CONFIDENCE";
   else
      confidenceClass = "WEAK_HISTORICAL_CONFIDENCE";

   m_memory.LastSnapshot.HistoricalSetupConfidence = confidence;
   m_memory.LastSnapshot.HistoricalSetupConfidenceClass = confidenceClass;
   m_memory.LastSnapshot.HistoricalSetupConfidenceReady = ready;

   MRH_Log("TRADE_MANAGEMENT_ENGINE",
           "HISTORICAL_SETUP_CONFIDENCE",
           "Grade=" + m_memory.Execution.ExecutionGrade +
           " | Confidence=" + DoubleToString(confidence, 2) +
           " | Class=" + confidenceClass +
           " | Ready=" + (ready ? "TRUE" : "FALSE"));
}

   void DebugTradeState()
   {
      if(m_memory == NULL)
         return;

      string stateText = "NONE";

      if(m_memory.Trade.State == TRADE_ACTIVE)
         stateText = "ACTIVE";
      else if(m_memory.Trade.State == TRADE_BE)
         stateText = "BE";
      else if(m_memory.Trade.State == TRADE_PARTIAL)
         stateText = "PARTIAL";
      else if(m_memory.Trade.State == TRADE_CLOSED)
         stateText = "CLOSED";

      string partialText = "false";
      string beText = "false";
      string trailingText = "false";
      string exitReasonText = m_memory.Trade.ExitReason;

      if(m_memory.Trade.PartialClosed)
         partialText = "true";

      if(m_memory.Trade.BreakEvenActivated)
         beText = "true";

      if(m_memory.Trade.TrailingStopActivated)
         trailingText = "true";

      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "DEBUG",
              "State=" + stateText +
              " | RR=" + DoubleToString(m_memory.Trade.CurrentRR, 2) +
              " | BreakEvenRR=" + DoubleToString(m_memory.Trade.BreakEvenRR, 2) +
              " | PartialCloseRR=" + DoubleToString(m_memory.Trade.PartialCloseRR, 2) +
              " | Partial=" + partialText +
              " | BE=" + beText +
              " | Trailing=" + trailingText +
              " | ExitReason=" + exitReasonText);
   }

   void Update()
   {
      if(m_memory == NULL)
         return;

      UpdateTradeStateMemory();
      CalculateCurrentRR();

      ManagePartialClose();
      ManageBreakEven();
      ManageTrailingStop();
      ManageFinalExit();
      PopulateTradeOutcomeOnClose();
      UpdateSetupPerformance();
      UpdateHistoricalSetupConfidence();

      DebugTradeState();
      
      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "UPDATE",
              "New bar update");
   }
};

#endif