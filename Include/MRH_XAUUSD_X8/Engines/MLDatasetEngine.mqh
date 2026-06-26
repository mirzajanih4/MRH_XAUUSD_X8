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
   // STEP92 - Validation Historical Persistence Internal State
int  m_validationPersistenceSamples;
int  m_validationApprovedPersistenceCount;
int  m_validationConfidencePersistenceCount;
int  m_validationMaturityPersistenceCount;

// STEP93 - Historical Trend Internal State
double m_previousValidationMaturityScore;

// STEP94 - Historical Consistency Internal State
bool m_previousValidationApproved;
bool m_previousValidationConfidenceReady;
int  m_validationConsistencyStableCount;
int  m_validationConsistencyChangeCount;

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
   double m_datasetCompletenessScore;
string m_datasetCompletenessClass;
bool   m_datasetComplete;

double m_datasetReliabilityScore;
string m_datasetReliabilityClass;
bool   m_datasetReliable;

double m_datasetStabilityScore;
string m_datasetStabilityClass;
bool   m_datasetStable;

double m_datasetHealthScore;
string m_datasetHealthClass;
bool   m_datasetHealthy;

double m_datasetConfidenceScore;
string m_datasetConfidenceClass;
bool   m_datasetConfidenceApproved;

double m_datasetApprovalScore;
string m_datasetApprovalClass;
bool   m_datasetApproved;

double m_datasetReleaseScore;
string m_datasetReleaseClass;
bool   m_datasetReleaseReady;

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
   
   // STEP74.8 - Persistent Validation Evidence Counters
int m_validationPassCount;
int m_validationWarningCount;
int m_validationFailCount;

// STEP75.3 - Persistent Validation Campaign Counters
int m_validationCampaignSampleCount;
int m_validationCampaignSessionCount;

// STEP80.3 - Persistent Validation Statistics Counters
int m_validationTotalSamples;
int m_validationApprovedSamples;
int m_validationBlockedSamples;

// STEP81.3 - Persistent Validation Event Tracking
int    m_validationEventCount;
string m_lastValidationDecisionClass;
bool   m_lastValidationApproved;
string m_lastValidationCertificationClass;

// STEP82.3 - Persistent Validation Event Quality Counters
int m_validationHighQualityEvents;
int m_validationMediumQualityEvents;
int m_validationLowQualityEvents;

// STEP83.3 - Persistent Validation Event Impact Counters
int m_validationCriticalEvents;
int m_validationMajorEvents;
int m_validationMinorEvents;

// STEP84.3 - Persistent Validation Stability Counters
int m_validationStateChanges;
int m_validationStableEvents;
int m_validationUnstableEvents;



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
     
     // STEP92 - Validation Historical Persistence Internal State
m_validationPersistenceSamples = 0;
m_validationApprovedPersistenceCount = 0;
m_validationConfidencePersistenceCount = 0;
m_validationMaturityPersistenceCount = 0;

// STEP93 - Historical Trend Internal State
m_previousValidationMaturityScore = 0.0;

// STEP94 - Historical Consistency Internal State
m_previousValidationApproved = false;
m_previousValidationConfidenceReady = false;
m_validationConsistencyStableCount = 0;
m_validationConsistencyChangeCount = 0;

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
     
     // STEP74.8 - Persistent Validation Evidence Counters
m_validationPassCount = 0;
m_validationWarningCount = 0;
m_validationFailCount = 0;

// STEP75.4 - Persistent Validation Campaign Counters
m_validationCampaignSampleCount = 0;
m_validationCampaignSessionCount = 0;

// STEP80.4 - Persistent Validation Statistics Counters
m_validationTotalSamples = 0;
m_validationApprovedSamples = 0;
m_validationBlockedSamples = 0;

// STEP81.4 - Persistent Validation Event Tracking
m_validationEventCount = 0;
m_lastValidationDecisionClass = "";
m_lastValidationApproved = false;
m_lastValidationCertificationClass = "";

// STEP82.4 - Persistent Validation Event Quality Counters
m_validationHighQualityEvents = 0;
m_validationMediumQualityEvents = 0;
m_validationLowQualityEvents = 0;

// STEP83.4 - Persistent Validation Event Impact Counters
m_validationCriticalEvents = 0;
m_validationMajorEvents = 0;
m_validationMinorEvents = 0;

// STEP84.4 - Persistent Validation Stability Counters
m_validationStateChanges = 0;
m_validationStableEvents = 0;
m_validationUnstableEvents = 0;

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
      row += "," + IntegerToString((int)m_memory.Trade.WinCause);
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

      m_memory.LastSnapshot.WinCause =
         m_memory.Trade.WinCause;

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
         
         CalculateDatasetCompleteness();
      
      // STEP66.1 - Dataset Completeness Snapshot

m_memory.LastSnapshot.DatasetCompletenessScore =
   m_datasetCompletenessScore;

m_memory.LastSnapshot.DatasetCompletenessClass =
   m_datasetCompletenessClass;

m_memory.LastSnapshot.DatasetComplete =
   m_datasetComplete;
      
      CalculateDatasetReliability();

// STEP67.1 - Dataset Reliability Snapshot

m_memory.LastSnapshot.DatasetReliabilityScore =
   m_datasetReliabilityScore;

m_memory.LastSnapshot.DatasetReliabilityClass =
   m_datasetReliabilityClass;

m_memory.LastSnapshot.DatasetReliable =
   m_datasetReliable;
      
     CalculateDatasetStability();

// STEP68.1 - Dataset Stability Snapshot

m_memory.LastSnapshot.DatasetStabilityScore =
   m_datasetStabilityScore;

m_memory.LastSnapshot.DatasetStabilityClass =
   m_datasetStabilityClass;

m_memory.LastSnapshot.DatasetStable =
   m_datasetStable; 
      
   CalculateDatasetHealth();

// STEP69.1 - Dataset Health Snapshot

m_memory.LastSnapshot.DatasetHealthScore =
   m_datasetHealthScore;

m_memory.LastSnapshot.DatasetHealthClass =
   m_datasetHealthClass;

m_memory.LastSnapshot.DatasetHealthy =
   m_datasetHealthy;
      
      CalculateDatasetConfidence();

// STEP70.1 - Dataset Confidence Snapshot

m_memory.LastSnapshot.DatasetConfidenceScore =
   m_datasetConfidenceScore;

m_memory.LastSnapshot.DatasetConfidenceClass =
   m_datasetConfidenceClass;

m_memory.LastSnapshot.DatasetConfidenceApproved =
   m_datasetConfidenceApproved;
      
      CalculateDatasetApproval();

// STEP71.1 - Dataset Approval Snapshot

m_memory.LastSnapshot.DatasetApprovalScore =
   m_datasetApprovalScore;

m_memory.LastSnapshot.DatasetApprovalClass =
   m_datasetApprovalClass;

m_memory.LastSnapshot.DatasetApproved =
   m_datasetApproved;
      
      CalculateDatasetReleaseReadiness();

// STEP72.1 - Dataset Release Readiness Snapshot

m_memory.LastSnapshot.DatasetReleaseScore =
   m_datasetReleaseScore;

m_memory.LastSnapshot.DatasetReleaseClass =
   m_datasetReleaseClass;

m_memory.LastSnapshot.DatasetReleaseReady =
   m_datasetReleaseReady;
   
   // STEP73.4 - Internal Validation Metrics Update
UpdateInternalValidationMetrics();

// STEP74.4 - Validation Evidence Update
UpdateValidationEvidence();
      
      // STEP75.6 - Validation Campaign Tracking Update
UpdateValidationCampaignTracking();

// STEP76.4 - Validation Performance Tracking Update
UpdateValidationPerformance();
      
      // STEP77.4 - Validation Certification Update
UpdateValidationCertification();
      
      // STEP78.4 - Validation Report Update
UpdateValidationReport();

// STEP79.4 - Validation Decision Update
UpdateValidationDecision();

// STEP80.6 - Validation Statistics Update
UpdateValidationEventTracking();

// STEP81.6 - Validation Event Tracking Update
UpdateValidationStatistics();

// STEP82.6 - Validation Event Quality Update
UpdateValidationEventQuality();
      
      // STEP83.6 - Validation Event Impact Update
UpdateValidationEventImpact();

// STEP84.6 - Validation Stability Update
UpdateValidationStability();

// STEP85.4 - Validation Maturity Update
UpdateValidationMaturity();

// STEP86.4 - Validation Trend Update
UpdateValidationTrend();
      
     // STEP87.4 - Validation Confidence Update
UpdateValidationConfidence(); 
      
      // STEP89.4 - Validation Analytics Update
UpdateValidationAnalytics();
      
      // STEP90.4 - Validation Dashboard Update
UpdateValidationDashboard();
      
      // STEP91.4 - Validation Consistency Update
UpdateValidationConsistency();
      
      // STEP92.6 - Validation Historical Persistence Update
UpdateValidationHistoricalPersistence();
      
      // STEP95.4 - Setup Reliability Update
UpdateSetupReliability();

// STEP96.4 - Setup Learning Readiness Update
UpdateSetupLearningReadiness();
      
      // STEP97.4 - Setup Probability Stability Update
UpdateSetupProbabilityStability();
      
      // STEP98.4 - Forward Test Readiness Update
UpdateForwardTestReadiness();
      
     // STEP99.4 - ML Dataset Certification Update
UpdateMLDatasetCertification(); 
      
      // STEP100.4 - Release Candidate Validation Update
UpdateReleaseCandidateValidation();

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
   
   // STEP73 - Internal Validation Metrics Foundation
m_memory.LastSnapshot.InternalValidationScore = 0.0;
m_memory.LastSnapshot.InternalValidationClass = "NOT_VALIDATED";
m_memory.LastSnapshot.InternalValidationPassed = false;
m_memory.LastSnapshot.InternalValidationReason = "VALIDATION_NOT_STARTED";
m_memory.LastSnapshot.InternalValidationSampleCount = 0;
m_memory.LastSnapshot.InternalValidationFailureCount = 0;

// STEP74 - Validation Evidence Collection Layer
m_memory.LastSnapshot.ValidationPassCount = 0;
m_memory.LastSnapshot.ValidationWarningCount = 0;
m_memory.LastSnapshot.ValidationFailCount = 0;
m_memory.LastSnapshot.ValidationEvidenceScore = 0.0;
m_memory.LastSnapshot.ValidationEvidenceClass = "NO_EVIDENCE";
m_memory.LastSnapshot.ValidationEvidenceReady = false;

// STEP75 - Validation Campaign Tracking Layer
m_memory.LastSnapshot.ValidationCampaignSampleCount = 0;
m_memory.LastSnapshot.ValidationCampaignSessionCount = 0;
m_memory.LastSnapshot.ValidationCampaignProgressScore = 0.0;
m_memory.LastSnapshot.ValidationCampaignStatusClass = "CAMPAIGN_NOT_STARTED";
m_memory.LastSnapshot.ValidationCampaignReady = false;

// STEP76 - Validation Performance Tracking Layer
m_memory.LastSnapshot.ValidationSuccessRate = 0.0;
m_memory.LastSnapshot.ValidationFailureRate = 0.0;
m_memory.LastSnapshot.ValidationPerformanceScore = 0.0;
m_memory.LastSnapshot.ValidationPerformanceClass = "NO_PERFORMANCE_DATA";
m_memory.LastSnapshot.ValidationPerformanceReady = false;

// STEP77 - Validation Certification Layer
m_memory.LastSnapshot.ValidationCertificationScore = 0.0;
m_memory.LastSnapshot.ValidationCertificationClass = "NOT_CERTIFIED";
m_memory.LastSnapshot.ValidationCertified = false;
m_memory.LastSnapshot.ValidationCertificationReason = "CERTIFICATION_NOT_STARTED";

// STEP78 - Validation Report Layer
m_memory.LastSnapshot.ValidationReportScore = 0.0;
m_memory.LastSnapshot.ValidationReportClass = "NO_REPORT";
m_memory.LastSnapshot.ValidationReportReady = false;
m_memory.LastSnapshot.ValidationReportSummary = "REPORT_NOT_GENERATED";

// STEP79 - Validation Decision Layer
m_memory.LastSnapshot.ValidationDecisionScore = 0.0;
m_memory.LastSnapshot.ValidationDecisionClass = "DECISION_NOT_MADE";
m_memory.LastSnapshot.ValidationApproved = false;
m_memory.LastSnapshot.ValidationDecisionReason = "DECISION_NOT_AVAILABLE";

// STEP80 - Validation Statistics Foundation
m_memory.LastSnapshot.ValidationTotalSamples = 0;
m_memory.LastSnapshot.ValidationApprovedSamples = 0;
m_memory.LastSnapshot.ValidationBlockedSamples = 0;
m_memory.LastSnapshot.ValidationApprovalRate = 0.0;
m_memory.LastSnapshot.ValidationBlockRate = 0.0;
m_memory.LastSnapshot.ValidationStatisticsClass = "NO_STATISTICS";
m_memory.LastSnapshot.ValidationStatisticsReady = false;

// STEP81 - Validation Event Tracking Foundation
m_memory.LastSnapshot.ValidationEventCount = 0;
m_memory.LastSnapshot.ValidationLastEventType = "NO_EVENT";
m_memory.LastSnapshot.ValidationNewEventDetected = false;

// STEP82 - Validation Event Quality Layer
m_memory.LastSnapshot.ValidationHighQualityEvents = 0;
m_memory.LastSnapshot.ValidationMediumQualityEvents = 0;
m_memory.LastSnapshot.ValidationLowQualityEvents = 0;
m_memory.LastSnapshot.ValidationEventQualityScore = 0.0;
m_memory.LastSnapshot.ValidationEventQualityClass = "NO_EVENT_QUALITY";
m_memory.LastSnapshot.ValidationEventQualityReady = false;

// STEP83 - Validation Event Impact Layer
m_memory.LastSnapshot.ValidationCriticalEvents = 0;
m_memory.LastSnapshot.ValidationMajorEvents = 0;
m_memory.LastSnapshot.ValidationMinorEvents = 0;
m_memory.LastSnapshot.ValidationEventImpactScore = 0.0;
m_memory.LastSnapshot.ValidationEventImpactClass = "NO_EVENT_IMPACT";
m_memory.LastSnapshot.ValidationEventImpactReady = false;

