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
   double m_datasetQualityScore;
   string m_datasetQualityClass;
   bool m_mlReadyFlag;
   int m_mlFeatureCount;
   double m_datasetMaturityScore;
   string m_datasetMaturityClass;
   double m_datasetBalanceScore;
   string m_datasetBalanceClass;
   double m_datasetIntegrityScore;
   string m_datasetIntegrityClass;
   bool   m_datasetIntegrityApproved;
   double m_testReadinessScore;
   string m_testReadinessClass;
   bool   m_testReady;
   double m_winLossBalance;
   double m_probabilityBalance;
   double m_labelBalance;
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
     m_datasetReadinessScore = 0.0;
     m_datasetReadinessClass = "NOT_READY";

     m_datasetQualityScore = 0.0;
     m_datasetQualityClass = "POOR_DATASET";

     m_mlReadyFlag = false;
     m_mlFeatureCount = 0;

     m_datasetMaturityScore = 0.0;
     m_datasetMaturityClass = "EARLY_DATASET";
     m_datasetBalanceScore = 0.0;
     m_datasetBalanceClass = "UNBALANCED";
     m_datasetIntegrityScore = 0.0;
     m_datasetIntegrityClass = "NOT_CHECKED";
     m_datasetIntegrityApproved = false;
     m_testReadinessScore = 0.0;
     m_testReadinessClass = "NOT_READY";
     m_testReady = false;
     m_winLossBalance = 0.0;
     m_probabilityBalance = 0.0;
     m_labelBalance = 0.0;
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
      row += "," + m_memory.Execution.AuditReason;
      row += "," + IntegerToString((int)m_memory.Risk.RiskApproved);
      row += "," + DoubleToString(m_memory.Risk.RiskPercent, 2);
      row += "," + DoubleToString(m_memory.Risk.LotSize, 2);

      row += "," + IntegerToString((int)m_memory.Trade.State);
      row += "," + DoubleToString(m_memory.Trade.CurrentRR, 2);

      row += "," + TradeOutcomeToString(m_memory.Trade.Outcome);
      row += "," + IntegerToString((int)m_memory.Trade.LossCause);
      row += "," + DoubleToString(m_memory.Trade.FinalProfit, 2);
      row += "," + DoubleToString(m_memory.Trade.FinalRR, 2);
      row += "," + DoubleToString(m_memory.Trade.ClosePrice, _Digits);
      row += "," + TimeToString(m_memory.Trade.CloseTime, TIME_DATE | TIME_SECONDS);
      row += "," + m_memory.Trade.TradeLabel;
      row += "," + m_memory.Trade.AdvancedLabel;
      row += "," + m_memory.Trade.LabelQuality;
      row += "," + m_memory.Trade.DynamicQualityLabel;
row += "," + m_memory.Trade.ProbabilityClass;
row += "," + m_memory.LastSnapshot.OutcomeReadinessClass;
row += "," + m_memory.LastSnapshot.LabelReadinessClass;
row += "," + m_memory.LastSnapshot.OutcomeTrackingClass;
row += "," + m_memory.LastSnapshot.TradeQualityAuditClass;
row += "," + m_memory.LastSnapshot.TradeLifecycleClass;
      //--- STEP45.1 Dataset-Audit Integration
      row += "," + DoubleToString(m_memory.LastSnapshot.ArchitectureAuditScore, 2);
      row += "," + m_memory.LastSnapshot.ArchitectureAuditClass;
      row += "," + IntegerToString((int)m_memory.LastSnapshot.ArchitectureApproved);

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

      m_memory.LastSnapshot.LossCause =
         m_memory.Trade.LossCause;

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
     // STEP52 - Outcome Readiness Layer
