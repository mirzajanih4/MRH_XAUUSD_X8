#ifndef MRH_ML_DATASET_ENGINE_MQH
#define MRH_ML_DATASET_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

enum ENUM_MRH_TRADE_OUTCOME
{
   MRH_OUTCOME_UNKNOWN = 0,
   MRH_OUTCOME_WIN,
   MRH_OUTCOME_LOSS,
   MRH_OUTCOME_BREAKEVEN
};

class CMLDatasetEngine
{
private:
   CSharedMemory* m_memory;
   string m_datasetFileName;

   ENUM_MRH_TRADE_OUTCOME m_lastTradeOutcome;
   double m_lastFinalProfit;
   double m_lastFinalRR;
   datetime m_lastCloseTime;

   string OutcomeToString(ENUM_MRH_TRADE_OUTCOME outcome)
   {
      switch(outcome)
      {
         case MRH_OUTCOME_WIN:
            return "WIN";

         case MRH_OUTCOME_LOSS:
            return "LOSS";

         case MRH_OUTCOME_BREAKEVEN:
            return "BREAKEVEN";

         default:
            return "UNKNOWN";
      }
   }

public:
   CMLDatasetEngine()
   {
      m_memory = NULL;

      m_datasetFileName = "MRH_XAUUSD_X8_Dataset.csv";

      m_lastTradeOutcome = MRH_OUTCOME_UNKNOWN;
      m_lastFinalProfit  = 0.0;
      m_lastFinalRR      = 0.0;
      m_lastCloseTime    = 0;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("ML_DATASET_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("ML_DATASET_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }

   string BuildDatasetRow()
   {
      if(m_memory == NULL)
         return "";

      string row = "";

      row += TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
      row += "," + _Symbol;
      row += "," + IntegerToString((int)_Period);

      row += "," + IntegerToString((int)m_memory.Structure.Bias);
      row += "," + IntegerToString((int)m_memory.Structure.State);

      row += "," + IntegerToString((int)m_memory.Liquidity.State);
      row += "," + IntegerToString((int)m_memory.Liquidity.SweepDetected);

      row += "," + IntegerToString((int)m_memory.OB.Valid);
      row += "," + IntegerToString((int)m_memory.OB.Strength);
      row += "," + IntegerToString((int)m_memory.OB.Mitigated);
      row += "," + IntegerToString((int)m_memory.OB.Invalidated);

      row += "," + IntegerToString((int)m_memory.Execution.State);
      row += "," + IntegerToString((int)m_memory.Execution.EntrySignal);
      row += "," + DoubleToString(m_memory.Execution.Confidence, 2);

      row += "," + IntegerToString((int)m_memory.Risk.RiskApproved);
      row += "," + DoubleToString(m_memory.Risk.RiskPercent, 2);
      row += "," + DoubleToString(m_memory.Risk.LotSize, 2);

      row += "," + IntegerToString((int)m_memory.Trade.State);
      row += "," + DoubleToString(m_memory.Trade.CurrentRR, 2);

      row += "," + OutcomeToString(m_lastTradeOutcome);
      row += "," + DoubleToString(m_lastFinalProfit, 2);
      row += "," + DoubleToString(m_lastFinalRR, 2);
      row += "," + TimeToString(m_lastCloseTime, TIME_DATE | TIME_SECONDS);

      return row;
   }

   void BuildTradeSnapshot()
   {
      if(m_memory == NULL)
         return;

      m_memory.LastSnapshot.SnapshotTime = TimeCurrent();

      m_memory.LastSnapshot.LiquidityScore =
         m_memory.Liquidity.LiquidityScore;

      m_memory.LastSnapshot.OBScore =
         m_memory.Execution.OBScore;

      m_memory.LastSnapshot.PermissionScore =
         m_memory.Execution.PermissionScore;

      m_memory.LastSnapshot.ConfluenceScore =
         m_memory.Execution.ConfluenceScore;

      m_memory.LastSnapshot.ExecutionGrade =
         m_memory.Execution.ExecutionGrade;

      m_memory.LastSnapshot.ConfidenceLevel =
         m_memory.Execution.ConfidenceLevel;

      m_memory.LastSnapshot.RecommendedRisk =
         m_memory.Execution.RecommendedRiskPercent;

      m_memory.LastSnapshot.RiskProfile =
         m_memory.Risk.RiskProfile;

      m_memory.LastSnapshot.TradeState =
         m_memory.Trade.State;

      m_memory.LastSnapshot.CurrentRR =
         m_memory.Trade.CurrentRR;

      m_memory.LastSnapshot.ExitReason =
         m_memory.Trade.ExitReason;
   }

   void TrackTradeOutcome(double entryPrice,
                          double stopLoss,
                          double closePrice,
                          double profit,
                          bool isBuy)
   {
      m_lastFinalProfit = profit;
      m_lastCloseTime   = TimeCurrent();

      double riskDistance = MathAbs(entryPrice - stopLoss);
      double rewardMove   = MathAbs(closePrice - entryPrice);

      if(riskDistance > 0.0)
         m_lastFinalRR = rewardMove / riskDistance;
      else
         m_lastFinalRR = 0.0;

      if(profit > 0.0)
         m_lastTradeOutcome = MRH_OUTCOME_WIN;
      else if(profit < 0.0)
         m_lastTradeOutcome = MRH_OUTCOME_LOSS;
      else
         m_lastTradeOutcome = MRH_OUTCOME_BREAKEVEN;

      string direction = "SELL";

      if(isBuy)
         direction = "BUY";

      MRH_Log("ML_DATASET_ENGINE",
              "OUTCOME_TRACKED",
              "Direction=" + direction +
              " | Outcome=" + OutcomeToString(m_lastTradeOutcome) +
              " | Profit=" + DoubleToString(m_lastFinalProfit, 2) +
              " | FinalRR=" + DoubleToString(m_lastFinalRR, 2));
   }

   void ExportSnapshotToCSV()
   {
      if(m_memory == NULL)
         return;

      int fileHandle =
         FileOpen(m_datasetFileName,
                  FILE_CSV | FILE_READ | FILE_WRITE | FILE_ANSI);

      if(fileHandle == INVALID_HANDLE)
      {
         MRH_Log("ML_DATASET_ENGINE",
                 "CSV_ERROR",
                 "Failed to open dataset file");

         return;
      }

      FileSeek(fileHandle, 0, SEEK_END);

      FileWrite(fileHandle,
                TimeToString(m_memory.LastSnapshot.SnapshotTime,
                             TIME_DATE | TIME_SECONDS),

                DoubleToString(m_memory.LastSnapshot.LiquidityScore, 1),
                DoubleToString(m_memory.LastSnapshot.OBScore, 1),
                DoubleToString(m_memory.LastSnapshot.PermissionScore, 1),
                DoubleToString(m_memory.LastSnapshot.ConfluenceScore, 1),

                m_memory.LastSnapshot.ExecutionGrade,
                m_memory.LastSnapshot.ConfidenceLevel,

                DoubleToString(m_memory.LastSnapshot.RecommendedRisk, 2),
                m_memory.LastSnapshot.RiskProfile,

                IntegerToString((int)m_memory.LastSnapshot.TradeState),

                DoubleToString(m_memory.LastSnapshot.CurrentRR, 2),

                m_memory.LastSnapshot.ExitReason,

                OutcomeToString(m_lastTradeOutcome),
                DoubleToString(m_lastFinalProfit, 2),
                DoubleToString(m_lastFinalRR, 2),
                TimeToString(m_lastCloseTime, TIME_DATE | TIME_SECONDS));

      FileClose(fileHandle);
   }

   void CaptureSnapshot()
   {
      if(m_memory == NULL)
         return;

      BuildTradeSnapshot();
      ExportSnapshotToCSV();

      MRH_Log("ML_DATASET_ENGINE",
              "SNAPSHOT_DEBUG",
              "LiquidityScore=" + DoubleToString(m_memory.LastSnapshot.LiquidityScore, 1) +
              " | OBScore=" + DoubleToString(m_memory.LastSnapshot.OBScore, 1) +
              " | PermissionScore=" + DoubleToString(m_memory.LastSnapshot.PermissionScore, 1) +
              " | ConfluenceScore=" + DoubleToString(m_memory.LastSnapshot.ConfluenceScore, 1) +
              " | Grade=" + m_memory.LastSnapshot.ExecutionGrade +
              " | Confidence=" + m_memory.LastSnapshot.ConfidenceLevel +
              " | RiskProfile=" + m_memory.LastSnapshot.RiskProfile +
              " | RR=" + DoubleToString(m_memory.LastSnapshot.CurrentRR, 2) +
              " | ExitReason=" + m_memory.LastSnapshot.ExitReason +
              " | Outcome=" + OutcomeToString(m_lastTradeOutcome));

      string row = BuildDatasetRow();

      MRH_Log("ML_DATASET_ENGINE",
              "SNAPSHOT",
              "Bias=" + IntegerToString((int)m_memory.Structure.Bias) +
              " | StructureState=" + IntegerToString((int)m_memory.Structure.State) +
              " | LiquidityState=" + IntegerToString((int)m_memory.Liquidity.State) +
              " | Sweep=" + IntegerToString((int)m_memory.Liquidity.SweepDetected) +
              " | OBValid=" + IntegerToString((int)m_memory.OB.Valid) +
              " | ExecutionState=" + IntegerToString((int)m_memory.Execution.State) +
              " | Signal=" + IntegerToString((int)m_memory.Execution.EntrySignal) +
              " | RiskApproved=" + IntegerToString((int)m_memory.Risk.RiskApproved) +
              " | TradeState=" + IntegerToString((int)m_memory.Trade.State) +
              " | RR=" + DoubleToString(m_memory.Trade.CurrentRR, 2) +
              " | Outcome=" + OutcomeToString(m_lastTradeOutcome));

      MRH_Log("ML_DATASET_ENGINE", "DATASET_ROW", row);
   }

   void Update()
   {
      if(m_memory == NULL)
      {
         return;
      }

      CaptureSnapshot();

      MRH_Log("ML_DATASET_ENGINE", "UPDATE", "New bar update");
   }
};

#endif