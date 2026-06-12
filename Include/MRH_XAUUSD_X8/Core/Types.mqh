#ifndef MRH_TYPES_MQH
#define MRH_TYPES_MQH

//==================================================
// Market Bias
//==================================================
enum ENUM_MARKET_BIAS
{
   BIAS_BULLISH = 0,
   BIAS_BEARISH = 1,
   BIAS_NEUTRAL = 2
};

//==================================================
// Structure State
//==================================================
enum ENUM_STRUCTURE_STATE
{
   STRUCTURE_TRENDING = 0,
   STRUCTURE_TRANSITION = 1,
   STRUCTURE_RANGE = 2
};

//==================================================
// Liquidity State
//==================================================
enum ENUM_LIQUIDITY_STATE
{
   LIQUIDITY_BUY_SIDE = 0,
   LIQUIDITY_SELL_SIDE = 1,
   LIQUIDITY_BALANCED = 2
};

//==================================================
// OB Strength
//==================================================
enum ENUM_OB_STRENGTH
{
   OB_WEAK = 0,
   OB_MEDIUM = 1,
   OB_STRONG = 2,
   OB_INSTITUTIONAL = 3
};

//==================================================
// Execution State
//==================================================
enum ENUM_EXECUTION_STATE
{
   EXECUTION_BLOCKED = 0,
   EXECUTION_WAITING = 1,
   EXECUTION_READY = 2,
   EXECUTION_TRIGGERED = 3
};

//==================================================
// Trade State
//==================================================
enum ENUM_TRADE_STATE
{
   TRADE_NONE = 0,
   TRADE_ACTIVE = 1,
   TRADE_BE = 2,
   TRADE_PARTIAL = 3,
   TRADE_CLOSED = 4
};

//==================================================
// Trade Outcome
//==================================================
enum ENUM_TRADE_OUTCOME
{
   TRADE_OUTCOME_UNKNOWN = 0,
   TRADE_OUTCOME_WIN = 1,
   TRADE_OUTCOME_LOSS = 2,
   TRADE_OUTCOME_BREAKEVEN = 3
};

enum ENUM_MRH_LOSS_CAUSE
{
   MRH_LOSS_CAUSE_NONE = 0,
   MRH_LOSS_CAUSE_STOPLOSS,
   MRH_LOSS_CAUSE_STRUCTURE_FLIP,
   MRH_LOSS_CAUSE_OB_INVALIDATION,
   MRH_LOSS_CAUSE_LIQUIDITY_FAILURE,
   MRH_LOSS_CAUSE_WEAK_EXECUTION,
   MRH_LOSS_CAUSE_SPREAD_OR_COST,
   MRH_LOSS_CAUSE_UNKNOWN
};

enum ENUM_MRH_WIN_CAUSE
{
   MRH_WIN_CAUSE_NONE = 0,
   MRH_WIN_CAUSE_TAKEPROFIT,
   MRH_WIN_CAUSE_LIQUIDITY_TARGET,
   MRH_WIN_CAUSE_OB_REACTION,
   MRH_WIN_CAUSE_STRUCTURE_CONTINUATION,
   MRH_WIN_CAUSE_HIGH_CONFLUENCE,
   MRH_WIN_CAUSE_UNKNOWN
};

//==================================================
// Swing Type
//==================================================
enum ENUM_SWING_TYPE
{
   SWING_NONE = 0,
   SWING_HIGH = 1,
   SWING_LOW = 2
};

//==================================================
// Swing Classification
//==================================================
enum ENUM_SWING_CLASS
{
   SWING_CLASS_NONE = 0,
   SWING_CLASS_HH   = 1,
   SWING_CLASS_HL   = 2,
   SWING_CLASS_LH   = 3,
   SWING_CLASS_LL   = 4
};

//==================================================
// Structure Shared Model
//==================================================
struct StructureData
{
   ENUM_MARKET_BIAS Bias;

   double LastSwingHigh;
   double LastSwingLow;
   double PreviousSwingHigh;
   double PreviousSwingLow;
   datetime LastBOS;
   datetime LastCHOCH;

   ENUM_STRUCTURE_STATE State;

   ENUM_SWING_TYPE  LastSwingType;
   datetime         LastSwingTime;
   datetime         LastProcessedSwingTime;

   ENUM_SWING_CLASS LastSwingClass;
};

//==================================================
// Liquidity Sweep Type
//==================================================
enum ENUM_SWEEP_TYPE
{
   SWEEP_NONE = 0,
   SWEEP_BUY_SIDE = 1,
   SWEEP_SELL_SIDE = 2
};

//==================================================
// Liquidity Pool Strength
//==================================================
enum ENUM_LIQUIDITY_STRENGTH
{
   LIQUIDITY_WEAK = 0,
   LIQUIDITY_MEDIUM = 1,
   LIQUIDITY_STRONG = 2
};

//==================================================
// Liquidity Level Type
//==================================================
enum ENUM_LIQUIDITY_LEVEL_TYPE
{
   INTERNAL_LIQUIDITY = 0,
   EXTERNAL_LIQUIDITY = 1
};