if(m_memory.Trade.State == TRADE_NONE)
{
   m_memory.LastSnapshot.OutcomeReadinessClass = "NO_TRADE_CREATED";
}
else if(m_memory.Trade.State == TRADE_ACTIVE ||
        m_memory.Trade.State == TRADE_BE ||
        m_memory.Trade.State == TRADE_PARTIAL)
{
   m_memory.LastSnapshot.OutcomeReadinessClass = "WAITING_FOR_CLOSE";
}
else if(m_memory.Trade.State == TRADE_CLOSED &&
        m_memory.Trade.Outcome != TRADE_OUTCOME_UNKNOWN)
{
   m_memory.LastSnapshot.OutcomeReadinessClass = "READY_FOR_LABELING";
}
else
{
   m_memory.LastSnapshot.OutcomeReadinessClass = "INSUFFICIENT_DATA";
}
    
  // STEP55 - Label Readiness Layer
if(m_memory.Trade.State == TRADE_NONE)
{
   m_memory.LastSnapshot.LabelReadinessClass = "NO_LABEL_AVAILABLE";
}
else if(m_memory.Trade.State == TRADE_ACTIVE ||
        m_memory.Trade.State == TRADE_BE ||
        m_memory.Trade.State == TRADE_PARTIAL)
{
   m_memory.LastSnapshot.LabelReadinessClass = "WAITING_FOR_TRADE_CLOSE";
}
else if(m_memory.Trade.State == TRADE_CLOSED &&
        m_memory.Trade.TradeLabel != "UNLABELED")
{
   m_memory.LastSnapshot.LabelReadinessClass = "LABEL_READY";
}
else
{
   m_memory.LastSnapshot.LabelReadinessClass = "LABEL_INCONSISTENT";
}  
      
      // STEP56 - Outcome Tracking Foundation
if(m_memory.Trade.State == TRADE_NONE)
{
   m_memory.LastSnapshot.OutcomeTrackingClass = "NO_TRADE_TO_TRACK";
}
else if(m_memory.Trade.State == TRADE_ACTIVE ||
        m_memory.Trade.State == TRADE_BE ||
        m_memory.Trade.State == TRADE_PARTIAL)
{
   m_memory.LastSnapshot.OutcomeTrackingClass = "TRADE_IN_PROGRESS";
}
else if(m_memory.Trade.State == TRADE_CLOSED &&
        m_memory.Trade.Outcome != TRADE_OUTCOME_UNKNOWN)
{
   m_memory.LastSnapshot.OutcomeTrackingClass = "OUTCOME_FINALIZED";
}
else if(m_memory.Trade.State == TRADE_CLOSED &&
        m_memory.Trade.Outcome == TRADE_OUTCOME_UNKNOWN)
{
   m_memory.LastSnapshot.OutcomeTrackingClass = "CLOSED_OUTCOME_MISSING";
}
else
{
   m_memory.LastSnapshot.OutcomeTrackingClass = "TRACKING_REVIEW";
}
      
 // STEP57 - Trade Lifecycle Audit Layer
switch(m_memory.Trade.State)
{
   case TRADE_NONE:
      m_memory.LastSnapshot.TradeLifecycleClass = "NO_TRADE";
      break;

   case TRADE_ACTIVE:
      m_memory.LastSnapshot.TradeLifecycleClass = "TRADE_ACTIVE";
      break;

   case TRADE_BE:
      m_memory.LastSnapshot.TradeLifecycleClass = "TRADE_BE";
      break;

   case TRADE_PARTIAL:
      m_memory.LastSnapshot.TradeLifecycleClass = "TRADE_PARTIAL";
      break;

   case TRADE_CLOSED:
      m_memory.LastSnapshot.TradeLifecycleClass = "TRADE_CLOSED";
      break;

   default:
      m_memory.LastSnapshot.TradeLifecycleClass = "LIFECYCLE_UNKNOWN";
      break;
}     
  
  // STEP62 - Trade Quality Audit Layer
