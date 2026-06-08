#ifndef MRH_ML_DATASET_ENGINE_MQH
#define MRH_ML_DATASET_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

class CMLDatasetEngine
{
private:
   CSharedMemory* m_memory;
   string m_datasetFileName;
   int m_totalRows;
   int m_validRows;
   int m_skippedRows;
   int m_closedTradesCaptured;
   int m_winLabels;
   int m_lossLabels;
   int m_breakevenLabels;
   double m_winRate;
   double m_lossRate;
   double m_breakevenRate;
   double m_probabilityScore;
   double m_winProbability;
   double m_lossProbability;
   double m_datasetReadinessScore;
   string m_datasetReadinessClass;
   int m_goodWinLabels;
   int m_normalLossLabels;
   int m_strongSetupLabels;
   int m_averageSetupLabels;
   int m_weakSetupLabels;
   int m_highProbabilityCount;
   int m_mediumProbabilityCount;
   int m_lowProbabilityCount;
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
      
     m_totalRows = 0;
     m_validRows = 0;
     m_skippedRows = 0;
     m_closedTradesCaptured = 0;
     m_winLabels = 0;
     m_lossLabels = 0;
     m_breakevenLabels = 0;
     m_winRate = 0.0;
     m_lossRate = 0.0;
     m_breakevenRate = 0.0;
     m_probabilityScore = 0.0;
     m_winProbability = 0.0;
     m_lossProbability = 0.0;
     
     m_goodWinLabels = 0;
     m_normalLossLabels = 0;
     m_strongSetupLabels = 0;
     m_averageSetupLabels = 0;
     m_weakSetupLabels = 0;
     m_highProbabilityCount = 0;
     m_mediumProbabilityCount = 0;
     m_lowProbabilityCount = 0;
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
      row += "," + m_memory.Trade.TradeLabel;
      row += "," + m_memory.Trade.AdvancedLabel;
      row += "," + m_memory.Trade.LabelQuality;
      row += "," + m_memory.Trade.DynamicQualityLabel;
      row += "," + m_memory.Trade.ProbabilityClass;
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
         m_memory.LastSnapshot.TradeLabel =
      m_memory.Trade.TradeLabel;
      m_memory.LastSnapshot.AdvancedLabel =
      m_memory.Trade.AdvancedLabel;
      m_memory.LastSnapshot.LabelQuality =
      m_memory.Trade.LabelQuality;
      
      m_memory.LastSnapshot.DynamicQualityLabel =
      m_memory.Trade.DynamicQualityLabel;
      m_memory.LastSnapshot.ProbabilityClass =
      m_memory.Trade.ProbabilityClass;
      
      if(m_memory.Trade.TradeLabel == "WIN")
   m_winLabels++;

else if(m_memory.Trade.TradeLabel == "LOSS")
   m_lossLabels++;

else if(m_memory.Trade.TradeLabel == "BREAKEVEN")
   m_breakevenLabels++;
   
   if(m_memory.Trade.AdvancedLabel == "GOOD_WIN")
   m_goodWinLabels++;

if(m_memory.Trade.AdvancedLabel == "NORMAL_LOSS")
   m_normalLossLabels++;

if(m_memory.Trade.DynamicQualityLabel == "STRONG_SETUP")
   m_strongSetupLabels++;

if(m_memory.Trade.DynamicQualityLabel == "AVERAGE_SETUP")
   m_averageSetupLabels++;

if(m_memory.Trade.DynamicQualityLabel == "WEAK_SETUP")
   m_weakSetupLabels++;
   