//==================================================
// Liquidity Shared Model
//==================================================
struct LiquidityData
{
   ENUM_LIQUIDITY_STATE State;

   bool SweepDetected;
   ENUM_SWEEP_TYPE SweepType;
   double BuySideLiquidity;
   double SellSideLiquidity;
   bool EqualHighDetected;
   bool EqualLowDetected;

   double EqualHighLevel;
   double EqualLowLevel;
   ENUM_LIQUIDITY_STRENGTH PoolStrength;
   ENUM_LIQUIDITY_LEVEL_TYPE LiquidityType;
   int LiquidityRank;
   bool PriorityTarget;
   double LiquidityScore;
   double TargetLiquidity;
};

//==================================================
// Order Block Shared Model
//==================================================
struct OBData
{
   bool Valid;

   double High;
   double Low;

   ENUM_OB_STRENGTH Strength;
   double OBScore;
   int Freshness;
   bool Mitigated;
   bool Invalidated;
};

//==================================================
// Execution Shared Model
//==================================================
struct ExecutionData
{
   ENUM_EXECUTION_STATE State;

   bool EntrySignal;

   double EntryPrice;
   double StopLoss;
   double TakeProfit;
   double Confidence;
   double PermissionScore;
   double StructureScore;
   double OBScore;
   bool ScoreApproved;
   string ExecutionGrade;
   string ConfidenceLevel;
   double ConfluenceScore;
   double RecommendedRiskPercent;
   string AuditReason;
   
};

//==================================================
// Risk Shared Model
//==================================================
struct RiskData
{
   double RiskPercent;
   double LotSize;
   double CalculatedLotSize;
   bool RiskApproved;
   bool ExecutionRiskApproved;
   string RiskProfile;
   string RiskBlockReason;
   double CurrentDrawdown;
};

//==================================================
// Trade Shared Model
//==================================================
#define EXIT_NONE       "NONE"
#define EXIT_STOPLOSS   "STOPLOSS"
#define EXIT_TAKEPROFIT "TAKEPROFIT"
#define EXIT_TIME       "TIME"
#define EXIT_MANUAL     "MANUAL"

struct TradeData
{
   ENUM_TRADE_STATE State;

   bool PartialClosed;
   bool BreakEvenActivated;
   bool TrailingStopActivated;

   double CurrentRR;
   double BreakEvenRR;
   double PartialCloseRR;

   string ExitReason;

   ENUM_TRADE_OUTCOME Outcome;
   
   ENUM_MRH_LOSS_CAUSE LossCause;
   
   ENUM_MRH_WIN_CAUSE WinCause;
   
   double FinalProfit;
   double FinalRR;
   double ClosePrice;
   datetime CloseTime;
   string TradeLabel;
   string AdvancedLabel;
   string LabelQuality;
   string DynamicQualityLabel;
   string ProbabilityClass;
};

//==================================================
// ML Dataset Row Model
//==================================================
struct MLDataRow
{
   string Scenario;
   double LiquidityScore;
   double OBScore;
   double PermissionScore;
   string ExecutionGrade;
   string ConfidenceLevel;
   double ConfluenceScore;
   double RecommendedRisk;
   string RiskProfile;
   ENUM_TRADE_STATE TradeState;
   string ExitReason;
   double CurrentRR;

   ENUM_TRADE_OUTCOME Outcome;
   
   ENUM_MRH_LOSS_CAUSE LossCause;
   
   ENUM_MRH_WIN_CAUSE WinCause;
   
   double FinalProfit;
   double FinalRR;
   double ClosePrice;
   datetime CloseTime;
   string TradeLabel;
   string AdvancedLabel;
   string LabelQuality;
   string DynamicQualityLabel;
   string ProbabilityClass;
   
   //--- STEP44.1 Architecture Audit Layer
   double ArchitectureAuditScore;
   string ArchitectureAuditClass;
   bool   ArchitectureApproved;
};

//==================================================
// ML Trade Snapshot Model
//==================================================
struct MLTradeSnapshot
{
   datetime SnapshotTime;

   double LiquidityScore;
   double OBScore;
   double PermissionScore;
   double ConfluenceScore;

   string ExecutionGrade;
   string ConfidenceLevel;

   double RecommendedRisk;
   string RiskProfile;

   ENUM_TRADE_STATE TradeState;
   double CurrentRR;
   string ExitReason;

   ENUM_TRADE_OUTCOME Outcome;
 
   ENUM_MRH_LOSS_CAUSE LossCause;
   
   ENUM_MRH_WIN_CAUSE WinCause;
   
   double FinalProfit;
   double FinalRR;
   double ClosePrice;
   datetime CloseTime;
   string TradeLabel;
   string AdvancedLabel;
   string LabelQuality;
   string DynamicQualityLabel;
   string ProbabilityClass;
string OutcomeReadinessClass;
string LabelReadinessClass;
string OutcomeTrackingClass;
string TradeQualityAuditClass;
string TradeLifecycleClass;