if(m_memory.Trade.State != TRADE_CLOSED)
{
   m_memory.LastSnapshot.TradeQualityAuditClass =
      "TRADE_NOT_FINISHED";
}
else if(m_memory.Trade.Outcome == TRADE_OUTCOME_WIN)
{
   m_memory.LastSnapshot.TradeQualityAuditClass =
      "QUALITY_WIN";
}
else if(m_memory.Trade.Outcome == TRADE_OUTCOME_LOSS)
{
   if(m_memory.Trade.ExitReason == EXIT_STOPLOSS)
   {
      m_memory.LastSnapshot.TradeQualityAuditClass =
         "LOSS_BY_STOPLOSS";
   }
   else
   {
      m_memory.LastSnapshot.TradeQualityAuditClass =
         "LOSS_OTHER_REASON";
   }
}
else if(m_memory.Trade.Outcome == TRADE_OUTCOME_BREAKEVEN)
{
   m_memory.LastSnapshot.TradeQualityAuditClass =
      "BREAKEVEN_TRADE";
}
else
{
   m_memory.LastSnapshot.TradeQualityAuditClass =
      "QUALITY_REVIEW";
}
      
      // STEP46.6 - Dataset Integrity Snapshot

      m_memory.LastSnapshot.DatasetIntegrityScore =
         m_datasetIntegrityScore;

      m_memory.LastSnapshot.DatasetIntegrityClass =
         m_datasetIntegrityClass;

      m_memory.LastSnapshot.DatasetIntegrityApproved =
         m_datasetIntegrityApproved;
      
      // STEP48.6 - Test Readiness Snapshot

      m_memory.LastSnapshot.TestReadinessScore =
         m_testReadinessScore;

      m_memory.LastSnapshot.TestReadinessClass =
         m_testReadinessClass;

      m_memory.LastSnapshot.TestReady =
         m_testReady;
      
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

// STEP45.3 - Architecture Audit Warning Log

if(m_memory.LastSnapshot.ArchitectureAuditClass == "")
{
   MRH_Log("ML_DATASET_ENGINE",
           "ARCHITECTURE_AUDIT_WARNING",
           "Architecture audit class is empty");
}

if(m_memory.LastSnapshot.ArchitectureAuditClass == "NOT_READY")
{
   MRH_Log("ML_DATASET_ENGINE",
           "ARCHITECTURE_AUDIT_WARNING",
           "Architecture audit is NOT_READY"
           " | AuditScore=" + DoubleToString(m_memory.LastSnapshot.ArchitectureAuditScore, 2));
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

// STEP45.2 - Architecture Audit Validation

if(m_memory.LastSnapshot.ArchitectureAuditClass == "")
   return false;

if(m_memory.LastSnapshot.ArchitectureAuditScore < 0.0)
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
             "AuditReason",
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
             "ProbabilityClass",
"OutcomeReadinessClass",
"LabelReadinessClass",
"OutcomeTrackingClass",
"TradeQualityAuditClass",
"TradeLifecycleClass",
"DatasetReadinessClass",
             "DatasetQualityClass",
             "MLReadyFlag",
             "MLFeatureCount",
             "DatasetMaturityScore",
             "DatasetMaturityClass",
             "DatasetBalanceScore",
             "DatasetBalanceClass",
             "WinLossBalance",
              "ProbabilityBalance",
              "LabelBalance",
              "ArchitectureAuditScore",
              "ArchitectureAuditClass",
              "ArchitectureApproved",
              "DatasetIntegrityScore",
              "DatasetIntegrityClass",
              "DatasetIntegrityApproved",
              "TestReadinessScore",
              "TestReadinessClass",
              "TestReady");
                       
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
                m_memory.Execution.AuditReason,

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
               m_memory.LastSnapshot.ProbabilityClass,
