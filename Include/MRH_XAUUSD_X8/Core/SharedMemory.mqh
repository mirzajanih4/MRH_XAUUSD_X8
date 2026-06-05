#ifndef MRH_SHARED_MEMORY_MQH
#define MRH_SHARED_MEMORY_MQH
#include <MRH_XAUUSD_X8/Core/Types.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
//==================================================
// Central Shared Memory
//==================================================
class CSharedMemory
{
public:
   StructureData  Structure;
   LiquidityData  Liquidity;
   OBData         OB;
   ExecutionData  Execution;
   RiskData       Risk;
   TradeData      Trade;
   SafetyData Safety;
   //==================================================
// Last Trade Snapshot
//==================================================
MLTradeSnapshot LastSnapshot;

   bool           IsInitialized;
   long           UpdateCycle;

public:
   CSharedMemory()
   {
      IsInitialized = false;
      UpdateCycle   = 0;
   }

   bool Init()
   {
      Reset();

      IsInitialized = true;
      UpdateCycle   = 0;

      MRH_Log("SHARED_MEMORY", "INIT", "Initialized");
      return true;
   }

   void Reset()
   {
      Structure.Bias          = BIAS_NEUTRAL;
      Structure.LastSwingHigh = 0.0;
      Structure.LastSwingLow  = 0.0;
      Structure.PreviousSwingHigh = 0.0;
      Structure.PreviousSwingLow  = 0.0;
      Structure.LastBOS       = 0;
      Structure.LastCHOCH     = 0;
      Structure.State         = STRUCTURE_RANGE;
      Structure.LastSwingType = SWING_NONE;
      Structure.LastSwingTime = 0;
      Structure.LastProcessedSwingTime = 0;
      Structure.LastSwingClass = SWING_CLASS_NONE;
      Liquidity.State             = LIQUIDITY_BALANCED;
      Liquidity.SweepDetected     = false;
      Liquidity.SweepType         = SWEEP_NONE;
      Liquidity.BuySideLiquidity  = 0.0;
      Liquidity.SellSideLiquidity = 0.0;
      Liquidity.EqualHighDetected = false;
      Liquidity.EqualLowDetected  = false;

      Liquidity.EqualHighLevel = 0.0;
      Liquidity.EqualLowLevel  = 0.0;
      Liquidity.PoolStrength = LIQUIDITY_WEAK;
      Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
      Liquidity.LiquidityRank = 0;
      Liquidity.PriorityTarget = false;
      Liquidity.LiquidityScore = 0.0;
      Liquidity.TargetLiquidity   = 0.0;

      OB.Valid       = false;
      OB.High        = 0.0;
      OB.Low         = 0.0;
      OB.Strength    = OB_WEAK;
      OB.OBScore = 0.0;
      OB.Freshness = 0;
      OB.Mitigated   = false;
      OB.Invalidated = false;

      Execution.State       = EXECUTION_BLOCKED;
      Execution.EntrySignal = false;
      Execution.EntryPrice  = 0.0;
      Execution.StopLoss    = 0.0;
      Execution.TakeProfit  = 0.0;
      Execution.Confidence  = 0.0;
      Execution.PermissionScore = 0.0;
      Execution.StructureScore = 0.0;
      Execution.OBScore = 0.0;
      Execution.ScoreApproved = false;
      Execution.ExecutionGrade = "BLOCKED";
      Execution.ConfidenceLevel = "LOW";
      Execution.ConfluenceScore = 0.0;
      Execution.RecommendedRiskPercent = 0.0;
      Risk.RiskPercent     = 0.0;
      Risk.LotSize         = 0.0;
      Risk.CalculatedLotSize = 0.0;
      Risk.RiskApproved    = false;
      Risk.ExecutionRiskApproved = false;
      Risk.RiskProfile = "NO_RISK";
      Risk.RiskBlockReason = "NONE";
      Risk.CurrentDrawdown = 0.0;

      Trade.State              = TRADE_NONE;
      Trade.PartialClosed      = false;
      Trade.BreakEvenActivated = false;
      Trade.TrailingStopActivated = false;
      Trade.CurrentRR          = 0.0;
      Trade.BreakEvenRR = 1.0;
      Trade.PartialCloseRR = 2.0;
      Trade.ExitReason = "NONE";
      Trade.Outcome    = TRADE_OUTCOME_UNKNOWN;
      Trade.FinalProfit = 0.0;
      Trade.FinalRR     = 0.0;
      Trade.ClosePrice  = 0.0;
      Trade.CloseTime   = 0;
      Trade.TradeLabel = "UNLABELED";
      LastSnapshot.SnapshotTime = 0;

      LastSnapshot.LiquidityScore = 0.0;
      LastSnapshot.OBScore = 0.0;
      LastSnapshot.PermissionScore = 0.0;
      LastSnapshot.ConfluenceScore = 0.0;

      LastSnapshot.ExecutionGrade = "";
      LastSnapshot.ConfidenceLevel = "";

      LastSnapshot.RecommendedRisk = 0.0;
      LastSnapshot.RiskProfile = "";

      LastSnapshot.TradeState = TRADE_NONE;
      LastSnapshot.CurrentRR = 0.0;
      LastSnapshot.ExitReason = "NONE";
      LastSnapshot.Outcome     = TRADE_OUTCOME_UNKNOWN;
      LastSnapshot.FinalProfit = 0.0;
      LastSnapshot.FinalRR     = 0.0;
      LastSnapshot.ClosePrice  = 0.0;
      LastSnapshot.CloseTime   = 0;
      LastSnapshot.TradeLabel = "UNLABELED";
      Safety.SymbolAllowed       = false;
      Safety.SpreadAllowed       = false;
      Safety.StopDistanceAllowed = false;
      Safety.KillSwitch          = false;
      Safety.TradingAllowed      = false;
   }

   bool Ready()
   {
      return IsInitialized;
   }

   void BeginUpdateCycle()
   {
      UpdateCycle++;
   }
};

#endif