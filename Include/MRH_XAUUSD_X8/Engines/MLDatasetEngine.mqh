#ifndef MRH_ML_DATASET_ENGINE_MQH
#define MRH_ML_DATASET_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

class CMLDatasetEngine
{
private:
   CSharedMemory* m_memory;
   string m_datasetFileName;

   string TradeOutcomeToString(ENUM_TRADE_OUTCOME outcome)
   {
      switch(outcome)
      {
         case TRADE_OUTCOME_WIN:
            return "WIN";

         case TRADE_OUTCOME_LOSS:
            return "LOSS";

         case TRADE_OUTCOME_BREAKEVEN:
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

      row += "," + TradeOutcomeToString(m_memory.Trade.Outcome);
      row += "," + DoubleToString(m_memory.Trade.FinalProfit, 2);
      row += "," + DoubleToString(m_memory.Trade.FinalRR, 2);
      row += "," + DoubleToString(m_memory.Trade.ClosePrice, _Digits);
      row += "," + TimeToString(m_memory.Trade.CloseTime, TIME_DATE | TIME_SECONDS);

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

      m_memory.LastSnapshot.Outcome =
         m_memory.Trade.Outcome;

      m_memory.LastSnapshot.FinalProfit =
         m_memory.Trade.FinalProfit;

      m_memory.LastSnapshot.FinalRR =
         m_memory.Trade.FinalRR;

      m_memory.LastSnapshot.ClosePrice =
         m_memory.Trade.ClosePrice;

      m_memory.LastSnapshot.CloseTime =
         m_memory.Trade.CloseTime;
   }
void ValidateOutcomeSnapshot()
{
   if(m_memory == NULL)
      return;

   if(m_memory.LastSnapshot.TradeState != TRADE_CLOSED)
      return;

   MRH_Log("ML_DATASET_ENGINE",
           "OUTCOME_VALIDATION",
           "Outcome=" + TradeOutcomeToString(m_memory.LastSnapshot.Outcome) +
           " | FinalProfit=" + DoubleToString(m_memory.LastSnapshot.FinalProfit, 2) +
           " | FinalRR=" + DoubleToString(m_memory.LastSnapshot.FinalRR, 2) +
           " | ClosePrice=" + DoubleToString(m_memory.LastSnapshot.ClosePrice, _Digits) +
           " | CloseTime=" + TimeToString(m_memory.LastSnapshot.CloseTime, TIME_DATE | TIME_SECONDS));
}
void WriteCSVHeaderIfNeeded(int fileHandle)
{
   if(fileHandle == INVALID_HANDLE)
      return;

   if(FileSize(fileHandle) > 0)
      return;

   FileWrite(fileHandle,
             "SnapshotTime",
             "LiquidityScore",
             "OBScore",
             "PermissionScore",
             "ConfluenceScore",
             "ExecutionGrade",
             "ConfidenceLevel",
             "RecommendedRisk",
             "RiskProfile",
             "TradeState",
             "CurrentRR",
             "ExitReason",
             "Outcome",
             "FinalProfit",
             "FinalRR",
             "ClosePrice",
             "CloseTime");
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

      WriteCSVHeaderIfNeeded(fileHandle);

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

                TradeOutcomeToString(m_memory.LastSnapshot.Outcome),
                DoubleToString(m_memory.LastSnapshot.FinalProfit, 2),
                DoubleToString(m_memory.LastSnapshot.FinalRR, 2),
                DoubleToString(m_memory.LastSnapshot.ClosePrice, _Digits),
                TimeToString(m_memory.LastSnapshot.CloseTime, TIME_DATE | TIME_SECONDS));

      FileClose(fileHandle);
   }

   void CaptureSnapshot()
   {
      if(m_memory == NULL)
         return;

    BuildTradeSnapshot();
    ValidateOutcomeSnapshot();
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
              " | Outcome=" + TradeOutcomeToString(m_memory.LastSnapshot.Outcome) +
              " | FinalRR=" + DoubleToString(m_memory.LastSnapshot.FinalRR, 2) +
              " | ClosePrice=" + DoubleToString(m_memory.LastSnapshot.ClosePrice, _Digits));

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
              " | Outcome=" + TradeOutcomeToString(m_memory.LastSnapshot.Outcome));

      MRH_Log("ML_DATASET_ENGINE", "DATASET_ROW", row);
   }

   void Update()
   {
      if(m_memory == NULL)
         return;

      CaptureSnapshot();

      MRH_Log("ML_DATASET_ENGINE", "UPDATE", "New bar update");
   }
};

#endif