// STEP84 - Validation Stability Layer
m_memory.LastSnapshot.ValidationStateChanges = 0;
m_memory.LastSnapshot.ValidationStableEvents = 0;
m_memory.LastSnapshot.ValidationUnstableEvents = 0;
m_memory.LastSnapshot.ValidationStabilityScore = 0.0;
m_memory.LastSnapshot.ValidationStabilityClass = "NO_STABILITY_DATA";
m_memory.LastSnapshot.ValidationStabilityReady = false;

// STEP85 - Validation Maturity Layer
m_memory.LastSnapshot.ValidationMaturityScore = 0.0;
m_memory.LastSnapshot.ValidationMaturityClass = "NOT_MATURE";
m_memory.LastSnapshot.ValidationMature = false;
m_memory.LastSnapshot.ValidationMaturityReason = "MATURITY_NOT_EVALUATED";

// STEP86 - Validation Trend Layer
m_memory.LastSnapshot.ValidationTrendScore = 0.0;
m_memory.LastSnapshot.ValidationTrendClass = "NO_TREND";
m_memory.LastSnapshot.ValidationTrendImproving = false;

// STEP87 - Validation Confidence Layer
m_memory.LastSnapshot.ValidationConfidenceScore = 0.0;
m_memory.LastSnapshot.ValidationConfidenceClass = "NO_CONFIDENCE";
m_memory.LastSnapshot.ValidationConfidenceReady = false;
m_memory.LastSnapshot.ValidationConfidenceReason = "CONFIDENCE_NOT_EVALUATED";

// STEP89 - Validation Analytics Layer
m_memory.LastSnapshot.ValidationAnalyticsScore = 0.0;
m_memory.LastSnapshot.ValidationAnalyticsClass = "NO_ANALYTICS";
m_memory.LastSnapshot.ValidationAnalyticsReady = false;
m_memory.LastSnapshot.ValidationAnalyticsSummary = "ANALYTICS_NOT_EVALUATED";

// STEP90 - Validation Dashboard Layer
m_memory.LastSnapshot.ValidationDashboardScore = 0.0;
m_memory.LastSnapshot.ValidationDashboardClass = "NO_DASHBOARD";
m_memory.LastSnapshot.ValidationDashboardReady = false;
m_memory.LastSnapshot.ValidationDashboardStatus = "DASHBOARD_NOT_EVALUATED";

// STEP91 - Validation Consistency Layer
m_memory.LastSnapshot.ValidationConsistencyScore = 0.0;
m_memory.LastSnapshot.ValidationConsistencyClass = "NO_CONSISTENCY";
m_memory.LastSnapshot.ValidationConsistencyReady = false;
m_memory.LastSnapshot.ValidationConsistencyReason = "CONSISTENCY_NOT_EVALUATED";

// STEP92 - Validation Historical Persistence Layer
m_memory.LastSnapshot.ValidationPersistenceSamples = 0;
m_memory.LastSnapshot.ValidationApprovedPersistenceCount = 0;
m_memory.LastSnapshot.ValidationConfidencePersistenceCount = 0;
m_memory.LastSnapshot.ValidationMaturityPersistenceCount = 0;
m_memory.LastSnapshot.ValidationPersistenceScore = 0.0;
m_memory.LastSnapshot.ValidationPersistenceClass = "NO_PERSISTENCE";
m_memory.LastSnapshot.ValidationPersistenceReady = false;
m_memory.LastSnapshot.ValidationPersistenceReason = "PERSISTENCE_NOT_EVALUATED";

// STEP95 - Setup Reliability Layer
m_memory.LastSnapshot.SetupReliabilityScore = 0.0;
m_memory.LastSnapshot.SetupReliabilityClass = "NO_SETUP_RELIABILITY";
m_memory.LastSnapshot.SetupReliable = false;
m_memory.LastSnapshot.SetupReliabilityReason = "SETUP_RELIABILITY_NOT_EVALUATED";

// STEP96 - Setup Learning Readiness Layer
m_memory.LastSnapshot.SetupLearningReadinessScore = 0.0;
m_memory.LastSnapshot.SetupLearningReadinessClass = "NOT_READY_FOR_LEARNING";
m_memory.LastSnapshot.SetupLearningReady = false;
m_memory.LastSnapshot.SetupLearningReadinessReason = "SETUP_LEARNING_NOT_EVALUATED";

// STEP97 - Setup Probability Stability Layer
m_memory.LastSnapshot.SetupProbabilityStabilityScore = 0.0;
m_memory.LastSnapshot.SetupProbabilityStabilityClass = "NO_PROBABILITY_STABILITY";
m_memory.LastSnapshot.SetupProbabilityStable = false;
m_memory.LastSnapshot.SetupProbabilityStabilityReason = "PROBABILITY_STABILITY_NOT_EVALUATED";

// STEP98 - Forward Test Readiness Layer
m_memory.LastSnapshot.ForwardTestReadinessScore = 0.0;
m_memory.LastSnapshot.ForwardTestReadinessClass = "NOT_READY_FOR_FORWARD_TEST";
m_memory.LastSnapshot.ForwardTestReady = false;
m_memory.LastSnapshot.ForwardTestReadinessReason = "FORWARD_TEST_NOT_EVALUATED";

// STEP99 - ML Dataset Certification Layer
m_memory.LastSnapshot.MLDatasetCertificationScore = 0.0;
m_memory.LastSnapshot.MLDatasetCertificationClass = "NOT_CERTIFIED";
m_memory.LastSnapshot.MLDatasetCertified = false;
m_memory.LastSnapshot.MLDatasetCertificationReason = "ML_DATASET_NOT_EVALUATED";

// STEP100 - Release Candidate Validation Layer
m_memory.LastSnapshot.ReleaseCandidateScore = 0.0;
m_memory.LastSnapshot.ReleaseCandidateClass = "NOT_READY_FOR_ML_PHASE";
m_memory.LastSnapshot.ReleaseCandidateReady = false;
m_memory.LastSnapshot.ReleaseCandidateReason = "RELEASE_CANDIDATE_NOT_EVALUATED";

   }
   
   // STEP73.3 - Internal Validation Metrics Calculation
void UpdateInternalValidationMetrics()
{
   if(m_memory == NULL)
      return;

   int score = 0;
   int failures = 0;
   string reason = "";

   if(m_memory.LastSnapshot.SnapshotTime > 0)
      score += 20;
   else
   {
      failures++;
      reason += "MISSING_SNAPSHOT_TIME;";
   }

   if(m_memory.LastSnapshot.DatasetIntegrityApproved)
      score += 20;
   else
   {
      failures++;
      reason += "DATASET_INTEGRITY_NOT_APPROVED;";
   }

   if(m_memory.LastSnapshot.ArchitectureApproved)
      score += 20;
   else
   {
      failures++;
      reason += "ARCHITECTURE_NOT_APPROVED;";
   }

   if(m_memory.LastSnapshot.DatasetApproved)
      score += 20;
   else
   {
      failures++;
      reason += "DATASET_NOT_APPROVED;";
   }

   if(m_memory.LastSnapshot.DatasetReleaseReady)
      score += 20;
   else
   {
      failures++;
      reason += "DATASET_RELEASE_NOT_READY;";
   }

   m_memory.LastSnapshot.InternalValidationScore = score;
   m_memory.LastSnapshot.InternalValidationFailureCount = failures;
   m_memory.LastSnapshot.InternalValidationSampleCount++;

   if(score >= 80 && failures == 0)
   {
      m_memory.LastSnapshot.InternalValidationClass = "VALIDATION_READY";
      m_memory.LastSnapshot.InternalValidationPassed = true;
      m_memory.LastSnapshot.InternalValidationReason = "PASSED";
   }
   else if(score >= 60)
   {
      m_memory.LastSnapshot.InternalValidationClass = "VALIDATION_WARNING";
      m_memory.LastSnapshot.InternalValidationPassed = false;
      m_memory.LastSnapshot.InternalValidationReason = reason;
   }
   else
   {
      m_memory.LastSnapshot.InternalValidationClass = "VALIDATION_FAILED";
      m_memory.LastSnapshot.InternalValidationPassed = false;
      m_memory.LastSnapshot.InternalValidationReason = reason;
   }
   PrintFormat(
   "MRH_X8 STEP73 | InternalValidationScore=%.2f | Class=%s | Passed=%s | Reason=%s | Samples=%d | Failures=%d",
   m_memory.LastSnapshot.InternalValidationScore,
   m_memory.LastSnapshot.InternalValidationClass,
   (m_memory.LastSnapshot.InternalValidationPassed ? "TRUE" : "FALSE"),
   m_memory.LastSnapshot.InternalValidationReason,
   m_memory.LastSnapshot.InternalValidationSampleCount,
   m_memory.LastSnapshot.InternalValidationFailureCount
   
   
);
}
   
   // STEP74.3 - Validation Evidence Collection Calculation
void UpdateValidationEvidence()
{
   if(m_memory == NULL)
      return;

   if(m_memory.LastSnapshot.InternalValidationClass == "VALIDATION_READY")
      m_validationPassCount++;

   else if(m_memory.LastSnapshot.InternalValidationClass == "VALIDATION_WARNING")
      m_validationWarningCount++;

   else if(m_memory.LastSnapshot.InternalValidationClass == "VALIDATION_FAILED")
      m_validationFailCount++;
      
      m_memory.LastSnapshot.ValidationPassCount =
   m_validationPassCount;

m_memory.LastSnapshot.ValidationWarningCount =
   m_validationWarningCount;

m_memory.LastSnapshot.ValidationFailCount =
   m_validationFailCount;

   int totalEvidence =
      m_memory.LastSnapshot.ValidationPassCount +
      m_memory.LastSnapshot.ValidationWarningCount +
      m_memory.LastSnapshot.ValidationFailCount;

   if(totalEvidence <= 0)
   {
      m_memory.LastSnapshot.ValidationEvidenceScore = 0.0;
      m_memory.LastSnapshot.ValidationEvidenceClass = "NO_EVIDENCE";
      m_memory.LastSnapshot.ValidationEvidenceReady = false;
      return;
   }

   m_memory.LastSnapshot.ValidationEvidenceScore =
      ((double)m_memory.LastSnapshot.ValidationPassCount / (double)totalEvidence) * 100.0;

   if(totalEvidence < 5)
   {
      m_memory.LastSnapshot.ValidationEvidenceClass = "INSUFFICIENT_EVIDENCE";
      m_memory.LastSnapshot.ValidationEvidenceReady = false;
   }
   else if(m_memory.LastSnapshot.ValidationEvidenceScore >= 80.0)
   {
      m_memory.LastSnapshot.ValidationEvidenceClass = "STRONG_EVIDENCE";
      m_memory.LastSnapshot.ValidationEvidenceReady = true;
   }
   else if(m_memory.LastSnapshot.ValidationEvidenceScore >= 60.0)
   {
      m_memory.LastSnapshot.ValidationEvidenceClass = "MODERATE_EVIDENCE";
      m_memory.LastSnapshot.ValidationEvidenceReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationEvidenceClass = "WEAK_EVIDENCE";
      m_memory.LastSnapshot.ValidationEvidenceReady = false;
   }
   
   PrintFormat(
   "MRH_X8 STEP74 | Pass=%d | Warning=%d | Fail=%d | EvidenceScore=%.2f | Class=%s | Ready=%s",
   m_memory.LastSnapshot.ValidationPassCount,
   m_memory.LastSnapshot.ValidationWarningCount,
   m_memory.LastSnapshot.ValidationFailCount,
   m_memory.LastSnapshot.ValidationEvidenceScore,
   m_memory.LastSnapshot.ValidationEvidenceClass,
   (m_memory.LastSnapshot.ValidationEvidenceReady ? "TRUE" : "FALSE")
);

}
   
   // STEP75.5 - Validation Campaign Tracking Calculation
void UpdateValidationCampaignTracking()
{
   if(m_memory == NULL)
      return;

   m_validationCampaignSampleCount++;

   if(m_validationCampaignSampleCount == 1)
      m_validationCampaignSessionCount++;

   m_memory.LastSnapshot.ValidationCampaignSampleCount =
      m_validationCampaignSampleCount;

   m_memory.LastSnapshot.ValidationCampaignSessionCount =
      m_validationCampaignSessionCount;

   double targetSamples = 20.0;

   m_memory.LastSnapshot.ValidationCampaignProgressScore =
      MathMin(((double)m_validationCampaignSampleCount / targetSamples) * 100.0, 100.0);

   if(m_validationCampaignSampleCount <= 0)
   {
      m_memory.LastSnapshot.ValidationCampaignStatusClass = "CAMPAIGN_NOT_STARTED";
      m_memory.LastSnapshot.ValidationCampaignReady = false;
   }
   else if(m_validationCampaignSampleCount < 5)
   {
      m_memory.LastSnapshot.ValidationCampaignStatusClass = "CAMPAIGN_STARTED";
      m_memory.LastSnapshot.ValidationCampaignReady = false;
   }
   else if(m_validationCampaignSampleCount < 20)
   {
      m_memory.LastSnapshot.ValidationCampaignStatusClass = "CAMPAIGN_IN_PROGRESS";
      m_memory.LastSnapshot.ValidationCampaignReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationCampaignStatusClass = "CAMPAIGN_COMPLETE";
      m_memory.LastSnapshot.ValidationCampaignReady = true;
   }
   
   PrintFormat(
   "MRH_X8 STEP75 | Samples=%d | Sessions=%d | Progress=%.2f | Status=%s | Ready=%s",
   m_memory.LastSnapshot.ValidationCampaignSampleCount,
   m_memory.LastSnapshot.ValidationCampaignSessionCount,
   m_memory.LastSnapshot.ValidationCampaignProgressScore,
   m_memory.LastSnapshot.ValidationCampaignStatusClass,
   (m_memory.LastSnapshot.ValidationCampaignReady ? "TRUE" : "FALSE")
);
}
   
   // STEP76.3 - Validation Performance Tracking Calculation
