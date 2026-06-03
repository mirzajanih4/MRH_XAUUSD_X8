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
struct TradeData
{
   ENUM_TRADE_STATE State;

   bool PartialClosed;
   bool BreakEvenActivated;

   double CurrentRR;
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