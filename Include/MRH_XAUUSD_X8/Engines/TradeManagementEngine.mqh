#ifndef MRH_TRADE_MANAGEMENT_ENGINE_MQH
#define MRH_TRADE_MANAGEMENT_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

class CTradeManagementEngine
{
private:
   CSharedMemory* m_memory;

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
         MRH_Log("TRADE_MANAGEMENT_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("TRADE_MANAGEMENT_ENGINE", "INIT", "Initialized with SharedMemory");
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

   double entry = m_memory.Execution.EntryPrice;
   double sl    = m_memory.Execution.StopLoss;

   if(entry <= 0.0 || sl <= 0.0)
      return;

   double riskDistance = MathAbs(entry - sl);

   if(riskDistance <= 0.0)
      return;

   bool isBuy  = (sl < entry);
   bool isSell = (sl > entry);

   double highPrice = iHigh(_Symbol, _Period, 1);
   double lowPrice  = iLow(_Symbol, _Period, 1);

   if(isBuy)
      m_memory.Trade.CurrentRR = (highPrice - entry) / riskDistance;
   else if(isSell)
      m_memory.Trade.CurrentRR = (entry - lowPrice) / riskDistance;
}

   void ManageBreakEven()
   {
      if(m_memory == NULL)
         return;

      if(m_memory.Trade.State != TRADE_ACTIVE)
         return;

      if(!m_memory.Trade.BreakEvenActivated &&
         m_memory.Trade.CurrentRR >= m_memory.Trade.BreakEvenRR)
      {
         m_memory.Trade.BreakEvenActivated = true;
         m_memory.Trade.State = TRADE_BE;

         MRH_Log("TRADE_MANAGEMENT_ENGINE",
                 "BREAK_EVEN",
                 "Break Even activated");
      }
   }

   void ManagePartialClose()
   {
      if(m_memory == NULL)
         return;

      if(m_memory.Trade.State != TRADE_ACTIVE &&
         m_memory.Trade.State != TRADE_BE)
      {
         return;
      }

      if(!m_memory.Trade.PartialClosed &&
         m_memory.Trade.CurrentRR >= m_memory.Trade.PartialCloseRR)
      {
         m_memory.Trade.PartialClosed = true;
         m_memory.Trade.State = TRADE_PARTIAL;

         MRH_Log("TRADE_MANAGEMENT_ENGINE",
                 "PARTIAL_CLOSE",
                 "Partial close condition reached");
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

      ManageBreakEven();
      ManagePartialClose();
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