void UpdateValidationPerformance()
{
   if(m_memory == NULL)
      return;

   int totalEvidence =
      m_memory.LastSnapshot.ValidationPassCount +
      m_memory.LastSnapshot.ValidationWarningCount +
      m_memory.LastSnapshot.ValidationFailCount;

   if(totalEvidence <= 0)
   {
      m_memory.LastSnapshot.ValidationSuccessRate = 0.0;
      m_memory.LastSnapshot.ValidationFailureRate = 0.0;
      m_memory.LastSnapshot.ValidationPerformanceScore = 0.0;
      m_memory.LastSnapshot.ValidationPerformanceClass = "NO_PERFORMANCE_DATA";
      m_memory.LastSnapshot.ValidationPerformanceReady = false;
      return;
   }

   m_memory.LastSnapshot.ValidationSuccessRate =
      ((double)m_memory.LastSnapshot.ValidationPassCount / (double)totalEvidence) * 100.0;

   m_memory.LastSnapshot.ValidationFailureRate =
      ((double)m_memory.LastSnapshot.ValidationFailCount / (double)totalEvidence) * 100.0;

   m_memory.LastSnapshot.ValidationPerformanceScore =
      m_memory.LastSnapshot.ValidationSuccessRate;

   if(totalEvidence < 5)
   {
      m_memory.LastSnapshot.ValidationPerformanceClass = "INSUFFICIENT_PERFORMANCE_DATA";
      m_memory.LastSnapshot.ValidationPerformanceReady = false;
   }
   else if(m_memory.LastSnapshot.ValidationPerformanceScore >= 80.0)
   {
      m_memory.LastSnapshot.ValidationPerformanceClass = "STRONG_VALIDATION_PERFORMANCE";
      m_memory.LastSnapshot.ValidationPerformanceReady = true;
   }
   else if(m_memory.LastSnapshot.ValidationPerformanceScore >= 60.0)
   {
      m_memory.LastSnapshot.ValidationPerformanceClass = "MODERATE_VALIDATION_PERFORMANCE";
      m_memory.LastSnapshot.ValidationPerformanceReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationPerformanceClass = "WEAK_VALIDATION_PERFORMANCE";
      m_memory.LastSnapshot.ValidationPerformanceReady = false;
   }
   
   PrintFormat(
   "MRH_X8 STEP76 | SuccessRate=%.2f | FailureRate=%.2f | PerformanceScore=%.2f | Class=%s | Ready=%s",
   m_memory.LastSnapshot.ValidationSuccessRate,
   m_memory.LastSnapshot.ValidationFailureRate,
   m_memory.LastSnapshot.ValidationPerformanceScore,
   m_memory.LastSnapshot.ValidationPerformanceClass,
   (m_memory.LastSnapshot.ValidationPerformanceReady ? "TRUE" : "FALSE")
);
   
}
   
   // STEP77.3 - Validation Certification Calculation
void UpdateValidationCertification()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.InternalValidationPassed)
      score += 25.0;
   else
      reason += "INTERNAL_VALIDATION_NOT_PASSED;";

   if(m_memory.LastSnapshot.ValidationEvidenceReady)
      score += 25.0;
   else
      reason += "EVIDENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationCampaignReady)
      score += 25.0;
   else
      reason += "CAMPAIGN_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationPerformanceReady)
      score += 25.0;
   else
      reason += "PERFORMANCE_NOT_READY;";

   m_memory.LastSnapshot.ValidationCertificationScore = score;

   if(score >= 100.0)
   {
      m_memory.LastSnapshot.ValidationCertificationClass = "VALIDATION_CERTIFIED";
      m_memory.LastSnapshot.ValidationCertified = true;
      m_memory.LastSnapshot.ValidationCertificationReason = "CERTIFIED";
   }
   else if(score >= 75.0)
   {
      m_memory.LastSnapshot.ValidationCertificationClass = "CERTIFICATION_PENDING";
      m_memory.LastSnapshot.ValidationCertified = false;
      m_memory.LastSnapshot.ValidationCertificationReason = reason;
   }
   else if(score >= 50.0)
   {
      m_memory.LastSnapshot.ValidationCertificationClass = "CERTIFICATION_WEAK";
      m_memory.LastSnapshot.ValidationCertified = false;
      m_memory.LastSnapshot.ValidationCertificationReason = reason;
   }
   else
   {
      m_memory.LastSnapshot.ValidationCertificationClass = "NOT_CERTIFIED";
      m_memory.LastSnapshot.ValidationCertified = false;
      m_memory.LastSnapshot.ValidationCertificationReason = reason;
   }
   
   PrintFormat(
   "MRH_X8 STEP77 | CertificationScore=%.2f | Class=%s | Certified=%s | Reason=%s",
   m_memory.LastSnapshot.ValidationCertificationScore,
   m_memory.LastSnapshot.ValidationCertificationClass,
   (m_memory.LastSnapshot.ValidationCertified ? "TRUE" : "FALSE"),
   m_memory.LastSnapshot.ValidationCertificationReason
);
}
   
   // STEP78.3 - Validation Report Calculation
void UpdateValidationReport()
{
   if(m_memory == NULL)
      return;

   m_memory.LastSnapshot.ValidationReportScore =
      m_memory.LastSnapshot.ValidationCertificationScore;

   if(m_memory.LastSnapshot.ValidationCertified)
   {
      m_memory.LastSnapshot.ValidationReportClass = "VALIDATION_REPORT_APPROVED";
      m_memory.LastSnapshot.ValidationReportReady = true;
      m_memory.LastSnapshot.ValidationReportSummary =
         "VALIDATION_FRAMEWORK_CERTIFIED";
   }
   else if(m_memory.LastSnapshot.ValidationCertificationScore >= 75.0)
   {
      m_memory.LastSnapshot.ValidationReportClass = "VALIDATION_REPORT_PENDING";
      m_memory.LastSnapshot.ValidationReportReady = false;
      m_memory.LastSnapshot.ValidationReportSummary =
         m_memory.LastSnapshot.ValidationCertificationReason;
   }
   else
   {
      m_memory.LastSnapshot.ValidationReportClass = "VALIDATION_REPORT_INCOMPLETE";
      m_memory.LastSnapshot.ValidationReportReady = false;
      m_memory.LastSnapshot.ValidationReportSummary =
         m_memory.LastSnapshot.ValidationCertificationReason;
   }
   
   PrintFormat(
   "MRH_X8 STEP78 | ReportScore=%.2f | Class=%s | Ready=%s | Summary=%s",
   m_memory.LastSnapshot.ValidationReportScore,
   m_memory.LastSnapshot.ValidationReportClass,
   (m_memory.LastSnapshot.ValidationReportReady ? "TRUE" : "FALSE"),
   m_memory.LastSnapshot.ValidationReportSummary
);
   
}

// STEP79.3 - Validation Decision Calculation
void UpdateValidationDecision()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.InternalValidationPassed)
      score += 20.0;
   else
      reason += "INTERNAL_VALIDATION_BLOCKED;";

   if(m_memory.LastSnapshot.ValidationEvidenceReady)
      score += 20.0;
   else
      reason += "EVIDENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationCampaignReady)
      score += 20.0;
   else
      reason += "CAMPAIGN_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationPerformanceReady)
      score += 20.0;
   else
      reason += "PERFORMANCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationReportReady)
      score += 20.0;
   else
      reason += "REPORT_NOT_READY;";

// STEP88 - Validation Decision Enhancement Layer
if(m_memory.LastSnapshot.ValidationMature)
   score += 10.0;
else
   reason += "VALIDATION_NOT_MATURE;";

if(m_memory.LastSnapshot.ValidationConfidenceReady)
   score += 10.0;
else
   reason += "CONFIDENCE_NOT_READY;";

if(m_memory.LastSnapshot.ValidationTrendImproving)
   score += 5.0;
else
   reason += "TREND_NOT_IMPROVING;";

   m_memory.LastSnapshot.ValidationDecisionScore = score;

   if(score >= 115.0)
   {
      m_memory.LastSnapshot.ValidationDecisionClass = "INTERNAL_MT5_TEST_APPROVED";
      m_memory.LastSnapshot.ValidationApproved = true;
      m_memory.LastSnapshot.ValidationDecisionReason = "VALIDATION_APPROVED";
   }
   else if(score >= 75.0)
   {
      m_memory.LastSnapshot.ValidationDecisionClass = "INTERNAL_MT5_TEST_PENDING";
      m_memory.LastSnapshot.ValidationApproved = false;
      m_memory.LastSnapshot.ValidationDecisionReason = reason;
   }
   else
   {
      m_memory.LastSnapshot.ValidationDecisionClass = "INTERNAL_MT5_TEST_BLOCKED";
      m_memory.LastSnapshot.ValidationApproved = false;
      m_memory.LastSnapshot.ValidationDecisionReason = reason;
   }
   
   PrintFormat(
   "MRH_X8 STEP79 | DecisionScore=%.2f | Class=%s | Approved=%s | Reason=%s",
   m_memory.LastSnapshot.ValidationDecisionScore,
   m_memory.LastSnapshot.ValidationDecisionClass,
   (m_memory.LastSnapshot.ValidationApproved ? "TRUE" : "FALSE"),
   m_memory.LastSnapshot.ValidationDecisionReason
);

}
   
   // STEP80.5 - Validation Statistics Foundation Calculation
void UpdateValidationStatistics()
{
   if(m_memory == NULL)
      return;
      
      if(!m_memory.LastSnapshot.ValidationNewEventDetected)
   return;

   m_validationTotalSamples++;

   if(m_memory.LastSnapshot.ValidationApproved)
      m_validationApprovedSamples++;
   else
      m_validationBlockedSamples++;

   m_memory.LastSnapshot.ValidationTotalSamples =
      m_validationTotalSamples;

   m_memory.LastSnapshot.ValidationApprovedSamples =
      m_validationApprovedSamples;

   m_memory.LastSnapshot.ValidationBlockedSamples =
      m_validationBlockedSamples;

   if(m_validationTotalSamples <= 0)
   {
      m_memory.LastSnapshot.ValidationApprovalRate = 0.0;
      m_memory.LastSnapshot.ValidationBlockRate = 0.0;
      m_memory.LastSnapshot.ValidationStatisticsClass = "NO_STATISTICS";
      m_memory.LastSnapshot.ValidationStatisticsReady = false;
      return;
   }

   m_memory.LastSnapshot.ValidationApprovalRate =
      ((double)m_validationApprovedSamples / (double)m_validationTotalSamples) * 100.0;

   m_memory.LastSnapshot.ValidationBlockRate =
      ((double)m_validationBlockedSamples / (double)m_validationTotalSamples) * 100.0;

   if(m_validationTotalSamples < 20)
   {
      m_memory.LastSnapshot.ValidationStatisticsClass = "INSUFFICIENT_SAMPLES";
      m_memory.LastSnapshot.ValidationStatisticsReady = false;
   }
   else if(m_memory.LastSnapshot.ValidationApprovalRate >= 80.0)
   {
      m_memory.LastSnapshot.ValidationStatisticsClass = "STRONG_STATISTICS";
      m_memory.LastSnapshot.ValidationStatisticsReady = true;
   }
   else if(m_memory.LastSnapshot.ValidationApprovalRate >= 60.0)
   {
      m_memory.LastSnapshot.ValidationStatisticsClass = "MODERATE_STATISTICS";
      m_memory.LastSnapshot.ValidationStatisticsReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationStatisticsClass = "WEAK_STATISTICS";
      m_memory.LastSnapshot.ValidationStatisticsReady = false;
   }
   
   PrintFormat(
   "MRH_X8 STEP80 | Total=%d | Approved=%d | Blocked=%d | ApprovalRate=%.2f | BlockRate=%.2f | Class=%s | Ready=%s",
   m_memory.LastSnapshot.ValidationTotalSamples,
   m_memory.LastSnapshot.ValidationApprovedSamples,
   m_memory.LastSnapshot.ValidationBlockedSamples,
   m_memory.LastSnapshot.ValidationApprovalRate,
   m_memory.LastSnapshot.ValidationBlockRate,
   m_memory.LastSnapshot.ValidationStatisticsClass,
   (m_memory.LastSnapshot.ValidationStatisticsReady ? "TRUE" : "FALSE")
);
   
}

// STEP81.5 - Validation Event Tracking Foundation
void UpdateValidationEventTracking()
{
   if(m_memory == NULL)
      return;

   bool newEvent = false;
   string eventType = "NO_EVENT";

   if(m_lastValidationDecisionClass !=
      m_memory.LastSnapshot.ValidationDecisionClass)
   {
      newEvent = true;
      eventType = "DECISION_CHANGED";
   }

   if(m_lastValidationApproved !=
      m_memory.LastSnapshot.ValidationApproved)
   {
      newEvent = true;
      eventType = "APPROVAL_CHANGED";
   }

   if(m_lastValidationCertificationClass !=
      m_memory.LastSnapshot.ValidationCertificationClass)
   {
      newEvent = true;
      eventType = "CERTIFICATION_CHANGED";
   }

   if(newEvent)
      m_validationEventCount++;

   m_memory.LastSnapshot.ValidationEventCount =
      m_validationEventCount;

   m_memory.LastSnapshot.ValidationLastEventType =
      eventType;

   m_memory.LastSnapshot.ValidationNewEventDetected =
      newEvent;

   m_lastValidationDecisionClass =
      m_memory.LastSnapshot.ValidationDecisionClass;

   m_lastValidationApproved =
      m_memory.LastSnapshot.ValidationApproved;

   m_lastValidationCertificationClass =
      m_memory.LastSnapshot.ValidationCertificationClass;
      
      PrintFormat(
   "MRH_X8 STEP81 | EventCount=%d | EventType=%s | NewEvent=%s",
   m_memory.LastSnapshot.ValidationEventCount,
   m_memory.LastSnapshot.ValidationLastEventType,
   (m_memory.LastSnapshot.ValidationNewEventDetected ? "TRUE" : "FALSE")
);
      
}