m_memory.LastSnapshot.OutcomeReadinessClass,
m_memory.LastSnapshot.LabelReadinessClass,
m_memory.LastSnapshot.OutcomeTrackingClass,
m_memory.LastSnapshot.TradeQualityAuditClass,
m_memory.LastSnapshot.TradeLifecycleClass,
m_datasetReadinessClass,
                m_datasetQualityClass,
                (m_mlReadyFlag ? "TRUE" : "FALSE"),
                IntegerToString(m_mlFeatureCount),
                DoubleToString(m_datasetMaturityScore, 2),
                m_datasetMaturityClass,
                DoubleToString(m_datasetBalanceScore, 2),
                m_datasetBalanceClass,
                DoubleToString(m_winLossBalance, 2),
                DoubleToString(m_probabilityBalance, 2),
                DoubleToString(m_labelBalance, 2),

                DoubleToString(m_memory.LastSnapshot.ArchitectureAuditScore, 2),
                m_memory.LastSnapshot.ArchitectureAuditClass,
                (m_memory.LastSnapshot.ArchitectureApproved ? "TRUE" : "FALSE"),

                DoubleToString(m_memory.LastSnapshot.DatasetIntegrityScore, 2),
                m_memory.LastSnapshot.DatasetIntegrityClass,
                (m_memory.LastSnapshot.DatasetIntegrityApproved ? "TRUE" : "FALSE"),

                DoubleToString(m_memory.LastSnapshot.TestReadinessScore, 2),
                m_memory.LastSnapshot.TestReadinessClass,
                (m_memory.LastSnapshot.TestReady ? "TRUE" : "FALSE"));
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
   m_datasetQualityScore = 0.0;
   m_datasetQualityClass = "POOR_DATASET";
   m_mlReadyFlag = false;
   m_mlFeatureCount = 0;
   
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
   m_datasetQualityScore = 0.0;

m_datasetQualityScore += m_datasetReadinessScore * 0.50;

m_datasetQualityScore +=
   MathMin(m_closedTradesCaptured * 2.0, 25.0);

m_datasetQualityScore +=
   MathMin((m_highProbabilityCount +
            m_mediumProbabilityCount +
            m_lowProbabilityCount), 25.0);

if(m_datasetQualityScore > 100.0)
   m_datasetQualityScore = 100.0;
   
   if(m_datasetQualityScore >= 80.0)
   m_datasetQualityClass = "HIGH_QUALITY_DATASET";

else if(m_datasetQualityScore >= 50.0)
   m_datasetQualityClass = "ACCEPTABLE_DATASET";

else
   m_datasetQualityClass = "POOR_DATASET";
   
   m_mlReadyFlag = false;

if(m_datasetReadinessClass == "ML_READY" &&
   m_datasetQualityClass == "HIGH_QUALITY_DATASET" &&
   m_closedTradesCaptured >= 50)
{
   m_mlReadyFlag = true;
}
m_mlFeatureCount = 0;

m_mlFeatureCount += 4; // Liquidity, OB, Permission, Confluence

m_mlFeatureCount += 3; // Grade, Confidence, RiskProfile

m_mlFeatureCount += 5; // Outcome, RR, Profit, Labels, Probability

m_mlFeatureCount += 3; // Readiness, Quality, MLReady

m_datasetMaturityScore = 0.0;

m_datasetMaturityScore +=
   MathMin(m_totalRows * 1.0, 40.0);

m_datasetMaturityScore +=
   MathMin(m_closedTradesCaptured * 2.0, 40.0);

m_datasetMaturityScore +=
   MathMin((m_winLabels + m_lossLabels) * 1.0, 20.0);

if(m_datasetMaturityScore > 100.0)
   m_datasetMaturityScore = 100.0;
   
   m_datasetMaturityClass = "EARLY_DATASET";
   

if(m_datasetMaturityScore >= 80.0)
   m_datasetMaturityClass = "MATURE_DATASET";

else if(m_datasetMaturityScore >= 40.0)
   m_datasetMaturityClass = "GROWING_DATASET";
   
   // STEP43.2 - Dataset Balance Score Calculation Foundation
m_winLossBalance = 0.0;
m_probabilityBalance = 0.0;
m_labelBalance = 0.0;
m_datasetBalanceScore = 0.0;
m_datasetBalanceClass = "UNBALANCED";