   //--- STEP44.2 Architecture Audit Layer
   double ArchitectureAuditScore;
   string ArchitectureAuditClass;
   bool   ArchitectureApproved;
   
   //--- STEP46.1 Dataset Integrity Layer
   double DatasetIntegrityScore;
   string DatasetIntegrityClass;
   bool   DatasetIntegrityApproved;
   
   //--- STEP48 Test Readiness Layer
   double TestReadinessScore;
   string TestReadinessClass;
   bool   TestReady;
   //--- STEP66 Dataset Completeness Audit Layer
   double DatasetCompletenessScore;
   string DatasetCompletenessClass;
   bool   DatasetComplete;
   
   //--- STEP67 Dataset Reliability Layer
double DatasetReliabilityScore;
string DatasetReliabilityClass;
bool   DatasetReliable;

//--- STEP68 Dataset Stability Layer
double DatasetStabilityScore;
string DatasetStabilityClass;
bool   DatasetStable;

//--- STEP69 Dataset Health Layer
double DatasetHealthScore;
string DatasetHealthClass;
bool   DatasetHealthy;

//--- STEP70 Dataset Confidence Layer
double DatasetConfidenceScore;
string DatasetConfidenceClass;
bool   DatasetConfidenceApproved;

//--- STEP71 Dataset Approval Layer
double DatasetApprovalScore;
string DatasetApprovalClass;
bool   DatasetApproved;

//--- STEP72 Dataset Release Readiness Layer
double DatasetReleaseScore;
string DatasetReleaseClass;
bool   DatasetReleaseReady;

// STEP73 - Internal Validation Metrics Foundation
double InternalValidationScore;
string InternalValidationClass;
bool   InternalValidationPassed;
string InternalValidationReason;
int    InternalValidationSampleCount;
int    InternalValidationFailureCount;

// STEP74 - Validation Evidence Collection Layer
int    ValidationPassCount;
int    ValidationWarningCount;
int    ValidationFailCount;
double ValidationEvidenceScore;
string ValidationEvidenceClass;
bool   ValidationEvidenceReady;

// STEP75 - Validation Campaign Tracking Layer
int    ValidationCampaignSampleCount;
int    ValidationCampaignSessionCount;
double ValidationCampaignProgressScore;
string ValidationCampaignStatusClass;
bool   ValidationCampaignReady;

// STEP76 - Validation Performance Tracking Layer
double ValidationSuccessRate;
double ValidationFailureRate;
double ValidationPerformanceScore;
string ValidationPerformanceClass;
bool   ValidationPerformanceReady;

// STEP77 - Validation Certification Layer
double ValidationCertificationScore;
string ValidationCertificationClass;
bool   ValidationCertified;
string ValidationCertificationReason;

// STEP78 - Validation Report Layer
double ValidationReportScore;
string ValidationReportClass;
bool   ValidationReportReady;
string ValidationReportSummary;

// STEP79 - Validation Decision Layer
double ValidationDecisionScore;
string ValidationDecisionClass;
bool   ValidationApproved;
string ValidationDecisionReason;

// STEP80 - Validation Statistics Foundation
int    ValidationTotalSamples;
int    ValidationApprovedSamples;
int    ValidationBlockedSamples;
double ValidationApprovalRate;
double ValidationBlockRate;
string ValidationStatisticsClass;
bool   ValidationStatisticsReady;

// STEP81 - Validation Event Tracking Foundation
int    ValidationEventCount;
string ValidationLastEventType;
bool   ValidationNewEventDetected;

// STEP82 - Validation Event Quality Layer
int    ValidationHighQualityEvents;
int    ValidationMediumQualityEvents;
int    ValidationLowQualityEvents;
double ValidationEventQualityScore;
string ValidationEventQualityClass;
bool   ValidationEventQualityReady;

// STEP83 - Validation Event Impact Layer
int    ValidationCriticalEvents;
int    ValidationMajorEvents;
int    ValidationMinorEvents;
double ValidationEventImpactScore;
string ValidationEventImpactClass;
bool   ValidationEventImpactReady;

// STEP84 - Validation Stability Layer
int    ValidationStateChanges;
int    ValidationStableEvents;
int    ValidationUnstableEvents;
double ValidationStabilityScore;
string ValidationStabilityClass;
bool   ValidationStabilityReady;

// STEP85 - Validation Maturity Layer
double ValidationMaturityScore;
string ValidationMaturityClass;
bool   ValidationMature;
string ValidationMaturityReason;

// STEP86 - Validation Trend Layer
double ValidationTrendScore;
string ValidationTrendClass;
bool   ValidationTrendImproving;

// STEP87 - Validation Confidence Layer
double ValidationConfidenceScore;
string ValidationConfidenceClass;
bool   ValidationConfidenceReady;
string ValidationConfidenceReason;
};

//==================================================
// Safety Shared Model
//==================================================
struct SafetyData
{
   bool SymbolAllowed;
   bool SpreadAllowed;
   bool StopDistanceAllowed;
   bool KillSwitch;
   bool TradingAllowed;
};

#endif