// STEP82.5 - Validation Event Quality Calculation
void UpdateValidationEventQuality()
{
   if(m_memory == NULL)
      return;

   if(!m_memory.LastSnapshot.ValidationNewEventDetected)
      return;

   if(m_memory.LastSnapshot.ValidationApproved)
      m_validationHighQualityEvents++;
   else if(m_memory.LastSnapshot.ValidationDecisionClass == "INTERNAL_MT5_TEST_PENDING")
      m_validationMediumQualityEvents++;
   else
      m_validationLowQualityEvents++;

   m_memory.LastSnapshot.ValidationHighQualityEvents =
      m_validationHighQualityEvents;

   m_memory.LastSnapshot.ValidationMediumQualityEvents =
      m_validationMediumQualityEvents;

   m_memory.LastSnapshot.ValidationLowQualityEvents =
      m_validationLowQualityEvents;

   int totalQualityEvents =
      m_validationHighQualityEvents +
      m_validationMediumQualityEvents +
      m_validationLowQualityEvents;

   if(totalQualityEvents <= 0)
   {
      m_memory.LastSnapshot.ValidationEventQualityScore = 0.0;
      m_memory.LastSnapshot.ValidationEventQualityClass = "NO_EVENT_QUALITY";
      m_memory.LastSnapshot.ValidationEventQualityReady = false;
      return;
   }

   m_memory.LastSnapshot.ValidationEventQualityScore =
      (
         ((double)m_validationHighQualityEvents * 100.0) +
         ((double)m_validationMediumQualityEvents * 60.0) +
         ((double)m_validationLowQualityEvents * 20.0)
      ) / (double)totalQualityEvents;

   if(totalQualityEvents < 5)
   {
      m_memory.LastSnapshot.ValidationEventQualityClass = "INSUFFICIENT_EVENT_QUALITY";
      m_memory.LastSnapshot.ValidationEventQualityReady = false;
   }
   else if(m_memory.LastSnapshot.ValidationEventQualityScore >= 80.0)
   {
      m_memory.LastSnapshot.ValidationEventQualityClass = "STRONG_EVENT_QUALITY";
      m_memory.LastSnapshot.ValidationEventQualityReady = true;
   }
   else if(m_memory.LastSnapshot.ValidationEventQualityScore >= 60.0)
   {
      m_memory.LastSnapshot.ValidationEventQualityClass = "MODERATE_EVENT_QUALITY";
      m_memory.LastSnapshot.ValidationEventQualityReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationEventQualityClass = "WEAK_EVENT_QUALITY";
      m_memory.LastSnapshot.ValidationEventQualityReady = false;
   }
   
   PrintFormat(
   "MRH_X8 STEP82 | High=%d | Medium=%d | Low=%d | QualityScore=%.2f | Class=%s | Ready=%s",
   m_memory.LastSnapshot.ValidationHighQualityEvents,
   m_memory.LastSnapshot.ValidationMediumQualityEvents,
   m_memory.LastSnapshot.ValidationLowQualityEvents,
   m_memory.LastSnapshot.ValidationEventQualityScore,
   m_memory.LastSnapshot.ValidationEventQualityClass,
   (m_memory.LastSnapshot.ValidationEventQualityReady ? "TRUE" : "FALSE")
);
   
}
   
   // STEP83.5 - Validation Event Impact Calculation
void UpdateValidationEventImpact()
{
   if(m_memory == NULL)
      return;

   if(!m_memory.LastSnapshot.ValidationNewEventDetected)
      return;

   if(m_memory.LastSnapshot.ValidationDecisionClass == "INTERNAL_MT5_TEST_APPROVED" ||
      m_memory.LastSnapshot.ValidationDecisionClass == "INTERNAL_MT5_TEST_BLOCKED")
   {
      m_validationCriticalEvents++;
   }
   else if(m_memory.LastSnapshot.ValidationDecisionClass == "INTERNAL_MT5_TEST_PENDING")
   {
      m_validationMajorEvents++;
   }
   else
   {
      m_validationMinorEvents++;
   }

   m_memory.LastSnapshot.ValidationCriticalEvents =
      m_validationCriticalEvents;

   m_memory.LastSnapshot.ValidationMajorEvents =
      m_validationMajorEvents;

   m_memory.LastSnapshot.ValidationMinorEvents =
      m_validationMinorEvents;

   int totalImpactEvents =
      m_validationCriticalEvents +
      m_validationMajorEvents +
      m_validationMinorEvents;

   if(totalImpactEvents <= 0)
   {
      m_memory.LastSnapshot.ValidationEventImpactScore = 0.0;
      m_memory.LastSnapshot.ValidationEventImpactClass = "NO_EVENT_IMPACT";
      m_memory.LastSnapshot.ValidationEventImpactReady = false;
      return;
   }

   m_memory.LastSnapshot.ValidationEventImpactScore =
      (
         ((double)m_validationCriticalEvents * 100.0) +
         ((double)m_validationMajorEvents * 70.0) +
         ((double)m_validationMinorEvents * 30.0)
      ) / (double)totalImpactEvents;

   if(totalImpactEvents < 5)
   {
      m_memory.LastSnapshot.ValidationEventImpactClass = "INSUFFICIENT_EVENT_IMPACT";
      m_memory.LastSnapshot.ValidationEventImpactReady = false;
   }
   else if(m_memory.LastSnapshot.ValidationEventImpactScore >= 80.0)
   {
      m_memory.LastSnapshot.ValidationEventImpactClass = "HIGH_EVENT_IMPACT";
      m_memory.LastSnapshot.ValidationEventImpactReady = true;
   }
   else if(m_memory.LastSnapshot.ValidationEventImpactScore >= 60.0)
   {
      m_memory.LastSnapshot.ValidationEventImpactClass = "MEDIUM_EVENT_IMPACT";
      m_memory.LastSnapshot.ValidationEventImpactReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationEventImpactClass = "LOW_EVENT_IMPACT";
      m_memory.LastSnapshot.ValidationEventImpactReady = false;
   }
   
   PrintFormat(
   "MRH_X8 STEP83 | Critical=%d | Major=%d | Minor=%d | ImpactScore=%.2f | Class=%s | Ready=%s",
   m_memory.LastSnapshot.ValidationCriticalEvents,
   m_memory.LastSnapshot.ValidationMajorEvents,
   m_memory.LastSnapshot.ValidationMinorEvents,
   m_memory.LastSnapshot.ValidationEventImpactScore,
   m_memory.LastSnapshot.ValidationEventImpactClass,
   (m_memory.LastSnapshot.ValidationEventImpactReady ? "TRUE" : "FALSE")
);
   
}
   
   // STEP84.5 - Validation Stability Calculation
void UpdateValidationStability()
{
   if(m_memory == NULL)
      return;

   if(!m_memory.LastSnapshot.ValidationNewEventDetected)
{
   m_validationStableEvents++;
}
else
{
   m_validationStateChanges++;
   m_validationUnstableEvents++;
}

   m_memory.LastSnapshot.ValidationStateChanges =
      m_validationStateChanges;

   m_memory.LastSnapshot.ValidationStableEvents =
      m_validationStableEvents;

   m_memory.LastSnapshot.ValidationUnstableEvents =
      m_validationUnstableEvents;

   int totalStabilityEvents =
      m_validationStableEvents +
      m_validationUnstableEvents;

   if(totalStabilityEvents <= 0)
   {
      m_memory.LastSnapshot.ValidationStabilityScore = 0.0;
      m_memory.LastSnapshot.ValidationStabilityClass = "NO_STABILITY_DATA";
      m_memory.LastSnapshot.ValidationStabilityReady = false;
      return;
   }

   m_memory.LastSnapshot.ValidationStabilityScore =
      ((double)m_validationStableEvents / (double)totalStabilityEvents) * 100.0;

   if(totalStabilityEvents < 5)
   {
      m_memory.LastSnapshot.ValidationStabilityClass = "INSUFFICIENT_STABILITY_DATA";
      m_memory.LastSnapshot.ValidationStabilityReady = false;
   }
   else if(m_memory.LastSnapshot.ValidationStabilityScore >= 80.0)
   {
      m_memory.LastSnapshot.ValidationStabilityClass = "HIGH_STABILITY";
      m_memory.LastSnapshot.ValidationStabilityReady = true;
   }
   else if(m_memory.LastSnapshot.ValidationStabilityScore >= 60.0)
   {
      m_memory.LastSnapshot.ValidationStabilityClass = "MODERATE_STABILITY";
      m_memory.LastSnapshot.ValidationStabilityReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationStabilityClass = "LOW_STABILITY";
      m_memory.LastSnapshot.ValidationStabilityReady = false;
   }
   
   PrintFormat(
   "MRH_X8 STEP84 | StateChanges=%d | Stable=%d | Unstable=%d | StabilityScore=%.2f | Class=%s | Ready=%s",
   m_memory.LastSnapshot.ValidationStateChanges,
   m_memory.LastSnapshot.ValidationStableEvents,
   m_memory.LastSnapshot.ValidationUnstableEvents,
   m_memory.LastSnapshot.ValidationStabilityScore,
   m_memory.LastSnapshot.ValidationStabilityClass,
   (m_memory.LastSnapshot.ValidationStabilityReady ? "TRUE" : "FALSE")
);
   
}
   
   // STEP85.3 - Validation Maturity Calculation
void UpdateValidationMaturity()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.ValidationStatisticsReady)
      score += 25.0;
   else
      reason += "STATISTICS_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationEventQualityReady)
      score += 25.0;
   else
      reason += "EVENT_QUALITY_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationEventImpactReady)
      score += 25.0;
   else
      reason += "EVENT_IMPACT_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationStabilityReady)
      score += 25.0;
   else
      reason += "STABILITY_NOT_READY;";

   m_memory.LastSnapshot.ValidationMaturityScore = score;

   if(score >= 100.0)
   {
      m_memory.LastSnapshot.ValidationMaturityClass = "FULLY_MATURE";
      m_memory.LastSnapshot.ValidationMature = true;
      m_memory.LastSnapshot.ValidationMaturityReason = "VALIDATION_MATURE";
   }
   else if(score >= 75.0)
   {
      m_memory.LastSnapshot.ValidationMaturityClass = "NEAR_MATURE";
      m_memory.LastSnapshot.ValidationMature = false;
      m_memory.LastSnapshot.ValidationMaturityReason = reason;
   }
   else if(score >= 50.0)
   {
      m_memory.LastSnapshot.ValidationMaturityClass = "PARTIALLY_MATURE";
      m_memory.LastSnapshot.ValidationMature = false;
      m_memory.LastSnapshot.ValidationMaturityReason = reason;
   }
   else
   {
      m_memory.LastSnapshot.ValidationMaturityClass = "NOT_MATURE";
      m_memory.LastSnapshot.ValidationMature = false;
      m_memory.LastSnapshot.ValidationMaturityReason = reason;
   }
   
   PrintFormat(
   "MRH_X8 STEP85 | MaturityScore=%.2f | Class=%s | Mature=%s | Reason=%s",
   m_memory.LastSnapshot.ValidationMaturityScore,
   m_memory.LastSnapshot.ValidationMaturityClass,
   (m_memory.LastSnapshot.ValidationMature ? "TRUE" : "FALSE"),
   m_memory.LastSnapshot.ValidationMaturityReason
);
   
}
   
   // STEP93.3 - Historical Validation Trend Refinement
void UpdateValidationTrend()
{
   if(m_memory == NULL)
      return;

   double currentMaturityScore =
      m_memory.LastSnapshot.ValidationMaturityScore;

   if(m_previousValidationMaturityScore <= 0.0)
   {
      m_memory.LastSnapshot.ValidationTrendScore = 0.0;
      m_memory.LastSnapshot.ValidationTrendClass = "NO_HISTORICAL_TREND";
      m_memory.LastSnapshot.ValidationTrendImproving = false;
   }
   else
   {
      double trendDelta =
         currentMaturityScore - m_previousValidationMaturityScore;

      m_memory.LastSnapshot.ValidationTrendScore = trendDelta;

      if(trendDelta >= 10.0)
      {
         m_memory.LastSnapshot.ValidationTrendClass = "STRONG_HISTORICAL_UPTREND";
         m_memory.LastSnapshot.ValidationTrendImproving = true;
      }
      else if(trendDelta > 0.0)
      {
         m_memory.LastSnapshot.ValidationTrendClass = "HISTORICAL_UPTREND";
         m_memory.LastSnapshot.ValidationTrendImproving = true;
      }
      else if(trendDelta == 0.0)
      {
         m_memory.LastSnapshot.ValidationTrendClass = "HISTORICAL_STABLE";
         m_memory.LastSnapshot.ValidationTrendImproving = false;
      }
      else if(trendDelta <= -10.0)
      {
         m_memory.LastSnapshot.ValidationTrendClass = "STRONG_HISTORICAL_DOWNTREND";
         m_memory.LastSnapshot.ValidationTrendImproving = false;
      }
      else
      {
         m_memory.LastSnapshot.ValidationTrendClass = "HISTORICAL_DOWNTREND";
         m_memory.LastSnapshot.ValidationTrendImproving = false;
      }
   }

   m_previousValidationMaturityScore = currentMaturityScore;

   PrintFormat(
      "MRH_X8 STEP93 | HistoricalTrendScore=%.2f | Class=%s | Improving=%s | CurrentMaturity=%.2f",
      m_memory.LastSnapshot.ValidationTrendScore,
      m_memory.LastSnapshot.ValidationTrendClass,
      (m_memory.LastSnapshot.ValidationTrendImproving ? "TRUE" : "FALSE"),
      currentMaturityScore
   );
}
   void UpdateValidationConfidence()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.ValidationStatisticsReady)
      score += 20.0;
   else
      reason += "STATISTICS_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationEventQualityReady)
      score += 20.0;
   else
      reason += "EVENT_QUALITY_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationEventImpactReady)
      score += 20.0;
   else
      reason += "EVENT_IMPACT_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationStabilityReady)
      score += 20.0;
   else
      reason += "STABILITY_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationMature)
      score += 20.0;
   else
      reason += "VALIDATION_NOT_MATURE;";

   m_memory.LastSnapshot.ValidationConfidenceScore = score;

   if(score >= 90.0)
   {
      m_memory.LastSnapshot.ValidationConfidenceClass = "HIGH_CONFIDENCE";
      m_memory.LastSnapshot.ValidationConfidenceReady = true;
      m_memory.LastSnapshot.ValidationConfidenceReason = "VALIDATION_CONFIDENT";
   }
   else if(score >= 70.0)
   {
      m_memory.LastSnapshot.ValidationConfidenceClass = "MEDIUM_CONFIDENCE";
      m_memory.LastSnapshot.ValidationConfidenceReady = true;
      m_memory.LastSnapshot.ValidationConfidenceReason = reason;
   }
   else if(score >= 50.0)
   {
      m_memory.LastSnapshot.ValidationConfidenceClass = "LOW_CONFIDENCE";
      m_memory.LastSnapshot.ValidationConfidenceReady = false;
      m_memory.LastSnapshot.ValidationConfidenceReason = reason;
   }
   else
   {
      m_memory.LastSnapshot.ValidationConfidenceClass = "NO_CONFIDENCE";
      m_memory.LastSnapshot.ValidationConfidenceReady = false;
      m_memory.LastSnapshot.ValidationConfidenceReason = reason;
   }

   PrintFormat(
      "MRH_X8 STEP87 | ConfidenceScore=%.2f | Class=%s | Ready=%s | Reason=%s",
      m_memory.LastSnapshot.ValidationConfidenceScore,
      m_memory.LastSnapshot.ValidationConfidenceClass,
      (m_memory.LastSnapshot.ValidationConfidenceReady ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.ValidationConfidenceReason
   );
}
   
   // STEP89.3 - Validation Analytics Calculation