if((m_winLabels + m_lossLabels) > 0)
{
   double totalWinLossLabels = (double)(m_winLabels + m_lossLabels);
   double winRatio = (double)m_winLabels / totalWinLossLabels;
   double lossRatio = (double)m_lossLabels / totalWinLossLabels;

   m_winLossBalance = 100.0 - MathAbs(winRatio - lossRatio) * 100.0;
}

if((m_highProbabilityCount +
    m_mediumProbabilityCount +
    m_lowProbabilityCount) > 0)
{
   int totalProbabilityLabels =
      m_highProbabilityCount +
      m_mediumProbabilityCount +
      m_lowProbabilityCount;

   double highRatio =
      (double)m_highProbabilityCount / totalProbabilityLabels;

   double mediumRatio =
      (double)m_mediumProbabilityCount / totalProbabilityLabels;

   double lowRatio =
      (double)m_lowProbabilityCount / totalProbabilityLabels;

   double maxProbabilityRatio =
      MathMax(highRatio, MathMax(mediumRatio, lowRatio));

   m_probabilityBalance =
      100.0 - ((maxProbabilityRatio - (1.0 / 3.0)) * 150.0);
}

if((m_strongSetupLabels +
    m_averageSetupLabels +
    m_weakSetupLabels) > 0)
{
   int totalSetupLabels =
      m_strongSetupLabels +
      m_averageSetupLabels +
      m_weakSetupLabels;

   double strongRatio =
      (double)m_strongSetupLabels / totalSetupLabels;

   double averageRatio =
      (double)m_averageSetupLabels / totalSetupLabels;

   double weakRatio =
      (double)m_weakSetupLabels / totalSetupLabels;

   double maxSetupRatio =
      MathMax(strongRatio, MathMax(averageRatio, weakRatio));

   m_labelBalance =
      100.0 - ((maxSetupRatio - (1.0 / 3.0)) * 150.0);
}

if(m_winLossBalance < 0.0)
   m_winLossBalance = 0.0;

if(m_probabilityBalance < 0.0)
   m_probabilityBalance = 0.0;

if(m_labelBalance < 0.0)
   m_labelBalance = 0.0;

m_datasetBalanceScore =
   (m_winLossBalance * 0.40) +
   (m_probabilityBalance * 0.30) +
   (m_labelBalance * 0.30);

if(m_datasetBalanceScore >= 75.0)
   m_datasetBalanceClass = "BALANCED_DATASET";

else if(m_datasetBalanceScore >= 45.0)
   m_datasetBalanceClass = "PARTIALLY_BALANCED";

else
   m_datasetBalanceClass = "UNBALANCED";
   
   // STEP46.5 - Dataset Integrity Score

m_datasetIntegrityScore = 0.0;

if(IsDatasetRowComplete())
   m_datasetIntegrityScore += 50.0;

if(m_memory.LastSnapshot.ArchitectureAuditClass != "")
   m_datasetIntegrityScore += 25.0;

if(m_memory.LastSnapshot.ArchitectureAuditScore >= 0.0)
   m_datasetIntegrityScore += 25.0;

if(m_datasetIntegrityScore >= 90.0)
{
   m_datasetIntegrityClass = "INTEGRITY_OK";
   m_datasetIntegrityApproved = true;
}
else if(m_datasetIntegrityScore >= 50.0)
{
   m_datasetIntegrityClass = "INTEGRITY_REVIEW";
   m_datasetIntegrityApproved = false;
}

else
{
   m_datasetIntegrityClass = "INTEGRITY_FAILED";
   m_datasetIntegrityApproved = false;
}
  
  // STEP48.5 - Test Readiness Score

m_testReadinessScore = 0.0;

if(m_datasetReadinessClass == "ML_READY")
   m_testReadinessScore += 25.0;

if(m_datasetQualityClass == "HIGH_QUALITY_DATASET")
   m_testReadinessScore += 25.0;

if(m_datasetIntegrityApproved)
   m_testReadinessScore += 25.0;

if(m_memory.LastSnapshot.ArchitectureApproved)
   m_testReadinessScore += 25.0;