   if(m_memory.Trade.ProbabilityClass == "HIGH_PROBABILITY")
   m_highProbabilityCount++;

else if(m_memory.Trade.ProbabilityClass == "MEDIUM_PROBABILITY")
   m_mediumProbabilityCount++;

else if(m_memory.Trade.ProbabilityClass == "LOW_PROBABILITY")
   m_lowProbabilityCount++;
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

void ValidateOutcomeConsistency()
{
   if(m_memory == NULL)
      return;

   if(m_memory.LastSnapshot.TradeState != TRADE_CLOSED)
      return;

   if(m_memory.LastSnapshot.Outcome == TRADE_OUTCOME_UNKNOWN)
   {
      MRH_Log("ML_DATASET_ENGINE",
              "OUTCOME_WARNING",
              "Trade is CLOSED but Outcome is UNKNOWN");
   }

   if(m_memory.LastSnapshot.CloseTime <= 0)
   {
      MRH_Log("ML_DATASET_ENGINE",
              "OUTCOME_WARNING",
              "Trade is CLOSED but CloseTime is missing");
   }

   if(m_memory.LastSnapshot.ClosePrice <= 0.0)
   {
      MRH_Log("ML_DATASET_ENGINE",
              "OUTCOME_WARNING",
              "Trade is CLOSED but ClosePrice is missing");
   }

   if(m_memory.LastSnapshot.FinalRR == 0.0 &&
      m_memory.LastSnapshot.Outcome != TRADE_OUTCOME_BREAKEVEN)
   {
      MRH_Log("ML_DATASET_ENGINE",
              "OUTCOME_WARNING",
              "FinalRR is zero but Outcome is not BREAKEVEN");
   }
   
   if(m_memory.LastSnapshot.TradeLabel == "UNLABELED" &&
   m_memory.LastSnapshot.Outcome != TRADE_OUTCOME_UNKNOWN)
{
   MRH_Log("ML_DATASET_ENGINE",
           "LABEL_WARNING",
           "Outcome exists but TradeLabel is UNLABELED");
}

if(m_memory.LastSnapshot.TradeLabel == "")
{
   MRH_Log("ML_DATASET_ENGINE",
           "LABEL_WARNING",
           "TradeLabel is empty");
}

}

bool IsDatasetRowComplete()
{
   if(m_memory == NULL)
      return false;

   if(m_memory.LastSnapshot.SnapshotTime <= 0)
      return false;

   if(m_memory.LastSnapshot.ExecutionGrade == "")
      return false;

   if(m_memory.LastSnapshot.ConfidenceLevel == "")
      return false;

   if(m_memory.LastSnapshot.RiskProfile == "")
      return false;

   if(m_memory.LastSnapshot.TradeState == TRADE_CLOSED)
   {
      if(m_memory.LastSnapshot.Outcome == TRADE_OUTCOME_UNKNOWN)
         return false;

      if(m_memory.LastSnapshot.CloseTime <= 0)
         return false;

      if(m_memory.LastSnapshot.ClosePrice <= 0.0)
         return false;
   }

   return true;
}
void LogDatasetSessionSummary()
{
   if(m_totalRows <= 0)
      return;

   if(m_totalRows % 10 != 0)
      return;

   MRH_Log("ML_DATASET_ENGINE",
           "DATASET_SESSION_SUMMARY",
           "TotalRows=" + IntegerToString(m_totalRows) +
           " | ValidRows=" + IntegerToString(m_validRows) +
           " | SkippedRows=" + IntegerToString(m_skippedRows) +
           " | ClosedTradesCaptured=" + IntegerToString(m_closedTradesCaptured));
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
             "CloseTime",
             "TradeLabel",
             "AdvancedLabel",
             "LabelQuality",
             "DynamicQualityLabel",
             "ProbabilityClass");
             
             
}
   void ExportSnapshotToCSV()
   {
      if(m_memory == NULL)
         return;
if(!IsDatasetRowComplete())
{
   m_skippedRows++;

   MRH_Log("ML_DATASET_ENGINE",
           "CSV_SKIP",
           "Dataset row skipped because required fields are incomplete"
           " | SkippedRows=" + IntegerToString(m_skippedRows));

   return;
}
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
                TimeToString(m_memory.LastSnapshot.CloseTime, TIME_DATE | TIME_SECONDS),
                m_memory.LastSnapshot.TradeLabel,
                m_memory.LastSnapshot.AdvancedLabel,
                m_memory.LastSnapshot.LabelQuality,
                m_memory.LastSnapshot.DynamicQualityLabel,
                m_memory.LastSnapshot.ProbabilityClass);
m_totalRows++;
m_validRows++;

if(m_memory.LastSnapshot.TradeState == TRADE_CLOSED)
   m_closedTradesCaptured++;
   
   if((m_winLabels + m_lossLabels + m_breakevenLabels) > m_totalRows)
{
   MRH_Log("ML_DATASET_ENGINE",
           "VALIDATION_WARNING",
           "Label count exceeds total rows");
}