void UpdateValidationAnalytics()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string summary = "";

   if(m_memory.LastSnapshot.ValidationApproved)
   {
      score += 30.0;
      summary += "APPROVED;";
   }
   else
      summary += "NOT_APPROVED;";

   if(m_memory.LastSnapshot.ValidationConfidenceReady)
   {
      score += 25.0;
      summary += "CONFIDENCE_READY;";
   }
   else
      summary += "CONFIDENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationMature)
   {
      score += 25.0;
      summary += "MATURE;";
   }
   else
      summary += "NOT_MATURE;";

   if(m_memory.LastSnapshot.ValidationTrendImproving)
   {
      score += 20.0;
      summary += "TREND_IMPROVING;";
   }
   else
      summary += "TREND_NOT_IMPROVING;";

   m_memory.LastSnapshot.ValidationAnalyticsScore = score;

   if(score >= 90.0)
   {
      m_memory.LastSnapshot.ValidationAnalyticsClass = "STRONG_VALIDATION_ANALYTICS";
      m_memory.LastSnapshot.ValidationAnalyticsReady = true;
   }
   else if(score >= 70.0)
   {
      m_memory.LastSnapshot.ValidationAnalyticsClass = "GOOD_VALIDATION_ANALYTICS";
      m_memory.LastSnapshot.ValidationAnalyticsReady = true;
   }
   else if(score >= 50.0)
   {
      m_memory.LastSnapshot.ValidationAnalyticsClass = "WEAK_VALIDATION_ANALYTICS";
      m_memory.LastSnapshot.ValidationAnalyticsReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationAnalyticsClass = "NO_VALIDATION_ANALYTICS";
      m_memory.LastSnapshot.ValidationAnalyticsReady = false;
   }

   m_memory.LastSnapshot.ValidationAnalyticsSummary = summary;

   PrintFormat(
      "MRH_X8 STEP89 | AnalyticsScore=%.2f | Class=%s | Ready=%s | Summary=%s",
      m_memory.LastSnapshot.ValidationAnalyticsScore,
      m_memory.LastSnapshot.ValidationAnalyticsClass,
      (m_memory.LastSnapshot.ValidationAnalyticsReady ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.ValidationAnalyticsSummary
   );
}
   
   // STEP90.3 - Validation Dashboard Calculation
void UpdateValidationDashboard()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string status = "";

   if(m_memory.LastSnapshot.ValidationAnalyticsReady)
   {
      score += 30.0;
      status += "ANALYTICS_READY;";
   }
   else
      status += "ANALYTICS_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationApproved)
   {
      score += 25.0;
      status += "VALIDATION_APPROVED;";
   }
   else
      status += "VALIDATION_NOT_APPROVED;";

   if(m_memory.LastSnapshot.ValidationConfidenceReady)
   {
      score += 20.0;
      status += "CONFIDENCE_READY;";
   }
   else
      status += "CONFIDENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationMature)
   {
      score += 15.0;
      status += "VALIDATION_MATURE;";
   }
   else
      status += "VALIDATION_NOT_MATURE;";

   if(m_memory.LastSnapshot.ValidationTrendImproving)
   {
      score += 10.0;
      status += "TREND_IMPROVING;";
   }
   else
      status += "TREND_NOT_IMPROVING;";

   m_memory.LastSnapshot.ValidationDashboardScore = score;

   if(score >= 90.0)
   {
      m_memory.LastSnapshot.ValidationDashboardClass = "STRONG_VALIDATION_DASHBOARD";
      m_memory.LastSnapshot.ValidationDashboardReady = true;
   }
   else if(score >= 70.0)
   {
      m_memory.LastSnapshot.ValidationDashboardClass = "GOOD_VALIDATION_DASHBOARD";
      m_memory.LastSnapshot.ValidationDashboardReady = true;
   }
   else if(score >= 50.0)
   {
      m_memory.LastSnapshot.ValidationDashboardClass = "WEAK_VALIDATION_DASHBOARD";
      m_memory.LastSnapshot.ValidationDashboardReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationDashboardClass = "NO_VALIDATION_DASHBOARD";
      m_memory.LastSnapshot.ValidationDashboardReady = false;
   }

   m_memory.LastSnapshot.ValidationDashboardStatus = status;

   PrintFormat(
      "MRH_X8 STEP90 | DashboardScore=%.2f | Class=%s | Ready=%s | Status=%s",
      m_memory.LastSnapshot.ValidationDashboardScore,
      m_memory.LastSnapshot.ValidationDashboardClass,
      (m_memory.LastSnapshot.ValidationDashboardReady ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.ValidationDashboardStatus
   );
}
   
   // STEP94.3 - Historical Validation Consistency Refinement
void UpdateValidationConsistency()
{
   if(m_memory == NULL)
      return;

   bool currentApproved =
      m_memory.LastSnapshot.ValidationApproved;

   bool currentConfidenceReady =
      m_memory.LastSnapshot.ValidationConfidenceReady;

   bool approvalStable =
      (currentApproved == m_previousValidationApproved);

   bool confidenceStable =
      (currentConfidenceReady == m_previousValidationConfidenceReady);

   if(approvalStable && confidenceStable)
      m_validationConsistencyStableCount++;
   else
      m_validationConsistencyChangeCount++;

   int totalChecks =
      m_validationConsistencyStableCount +
      m_validationConsistencyChangeCount;

   double score = 0.0;
   string reason = "";

   if(totalChecks > 0)
   {
      score =
         ((double)m_validationConsistencyStableCount /
          (double)totalChecks) * 100.0;
   }

   if(totalChecks < 5)
      reason += "INSUFFICIENT_CONSISTENCY_HISTORY;";

   if(!approvalStable)
      reason += "APPROVAL_STATE_CHANGED;";

   if(!confidenceStable)
      reason += "CONFIDENCE_STATE_CHANGED;";

   m_memory.LastSnapshot.ValidationConsistencyScore = score;

   if(score >= 85.0 && totalChecks >= 5)
   {
      m_memory.LastSnapshot.ValidationConsistencyClass = "HIGH_HISTORICAL_CONSISTENCY";
      m_memory.LastSnapshot.ValidationConsistencyReady = true;
   }
   else if(score >= 65.0 && totalChecks >= 5)
   {
      m_memory.LastSnapshot.ValidationConsistencyClass = "MEDIUM_HISTORICAL_CONSISTENCY";
      m_memory.LastSnapshot.ValidationConsistencyReady = true;
   }
   else if(score >= 40.0)
   {
      m_memory.LastSnapshot.ValidationConsistencyClass = "LOW_HISTORICAL_CONSISTENCY";
      m_memory.LastSnapshot.ValidationConsistencyReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationConsistencyClass = "NO_HISTORICAL_CONSISTENCY";
      m_memory.LastSnapshot.ValidationConsistencyReady = false;
   }

   m_memory.LastSnapshot.ValidationConsistencyReason = reason;

   m_previousValidationApproved = currentApproved;
   m_previousValidationConfidenceReady = currentConfidenceReady;

   PrintFormat(
      "MRH_X8 STEP94 | HistoricalConsistencyScore=%.2f | Class=%s | Ready=%s | StableCount=%d | ChangeCount=%d | Reason=%s",
      m_memory.LastSnapshot.ValidationConsistencyScore,
      m_memory.LastSnapshot.ValidationConsistencyClass,
      (m_memory.LastSnapshot.ValidationConsistencyReady ? "TRUE" : "FALSE"),
      m_validationConsistencyStableCount,
      m_validationConsistencyChangeCount,
      m_memory.LastSnapshot.ValidationConsistencyReason
   );
}
   
   // STEP92.5 - Validation Historical Persistence Calculation
void UpdateValidationHistoricalPersistence()
{
   if(m_memory == NULL)
      return;

   m_validationPersistenceSamples++;

   if(m_memory.LastSnapshot.ValidationApproved)
      m_validationApprovedPersistenceCount++;

   if(m_memory.LastSnapshot.ValidationConfidenceReady)
      m_validationConfidencePersistenceCount++;

   if(m_memory.LastSnapshot.ValidationMature)
      m_validationMaturityPersistenceCount++;

   m_memory.LastSnapshot.ValidationPersistenceSamples =
      m_validationPersistenceSamples;

   m_memory.LastSnapshot.ValidationApprovedPersistenceCount =
      m_validationApprovedPersistenceCount;

   m_memory.LastSnapshot.ValidationConfidencePersistenceCount =
      m_validationConfidencePersistenceCount;

   m_memory.LastSnapshot.ValidationMaturityPersistenceCount =
      m_validationMaturityPersistenceCount;

   double approvedRate = 0.0;
   double confidenceRate = 0.0;
   double maturityRate = 0.0;

   if(m_validationPersistenceSamples > 0)
   {
      approvedRate =
         (double)m_validationApprovedPersistenceCount /
         (double)m_validationPersistenceSamples;

      confidenceRate =
         (double)m_validationConfidencePersistenceCount /
         (double)m_validationPersistenceSamples;

      maturityRate =
         (double)m_validationMaturityPersistenceCount /
         (double)m_validationPersistenceSamples;
   }

   double score =
      (approvedRate * 40.0) +
      (confidenceRate * 30.0) +
      (maturityRate * 30.0);

   m_memory.LastSnapshot.ValidationPersistenceScore = score;

   string reason = "";

   if(m_validationPersistenceSamples < 5)
      reason += "INSUFFICIENT_HISTORY;";

   if(approvedRate < 0.60)
      reason += "LOW_APPROVAL_PERSISTENCE;";

   if(confidenceRate < 0.60)
      reason += "LOW_CONFIDENCE_PERSISTENCE;";

   if(maturityRate < 0.60)
      reason += "LOW_MATURITY_PERSISTENCE;";

   if(score >= 85.0 && m_validationPersistenceSamples >= 5)
   {
      m_memory.LastSnapshot.ValidationPersistenceClass = "HIGH_PERSISTENCE";
      m_memory.LastSnapshot.ValidationPersistenceReady = true;
   }
   else if(score >= 65.0 && m_validationPersistenceSamples >= 5)
   {
      m_memory.LastSnapshot.ValidationPersistenceClass = "MEDIUM_PERSISTENCE";
      m_memory.LastSnapshot.ValidationPersistenceReady = true;
   }
   else if(score >= 40.0)
   {
      m_memory.LastSnapshot.ValidationPersistenceClass = "LOW_PERSISTENCE";
      m_memory.LastSnapshot.ValidationPersistenceReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ValidationPersistenceClass = "NO_PERSISTENCE";
      m_memory.LastSnapshot.ValidationPersistenceReady = false;
   }

   m_memory.LastSnapshot.ValidationPersistenceReason = reason;

   PrintFormat(
      "MRH_X8 STEP92 | PersistenceSamples=%d | PersistenceScore=%.2f | Class=%s | Ready=%s | Reason=%s",
      m_memory.LastSnapshot.ValidationPersistenceSamples,
      m_memory.LastSnapshot.ValidationPersistenceScore,
      m_memory.LastSnapshot.ValidationPersistenceClass,
      (m_memory.LastSnapshot.ValidationPersistenceReady ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.ValidationPersistenceReason
   );
}
   
   // STEP95.3 - Setup Reliability Calculation
void UpdateSetupReliability()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.Trade.TradeLabel == "WIN")
      score += 30.0;
   else if(m_memory.Trade.TradeLabel == "LOSS")
      reason += "LOSS_LABEL;";
   else
      reason += "NO_VALID_TRADE_LABEL;";

   if(m_memory.Trade.AdvancedLabel == "GOOD_WIN")
      score += 25.0;
   else
      reason += "ADVANCED_LABEL_NOT_STRONG;";

   if(m_memory.LastSnapshot.ValidationConfidenceReady)
      score += 20.0;
   else
      reason += "VALIDATION_CONFIDENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationPersistenceReady)
      score += 15.0;
   else
      reason += "VALIDATION_PERSISTENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationConsistencyReady)
      score += 10.0;
   else
      reason += "VALIDATION_CONSISTENCY_NOT_READY;";

   m_memory.LastSnapshot.SetupReliabilityScore = score;

   if(score >= 80.0)
   {
      m_memory.LastSnapshot.SetupReliabilityClass = "HIGH_SETUP_RELIABILITY";
      m_memory.LastSnapshot.SetupReliable = true;
   }
   else if(score >= 60.0)
   {
      m_memory.LastSnapshot.SetupReliabilityClass = "MEDIUM_SETUP_RELIABILITY";
      m_memory.LastSnapshot.SetupReliable = true;
   }
   else if(score >= 40.0)
   {
      m_memory.LastSnapshot.SetupReliabilityClass = "LOW_SETUP_RELIABILITY";
      m_memory.LastSnapshot.SetupReliable = false;
   }
   else
   {
      m_memory.LastSnapshot.SetupReliabilityClass = "NO_SETUP_RELIABILITY";
      m_memory.LastSnapshot.SetupReliable = false;
   }

   m_memory.LastSnapshot.SetupReliabilityReason = reason;

   PrintFormat(
      "MRH_X8 STEP95 | SetupReliabilityScore=%.2f | Class=%s | Reliable=%s | Reason=%s",
      m_memory.LastSnapshot.SetupReliabilityScore,
      m_memory.LastSnapshot.SetupReliabilityClass,
      (m_memory.LastSnapshot.SetupReliable ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.SetupReliabilityReason
   );
}