if(m_testReadinessScore >= 90.0)
{
   m_testReadinessClass = "TEST_READY";
   m_testReady = true;
}
else if(m_testReadinessScore >= 50.0)
{
   m_testReadinessClass = "TEST_REVIEW";
   m_testReady = false;
}
else
{
   m_testReadinessClass = "NOT_READY";
   m_testReady = false;
}
   
if(m_datasetReadinessClass == "" ||
   m_datasetQualityClass == "" ||
   m_mlFeatureCount <= 0)
{
   MRH_Log("ML_DATASET_ENGINE",
           "ML_PROFILE_WARNING",
           "ML profile fields are incomplete");
}

// STEP43.5 - Dataset Balance Validation Layer
if(m_datasetBalanceClass == "UNBALANCED" &&
   m_totalRows >= 20)
{
   MRH_Log("ML_DATASET_ENGINE",
           "BALANCE_WARNING",
           "Dataset is unbalanced"
           " | BalanceScore=" + DoubleToString(m_datasetBalanceScore, 2) +
           " | WinLossBalance=" + DoubleToString(m_winLossBalance, 2) +
           " | ProbabilityBalance=" + DoubleToString(m_probabilityBalance, 2) +
           " | LabelBalance=" + DoubleToString(m_labelBalance, 2));
}

if(m_winLossBalance < 30.0 &&
   (m_winLabels + m_lossLabels) >= 10)
{
   MRH_Log("ML_DATASET_ENGINE",
           "WIN_LOSS_BALANCE_WARNING",
           "Win/Loss labels are highly imbalanced"
           " | Wins=" + IntegerToString(m_winLabels) +
           " | Losses=" + IntegerToString(m_lossLabels) +
           " | WinLossBalance=" + DoubleToString(m_winLossBalance, 2));
}

if(m_probabilityBalance < 30.0 &&
   (m_highProbabilityCount +
    m_mediumProbabilityCount +
    m_lowProbabilityCount) >= 10)
{
   MRH_Log("ML_DATASET_ENGINE",
           "PROBABILITY_BALANCE_WARNING",
           "Probability classes are highly imbalanced"
           " | High=" + IntegerToString(m_highProbabilityCount) +
           " | Medium=" + IntegerToString(m_mediumProbabilityCount) +
           " | Low=" + IntegerToString(m_lowProbabilityCount) +
           " | ProbabilityBalance=" + DoubleToString(m_probabilityBalance, 2));
}

if(m_labelBalance < 30.0 &&
   (m_strongSetupLabels +
    m_averageSetupLabels +
    m_weakSetupLabels) >= 10)
{
   MRH_Log("ML_DATASET_ENGINE",
           "LABEL_BALANCE_WARNING",
           "Setup quality labels are highly imbalanced"
           " | Strong=" + IntegerToString(m_strongSetupLabels) +
           " | Average=" + IntegerToString(m_averageSetupLabels) +
           " | Weak=" + IntegerToString(m_weakSetupLabels) +
           " | LabelBalance=" + DoubleToString(m_labelBalance, 2));
}

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
        m_datasetReadinessClass +
        " | DatasetQuality=" +
        DoubleToString(m_datasetQualityScore, 2) +
        " | QualityClass=" +
        m_datasetQualityClass +
        " | MLReady=" +
        (m_mlReadyFlag ? "TRUE" : "FALSE") +
        " | MLFeatures=" +
        IntegerToString(m_mlFeatureCount) +
        " | DatasetMaturity=" +
        DoubleToString(m_datasetMaturityScore, 2) +
        " | MaturityClass=" +
        m_datasetMaturityClass +
        " | DatasetBalance=" +
        DoubleToString(m_datasetBalanceScore, 2) +
        " | BalanceClass=" +
        m_datasetBalanceClass +
        " | WinLossBalance=" +
        DoubleToString(m_winLossBalance, 2) +
        " | ProbabilityBalance=" +
        DoubleToString(m_probabilityBalance, 2) +
        " | LabelBalance=" +
        DoubleToString(m_labelBalance, 2));
        
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