if(m_totalRows > 0 &&
   (m_winLabels + m_lossLabels + m_breakevenLabels) == 0)
{
   MRH_Log("ML_DATASET_ENGINE",
           "VALIDATION_WARNING",
           "No labels captured yet");
}

if(m_totalRows > 0)
{
   m_winRate =
      (100.0 * m_winLabels) / m_totalRows;

   m_lossRate =
      (100.0 * m_lossLabels) / m_totalRows;

   m_breakevenRate =
      (100.0 * m_breakevenLabels) / m_totalRows;
}

if(m_totalRows > 0)
{
   m_winProbability = m_winRate;

   m_lossProbability = m_lossRate;

   m_probabilityScore =
      m_winProbability - m_lossProbability;
}
if(m_probabilityScore > 20.0)
   m_memory.Trade.ProbabilityClass = "HIGH_PROBABILITY";

else if(m_probabilityScore > 0.0)
   m_memory.Trade.ProbabilityClass = "MEDIUM_PROBABILITY";

else
   m_memory.Trade.ProbabilityClass = "LOW_PROBABILITY";

if(m_totalRows > 0)
{
   m_datasetReadinessScore = 0.0;
   m_datasetReadinessClass = "NOT_READY";
   m_datasetReadinessScore += MathMin(m_validRows * 2.0, 30.0);
   m_datasetReadinessScore += MathMin(m_closedTradesCaptured * 5.0, 25.0);
   m_datasetReadinessScore += MathMin((m_winLabels + m_lossLabels) * 3.0, 25.0);

   if(m_highProbabilityCount > 0 ||
      m_mediumProbabilityCount > 0 ||
      m_lowProbabilityCount > 0)
   {
      m_datasetReadinessScore += 20.0;
   }

if(m_datasetReadinessScore >= 80.0)
   m_datasetReadinessClass = "ML_READY";

else if(m_datasetReadinessScore >= 40.0)
   m_datasetReadinessClass = "PARTIALLY_READY";

else
   m_datasetReadinessClass = "NOT_READY";
   
   if(m_datasetReadinessScore > 100.0)
      m_datasetReadinessScore = 100.0;
}

MRH_Log("ML_DATASET_ENGINE",
        "DATASET_STATS",
        "TotalRows=" + IntegerToString(m_totalRows) +
        " | ValidRows=" + IntegerToString(m_validRows) +
        " | SkippedRows=" + IntegerToString(m_skippedRows) +
        " | ClosedTradesCaptured=" + IntegerToString(m_closedTradesCaptured) +
        " | WinLabels=" + IntegerToString(m_winLabels) +
        " | LossLabels=" + IntegerToString(m_lossLabels) +
        " | BreakevenLabels=" + IntegerToString(m_breakevenLabels) +
        " | WinRate=" + DoubleToString(m_winRate, 2) +
        " | LossRate=" + DoubleToString(m_lossRate, 2) +
        " | BreakevenRate=" + DoubleToString(m_breakevenRate, 2) +
        " | GoodWin=" + IntegerToString(m_goodWinLabels) +
        " | NormalLoss=" + IntegerToString(m_normalLossLabels) +
        " | StrongSetup=" + IntegerToString(m_strongSetupLabels) +
        " | AverageSetup=" + IntegerToString(m_averageSetupLabels) +
        " | WeakSetup=" + IntegerToString(m_weakSetupLabels) +
        " | WinProbability=" + DoubleToString(m_winProbability, 2) +
        " | LossProbability=" + DoubleToString(m_lossProbability, 2) +
        " | ProbabilityScore=" + DoubleToString(m_probabilityScore, 2) +
        " | HighProbability=" + IntegerToString(m_highProbabilityCount) +
        " | MediumProbability=" + IntegerToString(m_mediumProbabilityCount) +
        " | LowProbability=" + IntegerToString(m_lowProbabilityCount) +
        " | DatasetReadiness=" +
        DoubleToString(m_datasetReadinessScore, 2) +
        " | ReadinessClass=" +
        m_datasetReadinessClass);
        LogDatasetSessionSummary();
      FileClose(fileHandle);
   }

   void CaptureSnapshot()
   {
      if(m_memory == NULL)
         return;

    BuildTradeSnapshot();
    ValidateOutcomeSnapshot();
    ValidateOutcomeConsistency();
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