// STEP96.3 - Setup Learning Readiness Calculation
void UpdateSetupLearningReadiness()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.SetupReliable)
      score += 35.0;
   else
      reason += "SETUP_NOT_RELIABLE;";

   if(m_memory.LastSnapshot.ValidationPersistenceReady)
      score += 25.0;
   else
      reason += "PERSISTENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationConsistencyReady)
      score += 20.0;
   else
      reason += "CONSISTENCY_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationConfidenceReady)
      score += 20.0;
   else
      reason += "CONFIDENCE_NOT_READY;";

   m_memory.LastSnapshot.SetupLearningReadinessScore = score;

   if(score >= 80.0)
   {
      m_memory.LastSnapshot.SetupLearningReadinessClass =
         "READY_FOR_ML_LEARNING";
      m_memory.LastSnapshot.SetupLearningReady = true;
   }
   else if(score >= 60.0)
   {
      m_memory.LastSnapshot.SetupLearningReadinessClass =
         "PARTIALLY_READY_FOR_ML_LEARNING";
      m_memory.LastSnapshot.SetupLearningReady = false;
   }
   else
   {
      m_memory.LastSnapshot.SetupLearningReadinessClass =
         "NOT_READY_FOR_ML_LEARNING";
      m_memory.LastSnapshot.SetupLearningReady = false;
   }

   m_memory.LastSnapshot.SetupLearningReadinessReason = reason;

   PrintFormat(
      "MRH_X8 STEP96 | LearningReadinessScore=%.2f | Class=%s | Ready=%s | Reason=%s",
      m_memory.LastSnapshot.SetupLearningReadinessScore,
      m_memory.LastSnapshot.SetupLearningReadinessClass,
      (m_memory.LastSnapshot.SetupLearningReady ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.SetupLearningReadinessReason
   );
}
   
   // STEP97.3 - Setup Probability Stability Calculation
void UpdateSetupProbabilityStability()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.SetupLearningReady)
      score += 40.0;
   else
      reason += "LEARNING_NOT_READY;";

   if(m_memory.LastSnapshot.SetupReliable)
      score += 30.0;
   else
      reason += "SETUP_NOT_RELIABLE;";

   if(m_memory.LastSnapshot.ValidationPersistenceReady)
      score += 20.0;
   else
      reason += "PERSISTENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationConsistencyReady)
      score += 10.0;
   else
      reason += "CONSISTENCY_NOT_READY;";

   m_memory.LastSnapshot.SetupProbabilityStabilityScore = score;

   if(score >= 80.0)
   {
      m_memory.LastSnapshot.SetupProbabilityStabilityClass =
         "HIGH_PROBABILITY_STABILITY";
      m_memory.LastSnapshot.SetupProbabilityStable = true;
   }
   else if(score >= 60.0)
   {
      m_memory.LastSnapshot.SetupProbabilityStabilityClass =
         "MEDIUM_PROBABILITY_STABILITY";
      m_memory.LastSnapshot.SetupProbabilityStable = true;
   }
   else if(score >= 40.0)
   {
      m_memory.LastSnapshot.SetupProbabilityStabilityClass =
         "LOW_PROBABILITY_STABILITY";
      m_memory.LastSnapshot.SetupProbabilityStable = false;
   }
   else
   {
      m_memory.LastSnapshot.SetupProbabilityStabilityClass =
         "NO_PROBABILITY_STABILITY";
      m_memory.LastSnapshot.SetupProbabilityStable = false;
   }

   m_memory.LastSnapshot.SetupProbabilityStabilityReason = reason;

   PrintFormat(
      "MRH_X8 STEP97 | ProbabilityStabilityScore=%.2f | Class=%s | Stable=%s | Reason=%s",
      m_memory.LastSnapshot.SetupProbabilityStabilityScore,
      m_memory.LastSnapshot.SetupProbabilityStabilityClass,
      (m_memory.LastSnapshot.SetupProbabilityStable ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.SetupProbabilityStabilityReason
   );
}
   
   // STEP98.3 - Forward Test Readiness Calculation
void UpdateForwardTestReadiness()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.ValidationPersistenceReady)
      score += 25.0;
   else
      reason += "PERSISTENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationConsistencyReady)
      score += 25.0;
   else
      reason += "CONSISTENCY_NOT_READY;";

   if(m_memory.LastSnapshot.SetupLearningReady)
      score += 25.0;
   else
      reason += "SETUP_LEARNING_NOT_READY;";

   if(m_memory.LastSnapshot.SetupProbabilityStable)
      score += 25.0;
   else
      reason += "PROBABILITY_NOT_STABLE;";

   m_memory.LastSnapshot.ForwardTestReadinessScore = score;

   if(score >= 80.0)
   {
      m_memory.LastSnapshot.ForwardTestReadinessClass =
         "READY_FOR_FORWARD_TEST";
      m_memory.LastSnapshot.ForwardTestReady = true;
   }
   else if(score >= 60.0)
   {
      m_memory.LastSnapshot.ForwardTestReadinessClass =
         "PARTIALLY_READY_FOR_FORWARD_TEST";
      m_memory.LastSnapshot.ForwardTestReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ForwardTestReadinessClass =
         "NOT_READY_FOR_FORWARD_TEST";
      m_memory.LastSnapshot.ForwardTestReady = false;
   }

   m_memory.LastSnapshot.ForwardTestReadinessReason = reason;

   PrintFormat(
      "MRH_X8 STEP98 | ForwardTestScore=%.2f | Class=%s | Ready=%s | Reason=%s",
      m_memory.LastSnapshot.ForwardTestReadinessScore,
      m_memory.LastSnapshot.ForwardTestReadinessClass,
      (m_memory.LastSnapshot.ForwardTestReady ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.ForwardTestReadinessReason
   );
}
   
   // STEP99.3 - ML Dataset Certification Calculation
void UpdateMLDatasetCertification()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.DatasetApproved)
      score += 25.0;
   else
      reason += "DATASET_NOT_APPROVED;";

   if(m_memory.LastSnapshot.ValidationPersistenceReady)
      score += 20.0;
   else
      reason += "PERSISTENCE_NOT_READY;";

   if(m_memory.LastSnapshot.ValidationConsistencyReady)
      score += 20.0;
   else
      reason += "CONSISTENCY_NOT_READY;";

   if(m_memory.LastSnapshot.SetupLearningReady)
      score += 20.0;
   else
      reason += "SETUP_LEARNING_NOT_READY;";

   if(m_memory.LastSnapshot.SetupProbabilityStable)
      score += 15.0;
   else
      reason += "PROBABILITY_NOT_STABLE;";

   m_memory.LastSnapshot.MLDatasetCertificationScore = score;

   if(score >= 85.0)
   {
      m_memory.LastSnapshot.MLDatasetCertificationClass =
         "ML_DATASET_CERTIFIED";
      m_memory.LastSnapshot.MLDatasetCertified = true;
   }
   else if(score >= 65.0)
   {
      m_memory.LastSnapshot.MLDatasetCertificationClass =
         "ML_DATASET_PARTIALLY_CERTIFIED";
      m_memory.LastSnapshot.MLDatasetCertified = false;
   }
   else
   {
      m_memory.LastSnapshot.MLDatasetCertificationClass =
         "ML_DATASET_NOT_CERTIFIED";
      m_memory.LastSnapshot.MLDatasetCertified = false;
   }

   m_memory.LastSnapshot.MLDatasetCertificationReason = reason;

   PrintFormat(
      "MRH_X8 STEP99 | MLDatasetCertificationScore=%.2f | Class=%s | Certified=%s | Reason=%s",
      m_memory.LastSnapshot.MLDatasetCertificationScore,
      m_memory.LastSnapshot.MLDatasetCertificationClass,
      (m_memory.LastSnapshot.MLDatasetCertified ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.MLDatasetCertificationReason
   );
}
   
   // STEP100.3 - Release Candidate Validation Calculation
void UpdateReleaseCandidateValidation()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   string reason = "";

   if(m_memory.LastSnapshot.MLDatasetCertified)
      score += 40.0;
   else
      reason += "ML_DATASET_NOT_CERTIFIED;";

   if(m_memory.LastSnapshot.ForwardTestReady)
      score += 30.0;
   else
      reason += "FORWARD_TEST_NOT_READY;";

   if(m_memory.LastSnapshot.SetupLearningReady)
      score += 20.0;
   else
      reason += "SETUP_LEARNING_NOT_READY;";

   if(m_memory.LastSnapshot.SetupProbabilityStable)
      score += 10.0;
   else
      reason += "PROBABILITY_NOT_STABLE;";

   m_memory.LastSnapshot.ReleaseCandidateScore = score;

   if(score >= 85.0)
   {
      m_memory.LastSnapshot.ReleaseCandidateClass =
         "READY_FOR_ML_PHASE";
      m_memory.LastSnapshot.ReleaseCandidateReady = true;
   }
   else if(score >= 60.0)
   {
      m_memory.LastSnapshot.ReleaseCandidateClass =
         "PARTIALLY_READY_FOR_ML_PHASE";
      m_memory.LastSnapshot.ReleaseCandidateReady = false;
   }
   else
   {
      m_memory.LastSnapshot.ReleaseCandidateClass =
         "NOT_READY_FOR_ML_PHASE";
      m_memory.LastSnapshot.ReleaseCandidateReady = false;
   }

   m_memory.LastSnapshot.ReleaseCandidateReason = reason;

   PrintFormat(
      "MRH_X8 STEP100 | ReleaseCandidateScore=%.2f | Class=%s | Ready=%s | Reason=%s",
      m_memory.LastSnapshot.ReleaseCandidateScore,
      m_memory.LastSnapshot.ReleaseCandidateClass,
      (m_memory.LastSnapshot.ReleaseCandidateReady ? "TRUE" : "FALSE"),
      m_memory.LastSnapshot.ReleaseCandidateReason
   );
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

void CalculateDatasetCompleteness()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   int totalChecks = 10;
   int passedChecks = 0;

   if(m_memory.LastSnapshot.SnapshotTime > 0)
      passedChecks++;

   if(m_memory.LastSnapshot.ExecutionGrade != "")
      passedChecks++;

   if(m_memory.LastSnapshot.ConfidenceLevel != "")
      passedChecks++;

   if(m_memory.LastSnapshot.RiskProfile != "")
      passedChecks++;

   if(m_memory.LastSnapshot.ExitReason != "")
      passedChecks++;

   if(m_memory.LastSnapshot.Outcome != TRADE_OUTCOME_UNKNOWN)
      passedChecks++;

   if(m_memory.LastSnapshot.TradeLabel != "")
      passedChecks++;

   if(m_memory.LastSnapshot.ProbabilityClass != "")
      passedChecks++;

   if(m_memory.LastSnapshot.DatasetIntegrityClass != "")
      passedChecks++;

   if(m_memory.LastSnapshot.TestReadinessClass != "")
      passedChecks++;

   score = ((double)passedChecks / (double)totalChecks) * 100.0;

   m_datasetCompletenessScore = score;

   if(score >= 90.0)
   {
      m_datasetCompletenessClass = "COMPLETE";
      m_datasetComplete = true;
   }
   else if(score >= 70.0)
   {
      m_datasetCompletenessClass = "PARTIAL";
      m_datasetComplete = false;
   }
   else
   {
      m_datasetCompletenessClass = "INCOMPLETE";
      m_datasetComplete = false;
   }
}

void CalculateDatasetReliability()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   int totalChecks = 5;
   int passedChecks = 0;

   if(m_memory.LastSnapshot.DatasetIntegrityApproved)
      passedChecks++;

   if(m_memory.LastSnapshot.TestReady)
      passedChecks++;

   if(m_memory.LastSnapshot.DatasetComplete)
      passedChecks++;

   if(m_memory.LastSnapshot.ArchitectureApproved)
      passedChecks++;

   if(m_memory.LastSnapshot.Outcome != TRADE_OUTCOME_UNKNOWN)
      passedChecks++;

   score = ((double)passedChecks / (double)totalChecks) * 100.0;

   m_datasetReliabilityScore = score;

   if(score >= 80.0)
   {
      m_datasetReliabilityClass = "RELIABLE";
      m_datasetReliable = true;
   }
   else if(score >= 60.0)
   {
      m_datasetReliabilityClass = "MODERATE";
      m_datasetReliable = false;
   }
   else
   {
      m_datasetReliabilityClass = "UNRELIABLE";
      m_datasetReliable = false;
   }
}

void CalculateDatasetStability()
{
   if(m_memory == NULL)
      return;

   double score = 0.0;
   int totalChecks = 5;
   int passedChecks = 0;

   if(m_datasetReliabilityScore >= 60.0)
      passedChecks++;

   if(m_datasetCompletenessScore >= 70.0)
      passedChecks++;

   if(m_datasetIntegrityScore >= 70.0)
      passedChecks++;

   if(m_totalRows >= 10)
      passedChecks++;

   if(m_mlFeatureCount >= 10)
      passedChecks++;

   score = ((double)passedChecks / (double)totalChecks) * 100.0;

   m_datasetStabilityScore = score;

   if(score >= 80.0)
   {
      m_datasetStabilityClass = "STABLE";
      m_datasetStable = true;
   }
   else if(score >= 60.0)
   {
      m_datasetStabilityClass = "DEVELOPING";
      m_datasetStable = false;
   }
   else
   {
      m_datasetStabilityClass = "UNSTABLE";
      m_datasetStable = false;
   }
}

void CalculateDatasetHealth()
{
   if(m_memory == NULL)
      return;

   m_datasetHealthScore =
      (m_datasetIntegrityScore +
       m_datasetCompletenessScore +
       m_datasetReliabilityScore +
       m_datasetStabilityScore) / 4.0;

   if(m_datasetHealthScore >= 80.0)
   {
      m_datasetHealthClass = "HEALTHY";
      m_datasetHealthy = true;
   }
   else if(m_datasetHealthScore >= 60.0)
   {
      m_datasetHealthClass = "WARNING";
      m_datasetHealthy = false;
   }
   else
   {
      m_datasetHealthClass = "CRITICAL";
      m_datasetHealthy = false;
   }
}

void CalculateDatasetConfidence()
{
   if(m_memory == NULL)
      return;

   m_datasetConfidenceScore =
      (m_datasetCompletenessScore +
       m_datasetReliabilityScore +
       m_datasetStabilityScore +
       m_datasetHealthScore) / 4.0;

   if(m_datasetConfidenceScore >= 80.0)
   {
      m_datasetConfidenceClass = "HIGH_CONFIDENCE";
      m_datasetConfidenceApproved = true;
   }
   else if(m_datasetConfidenceScore >= 60.0)
   {
      m_datasetConfidenceClass = "MEDIUM_CONFIDENCE";
      m_datasetConfidenceApproved = false;
   }
   else
   {
      m_datasetConfidenceClass = "LOW_CONFIDENCE";
      m_datasetConfidenceApproved = false;
   }
}

void CalculateDatasetApproval()
{
   if(m_memory == NULL)
      return;

   m_datasetApprovalScore =
      (m_datasetHealthScore +
       m_datasetConfidenceScore) / 2.0;

   if(m_datasetApprovalScore >= 80.0)
   {
      m_datasetApprovalClass = "APPROVED";
      m_datasetApproved = true;
   }
   else if(m_datasetApprovalScore >= 60.0)
   {
      m_datasetApprovalClass = "REVIEW_REQUIRED";
      m_datasetApproved = false;
   }
   else
   {
      m_datasetApprovalClass = "REJECTED";
      m_datasetApproved = false;
   }
}

void CalculateDatasetReleaseReadiness()
{
   if(m_memory == NULL)
      return;

   m_datasetReleaseScore =
      (m_datasetApprovalScore +
       m_datasetConfidenceScore) / 2.0;

   if(m_datasetReleaseScore >= 80.0)
   {
      m_datasetReleaseClass = "RELEASE_READY";
      m_datasetReleaseReady = true;
   }
   else if(m_datasetReleaseScore >= 60.0)
   {
      m_datasetReleaseClass = "VALIDATION_REQUIRED";
      m_datasetReleaseReady = false;
   }
   else
   {
      m_datasetReleaseClass = "NOT_READY";
      m_datasetReleaseReady = false;
   }
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

  string header =
"SnapshotTime\tLiquidityScore\tOBScore\tPermissionScore\tConfluenceScore\tExecutionGrade\tConfidenceLevel\tAuditReason\tRecommendedRisk\tRiskProfile\tTradeState\tCurrentRR\tExitReason\tOutcome\tLossCause\tWinCause\tFinalProfit\tFinalRR\tClosePrice\tCloseTime\tTradeLabel\tAdvancedLabel\tLabelQuality\tDynamicQualityLabel\tProbabilityClass\tOutcomeReadinessClass\tLabelReadinessClass\tOutcomeTrackingClass\tTradeQualityAuditClass\tTradeLifecycleClass\tDatasetReadinessClass\tDatasetQualityClass\tMLReadyFlag\tMLFeatureCount\tDatasetMaturityScore\tDatasetMaturityClass\tDatasetBalanceScore\tDatasetBalanceClass\tWinLossBalance\tProbabilityBalance\tLabelBalance\tArchitectureAuditScore\tArchitectureAuditClass\tArchitectureApproved\tDatasetIntegrityScore\tDatasetIntegrityClass\tDatasetIntegrityApproved\tTestReadinessScore\tTestReadinessClass\tTestReady\tDatasetCompletenessScore\tDatasetCompletenessClass\tDatasetComplete\tDatasetReliabilityScore\tDatasetReliabilityClass\tDatasetReliable\tDatasetStabilityScore\tDatasetStabilityClass\tDatasetStable\tDatasetHealthScore\tDatasetHealthClass\tDatasetHealthy\tDatasetConfidenceScore\tDatasetConfidenceClass\tDatasetConfidenceApproved\tDatasetApprovalScore\tDatasetApprovalClass\tDatasetApproved\tDatasetReleaseScore\tDatasetReleaseClass\tDatasetReleaseReady\tInternalValidationScore\tInternalValidationClass\tInternalValidationPassed\tInternalValidationReason\tInternalValidationSampleCount\tInternalValidationFailureCount\tValidationPassCount\tValidationWarningCount\tValidationFailCount\tValidationEvidenceScore\tValidationEvidenceClass\tValidationEvidenceReady\tValidationCampaignSampleCount\tValidationCampaignSessionCount\tValidationCampaignProgressScore\tValidationCampaignStatusClass\tValidationCampaignReady\tValidationSuccessRate\tValidationFailureRate\tValidationPerformanceScore\tValidationPerformanceClass\tValidationPerformanceReady\tValidationCertificationScore\tValidationCertificationClass\tValidationCertified\tValidationCertificationReason\tValidationReportScore\tValidationReportClass\tValidationReportReady\tValidationReportSummary\tValidationDecisionScore\tValidationDecisionClass\tValidationApproved\tValidationDecisionReason\tValidationTotalSamples\tValidationApprovedSamples\tValidationBlockedSamples\tValidationApprovalRate\tValidationBlockRate\tValidationStatisticsClass\tValidationStatisticsReady\tValidationEventCount\tValidationLastEventType\tValidationNewEventDetected\tValidationHighQualityEvents\tValidationMediumQualityEvents\tValidationLowQualityEvents\tValidationEventQualityScore\tValidationEventQualityClass\tValidationEventQualityReady\tValidationCriticalEvents\tValidationMajorEvents\tValidationMinorEvents\tValidationEventImpactScore\tValidationEventImpactClass\tValidationEventImpactReady\tValidationStateChanges\tValidationStableEvents\tValidationUnstableEvents\tValidationStabilityScore\tValidationStabilityClass\tValidationStabilityReady\tValidationMaturityScore\tValidationMaturityClass\tValidationMature\tValidationMaturityReason\tFeatureReliabilityScore\tFeatureReliabilityClass\tFeatureReliabilityReady\tFeatureReliabilityReason\tStructureFeatureWeight\tLiquidityFeatureWeight\tOBFeatureWeight\tExecutionFeatureWeight\tRiskFeatureWeight\tSetupConfidenceWeight\tOverallFeatureWeightScore\tFeatureWeightClass\tFeatureWeightReady\tAdaptiveFeatureWeightScore\tAdaptiveFeatureWeightClass\tAdaptiveFeatureWeightReady\tAdaptiveFeatureWeightReason\tHistoricalFeatureTrades\tHistoricalFeatureWins\tHistoricalFeatureLosses\tHistoricalFeatureWinRate\tHistoricalFeaturePerformanceScore\tHistoricalFeaturePerformanceClass\tHistoricalFeaturePerformanceReady";
   FileWriteString(fileHandle, header + "\r\n");
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

     string row =
   TimeToString(m_memory.LastSnapshot.SnapshotTime, TIME_DATE | TIME_SECONDS) + "\t" +
   DoubleToString(m_memory.LastSnapshot.LiquidityScore, 1) + "\t" +
   DoubleToString(m_memory.LastSnapshot.OBScore, 1) + "\t" +
   DoubleToString(m_memory.LastSnapshot.PermissionScore, 1) + "\t" +
   DoubleToString(m_memory.LastSnapshot.ConfluenceScore, 1) + "\t" +
   m_memory.LastSnapshot.ExecutionGrade + "\t" +
   m_memory.LastSnapshot.ConfidenceLevel + "\t" +
   m_memory.Execution.AuditReason + "\t" +
   DoubleToString(m_memory.LastSnapshot.RecommendedRisk, 2) + "\t" +
   m_memory.LastSnapshot.RiskProfile + "\t" +
   IntegerToString((int)m_memory.LastSnapshot.TradeState) + "\t" +
   DoubleToString(m_memory.LastSnapshot.CurrentRR, 2) + "\t" +
   m_memory.LastSnapshot.ExitReason + "\t" +
   TradeOutcomeToString(m_memory.LastSnapshot.Outcome) + "\t" +
   IntegerToString((int)m_memory.LastSnapshot.LossCause) + "\t" +
   IntegerToString((int)m_memory.LastSnapshot.WinCause) + "\t" +
   DoubleToString(m_memory.LastSnapshot.FinalProfit, 2) + "\t" +
   DoubleToString(m_memory.LastSnapshot.FinalRR, 2) + "\t" +
   DoubleToString(m_memory.LastSnapshot.ClosePrice, _Digits) + "\t" +
   TimeToString(m_memory.LastSnapshot.CloseTime, TIME_DATE | TIME_SECONDS) + "\t" +
   m_memory.LastSnapshot.TradeLabel + "\t" +
   m_memory.LastSnapshot.AdvancedLabel + "\t" +
   m_memory.LastSnapshot.LabelQuality + "\t" +
   m_memory.LastSnapshot.DynamicQualityLabel + "\t" +
   m_memory.LastSnapshot.ProbabilityClass + "\t" +
   m_memory.LastSnapshot.OutcomeReadinessClass + "\t" +
   m_memory.LastSnapshot.LabelReadinessClass + "\t" +
   m_memory.LastSnapshot.OutcomeTrackingClass + "\t" +
   m_memory.LastSnapshot.TradeQualityAuditClass + "\t" +
   m_memory.LastSnapshot.TradeLifecycleClass + "\t" +
   m_datasetReadinessClass + "\t" +
   m_datasetQualityClass + "\t" +
   (m_mlReadyFlag ? "TRUE" : "FALSE") + "\t" +
   IntegerToString(m_mlFeatureCount) + "\t" +
   DoubleToString(m_datasetMaturityScore, 2) + "\t" +
   m_datasetMaturityClass + "\t" +
   DoubleToString(m_datasetBalanceScore, 2) + "\t" +
   m_datasetBalanceClass + "\t" +
   DoubleToString(m_winLossBalance, 2) + "\t" +
   DoubleToString(m_probabilityBalance, 2) + "\t" +
   DoubleToString(m_labelBalance, 2) + "\t" +
   DoubleToString(m_memory.LastSnapshot.ArchitectureAuditScore, 2) + "\t" +
   m_memory.LastSnapshot.ArchitectureAuditClass + "\t" +
   (m_memory.LastSnapshot.ArchitectureApproved ? "TRUE" : "FALSE") + "\t" +
   DoubleToString(m_memory.LastSnapshot.DatasetIntegrityScore, 2) + "\t" +
   m_memory.LastSnapshot.DatasetIntegrityClass + "\t" +
   (m_memory.LastSnapshot.DatasetIntegrityApproved ? "TRUE" : "FALSE") + "\t" +
   DoubleToString(m_memory.LastSnapshot.TestReadinessScore, 2) + "\t" +
   m_memory.LastSnapshot.TestReadinessClass + "\t" +
   (m_memory.LastSnapshot.TestReady ? "TRUE" : "FALSE") + "\t" +
   DoubleToString(m_memory.LastSnapshot.DatasetCompletenessScore, 2) + "\t" +
   m_memory.LastSnapshot.DatasetCompletenessClass + "\t" +
   (m_memory.LastSnapshot.DatasetComplete ? "TRUE" : "FALSE") + "\t" +
   DoubleToString(m_memory.LastSnapshot.DatasetReliabilityScore, 2) + "\t" +
   m_memory.LastSnapshot.DatasetReliabilityClass + "\t" +
   (m_memory.LastSnapshot.DatasetReliable ? "TRUE" : "FALSE") + "\t" +
   DoubleToString(m_memory.LastSnapshot.DatasetStabilityScore, 2) + "\t" +
   m_memory.LastSnapshot.DatasetStabilityClass + "\t" +
   (m_memory.LastSnapshot.DatasetStable ? "TRUE" : "FALSE") + "\t" +
   DoubleToString(m_memory.LastSnapshot.DatasetHealthScore, 2) + "\t" +
   m_memory.LastSnapshot.DatasetHealthClass + "\t" +
   (m_memory.LastSnapshot.DatasetHealthy ? "TRUE" : "FALSE") + "\t" +
   DoubleToString(m_memory.LastSnapshot.DatasetConfidenceScore, 2) + "\t" +
   m_memory.LastSnapshot.DatasetConfidenceClass + "\t" +
   (m_memory.LastSnapshot.DatasetConfidenceApproved ? "TRUE" : "FALSE")
+ "\t" +
DoubleToString(m_memory.LastSnapshot.DatasetApprovalScore, 2) + "\t" +
m_memory.LastSnapshot.DatasetApprovalClass + "\t" +
(m_memory.LastSnapshot.DatasetApproved ? "TRUE" : "FALSE")+ "\t" +
DoubleToString(m_memory.LastSnapshot.DatasetReleaseScore, 2) + "\t" +
m_memory.LastSnapshot.DatasetReleaseClass + "\t" +
(m_memory.LastSnapshot.DatasetReleaseReady ? "TRUE" : "FALSE") + "\t" +

DoubleToString(m_memory.LastSnapshot.InternalValidationScore, 2) + "\t" +
m_memory.LastSnapshot.InternalValidationClass + "\t" +
(m_memory.LastSnapshot.InternalValidationPassed ? "TRUE" : "FALSE") + "\t" +
m_memory.LastSnapshot.InternalValidationReason + "\t" +
IntegerToString(m_memory.LastSnapshot.InternalValidationSampleCount) + "\t" +
IntegerToString(m_memory.LastSnapshot.InternalValidationFailureCount) + "\t" +

IntegerToString(m_memory.LastSnapshot.ValidationPassCount) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationWarningCount) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationFailCount) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationEvidenceScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationEvidenceClass + "\t" +
(m_memory.LastSnapshot.ValidationEvidenceReady ? "TRUE" : "FALSE") + "\t" +

IntegerToString(m_memory.LastSnapshot.ValidationCampaignSampleCount) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationCampaignSessionCount) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationCampaignProgressScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationCampaignStatusClass + "\t" +
(m_memory.LastSnapshot.ValidationCampaignReady ? "TRUE" : "FALSE") + "\t" +

DoubleToString(m_memory.LastSnapshot.ValidationSuccessRate, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationFailureRate, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationPerformanceScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationPerformanceClass + "\t" +
(m_memory.LastSnapshot.ValidationPerformanceReady ? "TRUE" : "FALSE") + "\t" +

DoubleToString(m_memory.LastSnapshot.ValidationCertificationScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationCertificationClass + "\t" +
(m_memory.LastSnapshot.ValidationCertified ? "TRUE" : "FALSE") + "\t" +
m_memory.LastSnapshot.ValidationCertificationReason + "\t" +

DoubleToString(m_memory.LastSnapshot.ValidationReportScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationReportClass + "\t" +
(m_memory.LastSnapshot.ValidationReportReady ? "TRUE" : "FALSE") + "\t" +
m_memory.LastSnapshot.ValidationReportSummary + "\t" +

DoubleToString(m_memory.LastSnapshot.ValidationDecisionScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationDecisionClass + "\t" +
(m_memory.LastSnapshot.ValidationApproved ? "TRUE" : "FALSE") + "\t" +
m_memory.LastSnapshot.ValidationDecisionReason + "\t" +

IntegerToString(m_memory.LastSnapshot.ValidationTotalSamples) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationApprovedSamples) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationBlockedSamples) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationApprovalRate, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationBlockRate, 2) + "\t" +
m_memory.LastSnapshot.ValidationStatisticsClass + "\t" +
(m_memory.LastSnapshot.ValidationStatisticsReady ? "TRUE" : "FALSE") + "\t" +

IntegerToString(m_memory.LastSnapshot.ValidationEventCount) + "\t" +
m_memory.LastSnapshot.ValidationLastEventType + "\t" +
(m_memory.LastSnapshot.ValidationNewEventDetected ? "TRUE" : "FALSE") + "\t" +

IntegerToString(m_memory.LastSnapshot.ValidationHighQualityEvents) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationMediumQualityEvents) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationLowQualityEvents) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationEventQualityScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationEventQualityClass + "\t" +
(m_memory.LastSnapshot.ValidationEventQualityReady ? "TRUE" : "FALSE") + "\t" +

IntegerToString(m_memory.LastSnapshot.ValidationCriticalEvents) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationMajorEvents) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationMinorEvents) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationEventImpactScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationEventImpactClass + "\t" +
(m_memory.LastSnapshot.ValidationEventImpactReady ? "TRUE" : "FALSE") + "\t" +

IntegerToString(m_memory.LastSnapshot.ValidationStateChanges) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationStableEvents) + "\t" +
IntegerToString(m_memory.LastSnapshot.ValidationUnstableEvents) + "\t" +
DoubleToString(m_memory.LastSnapshot.ValidationStabilityScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationStabilityClass + "\t" +
(m_memory.LastSnapshot.ValidationStabilityReady ? "TRUE" : "FALSE") + "\t" +

DoubleToString(m_memory.LastSnapshot.ValidationMaturityScore, 2) + "\t" +
m_memory.LastSnapshot.ValidationMaturityClass + "\t" +
(m_memory.LastSnapshot.ValidationMature ? "TRUE" : "FALSE") + "\t" +
m_memory.LastSnapshot.ValidationMaturityReason + "\t" +
DoubleToString(m_memory.LastSnapshot.FeatureReliabilityScore, 2) + "\t" +
m_memory.LastSnapshot.FeatureReliabilityClass + "\t" +
(m_memory.LastSnapshot.FeatureReliabilityReady ? "TRUE" : "FALSE") + "\t" +
m_memory.LastSnapshot.FeatureReliabilityReason + "\t" +
DoubleToString(m_memory.LastSnapshot.StructureFeatureWeight, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.LiquidityFeatureWeight, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.OBFeatureWeight, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.ExecutionFeatureWeight, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.RiskFeatureWeight, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.SetupConfidenceWeight, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.OverallFeatureWeightScore, 2) + "\t" +
m_memory.LastSnapshot.FeatureWeightClass + "\t" +

(m_memory.LastSnapshot.FeatureWeightReady ? "TRUE" : "FALSE") + "\t" +
DoubleToString(m_memory.LastSnapshot.AdaptiveFeatureWeightScore, 2) + "\t" +
m_memory.LastSnapshot.AdaptiveFeatureWeightClass + "\t" +
(m_memory.LastSnapshot.AdaptiveFeatureWeightReady ? "TRUE" : "FALSE") + "\t" +

m_memory.LastSnapshot.AdaptiveFeatureWeightReason + "\t" +
IntegerToString(m_memory.LastSnapshot.HistoricalFeatureTrades) + "\t" +
IntegerToString(m_memory.LastSnapshot.HistoricalFeatureWins) + "\t" +
IntegerToString(m_memory.LastSnapshot.HistoricalFeatureLosses) + "\t" +
DoubleToString(m_memory.LastSnapshot.HistoricalFeatureWinRate, 2) + "\t" +
DoubleToString(m_memory.LastSnapshot.HistoricalFeaturePerformanceScore, 2) + "\t" +
m_memory.LastSnapshot.HistoricalFeaturePerformanceClass + "\t" +
(m_memory.LastSnapshot.HistoricalFeaturePerformanceReady ? "TRUE" : "FALSE");

FileWriteString(fileHandle, row + "\r\n");


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

// STEP106 - Feature Reliability Engine
double featureReliabilityScore = 0.0;
int featureReliabilityCount = 0;

if(m_memory.LastSnapshot.LiquidityScore > 0.0)
   featureReliabilityCount++;

if(m_memory.LastSnapshot.OBScore > 0.0)
   featureReliabilityCount++;

if(m_memory.LastSnapshot.PermissionScore > 0.0)
   featureReliabilityCount++;

if(m_memory.LastSnapshot.ConfluenceScore > 0.0)
   featureReliabilityCount++;

if(m_memory.LastSnapshot.HistoricalSetupConfidence > 0.0)
   featureReliabilityCount++;

featureReliabilityScore = (double)featureReliabilityCount / 5.0 * 100.0;

m_memory.LastSnapshot.FeatureReliabilityScore = featureReliabilityScore;

if(featureReliabilityScore >= 80.0)
{
   m_memory.LastSnapshot.FeatureReliabilityClass = "HIGH_RELIABILITY";
   m_memory.LastSnapshot.FeatureReliabilityReady = true;
   m_memory.LastSnapshot.FeatureReliabilityReason = "FEATURE_SET_STABLE";
}
else if(featureReliabilityScore >= 60.0)
{
   m_memory.LastSnapshot.FeatureReliabilityClass = "MEDIUM_RELIABILITY";
   m_memory.LastSnapshot.FeatureReliabilityReady = false;
   m_memory.LastSnapshot.FeatureReliabilityReason = "FEATURE_SET_PARTIAL";
}
else
{
   m_memory.LastSnapshot.FeatureReliabilityClass = "LOW_RELIABILITY";
   m_memory.LastSnapshot.FeatureReliabilityReady = false;
   m_memory.LastSnapshot.FeatureReliabilityReason = "FEATURE_SET_WEAK";
}

MRH_Log("ML_DATASET_ENGINE",
        "STEP106_FEATURE_RELIABILITY",
        "Score=" + DoubleToString(m_memory.LastSnapshot.FeatureReliabilityScore, 2) +
        " | Class=" + m_memory.LastSnapshot.FeatureReliabilityClass +
        " | Ready=" + (m_memory.LastSnapshot.FeatureReliabilityReady ? "TRUE" : "FALSE") +
        " | Reason=" + m_memory.LastSnapshot.FeatureReliabilityReason);

// STEP107 - Feature Weight Engine
m_memory.LastSnapshot.StructureFeatureWeight = 0.15;
m_memory.LastSnapshot.LiquidityFeatureWeight = 0.20;
m_memory.LastSnapshot.OBFeatureWeight = 0.20;
m_memory.LastSnapshot.ExecutionFeatureWeight = 0.15;
m_memory.LastSnapshot.RiskFeatureWeight = 0.10;
m_memory.LastSnapshot.SetupConfidenceWeight = 0.20;

m_memory.LastSnapshot.OverallFeatureWeightScore =
   (m_memory.LastSnapshot.StructureFeatureWeight +
    m_memory.LastSnapshot.LiquidityFeatureWeight +
    m_memory.LastSnapshot.OBFeatureWeight +
    m_memory.LastSnapshot.ExecutionFeatureWeight +
    m_memory.LastSnapshot.RiskFeatureWeight +
    m_memory.LastSnapshot.SetupConfidenceWeight) * 100.0;

if(m_memory.LastSnapshot.FeatureReliabilityReady)
{
   m_memory.LastSnapshot.FeatureWeightClass = "WEIGHT_PROFILE_READY";
   m_memory.LastSnapshot.FeatureWeightReady = true;
}
else if(m_memory.LastSnapshot.FeatureReliabilityScore >= 60.0)
{
   m_memory.LastSnapshot.FeatureWeightClass = "WEIGHT_PROFILE_PARTIAL";
   m_memory.LastSnapshot.FeatureWeightReady = false;
}
else
{
   m_memory.LastSnapshot.FeatureWeightClass = "WEIGHT_PROFILE_WEAK";
   m_memory.LastSnapshot.FeatureWeightReady = false;
}

MRH_Log("ML_DATASET_ENGINE",
        "STEP107_FEATURE_WEIGHT",
        "Score=" + DoubleToString(m_memory.LastSnapshot.OverallFeatureWeightScore, 2) +
        " | Class=" + m_memory.LastSnapshot.FeatureWeightClass +
        " | Ready=" + (m_memory.LastSnapshot.FeatureWeightReady ? "TRUE" : "FALSE"));
        
        // STEP108 - Adaptive Feature Weight Refinement
double adaptiveWeightMultiplier = 1.0;

if(m_memory.LastSnapshot.FeatureReliabilityScore < 60.0)
   adaptiveWeightMultiplier = 0.50;
else if(m_memory.LastSnapshot.FeatureReliabilityScore < 80.0)
   adaptiveWeightMultiplier = 0.75;
else
   adaptiveWeightMultiplier = 1.00;

m_memory.LastSnapshot.AdaptiveFeatureWeightScore =
   m_memory.LastSnapshot.OverallFeatureWeightScore * adaptiveWeightMultiplier;

if(m_memory.LastSnapshot.AdaptiveFeatureWeightScore >= 80.0)
{
   m_memory.LastSnapshot.AdaptiveFeatureWeightClass = "ADAPTIVE_WEIGHT_STRONG";
   m_memory.LastSnapshot.AdaptiveFeatureWeightReady = true;
   m_memory.LastSnapshot.AdaptiveFeatureWeightReason = "RELIABILITY_SUPPORTS_WEIGHT_PROFILE";
}
else if(m_memory.LastSnapshot.AdaptiveFeatureWeightScore >= 60.0)
{
   m_memory.LastSnapshot.AdaptiveFeatureWeightClass = "ADAPTIVE_WEIGHT_MEDIUM";
   m_memory.LastSnapshot.AdaptiveFeatureWeightReady = false;
   m_memory.LastSnapshot.AdaptiveFeatureWeightReason = "PARTIAL_RELIABILITY_SUPPORT";
}
else
{
   m_memory.LastSnapshot.AdaptiveFeatureWeightClass = "ADAPTIVE_WEIGHT_WEAK";
   m_memory.LastSnapshot.AdaptiveFeatureWeightReady = false;
   m_memory.LastSnapshot.AdaptiveFeatureWeightReason = "INSUFFICIENT_FEATURE_RELIABILITY";
}
   
   MRH_Log("ML_DATASET_ENGINE",
        "STEP108_ADAPTIVE_FEATURE_WEIGHT",
        "Score=" + DoubleToString(m_memory.LastSnapshot.AdaptiveFeatureWeightScore, 2) +
        " | Class=" + m_memory.LastSnapshot.AdaptiveFeatureWeightClass +
        " | Ready=" + (m_memory.LastSnapshot.AdaptiveFeatureWeightReady ? "TRUE" : "FALSE") +
        " | Reason=" + m_memory.LastSnapshot.AdaptiveFeatureWeightReason);
        
   // STEP109 - Historical Feature Performance Engine

if(m_memory.LastSnapshot.Outcome != TRADE_OUTCOME_UNKNOWN)
{
   m_memory.LastSnapshot.HistoricalFeatureTrades++;

   if(m_memory.LastSnapshot.Outcome == TRADE_OUTCOME_WIN)
      m_memory.LastSnapshot.HistoricalFeatureWins++;

   if(m_memory.LastSnapshot.Outcome == TRADE_OUTCOME_LOSS)
      m_memory.LastSnapshot.HistoricalFeatureLosses++;
}

if(m_memory.LastSnapshot.HistoricalFeatureTrades > 0)
{
   m_memory.LastSnapshot.HistoricalFeatureWinRate =
      (100.0 *
       m_memory.LastSnapshot.HistoricalFeatureWins) /
      m_memory.LastSnapshot.HistoricalFeatureTrades;
}
else
{
   m_memory.LastSnapshot.HistoricalFeatureWinRate = 0.0;
}

m_memory.LastSnapshot.HistoricalFeaturePerformanceScore =
   m_memory.LastSnapshot.HistoricalFeatureWinRate;

if(m_memory.LastSnapshot.HistoricalFeaturePerformanceScore >= 60.0)
{
   m_memory.LastSnapshot.HistoricalFeaturePerformanceClass = "FEATURE_HISTORY_STRONG";
   m_memory.LastSnapshot.HistoricalFeaturePerformanceReady = true;
}
else
{
   m_memory.LastSnapshot.HistoricalFeaturePerformanceClass = "FEATURE_HISTORY_BUILDING";
   m_memory.LastSnapshot.HistoricalFeaturePerformanceReady = false;
}

  MRH_Log("ML_DATASET_ENGINE",
        "STEP109_HISTORICAL_FEATURE_PERFORMANCE",
        "Trades=" + IntegerToString(m_memory.LastSnapshot.HistoricalFeatureTrades) +
        " | Wins=" + IntegerToString(m_memory.LastSnapshot.HistoricalFeatureWins) +
        " | Losses=" + IntegerToString(m_memory.LastSnapshot.HistoricalFeatureLosses) +
        " | WinRate=" + DoubleToString(m_memory.LastSnapshot.HistoricalFeatureWinRate, 2) +
        " | Class=" + m_memory.LastSnapshot.HistoricalFeaturePerformanceClass +
        " | Ready=" + (m_memory.LastSnapshot.HistoricalFeaturePerformanceReady ? "TRUE" : "FALSE"));
        
                
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