#ifndef MRH_EXECUTION_ENGINE_MQH
#define MRH_EXECUTION_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

class CExecutionEngine
{
private:
   CSharedMemory* m_memory;
   double m_requiredPermissionScore;

void SetPrimaryBlockReason(string reason)
{
   if(m_memory == NULL)
      return;

   if(m_memory.Execution.PrimaryBlockReason == "")
      m_memory.Execution.PrimaryBlockReason = reason;
}

public:
   CExecutionEngine()
   {
      m_memory = NULL;
      m_requiredPermissionScore = 40.0;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("EXECUTION_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("EXECUTION_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }
void CalculatePermissionScore()
{
   if(m_memory == NULL)
      return;

   //==================================
   // Reset
   //==================================
   m_memory.Execution.PermissionScore = 0.0;
   m_memory.Execution.StructureScore  = 0.0;
   m_memory.Execution.OBScore         = 0.0;

   m_memory.Execution.ScoreApproved   = false;
   m_memory.Execution.ExecutionGrade  = "BLOCKED";
   m_memory.Execution.ConfidenceLevel = "LOW";
   m_memory.Execution.PrimaryBlockReason = "";

   //==================================
   // Structure Score
   //==================================
   if(m_memory.Structure.Bias != BIAS_NEUTRAL)
      m_memory.Execution.StructureScore = 20.0;

   //==================================
   // OB Score
   //==================================
  if(m_memory.OB.Valid)
   m_memory.Execution.OBScore = m_memory.OB.OBScore;
   //==================================
   // Final Permission Score
   //==================================
   m_memory.Execution.PermissionScore =
      m_memory.Liquidity.LiquidityScore +
      m_memory.Execution.StructureScore +
      m_memory.Execution.OBScore;

   //==================================
   // Approval
   //==================================
   if(m_memory.Execution.PermissionScore >= m_requiredPermissionScore)
      m_memory.Execution.ScoreApproved = true;

   //==================================
   // Execution Grade
   //==================================
   if(m_memory.Execution.PermissionScore >= 80.0)
      m_memory.Execution.ExecutionGrade = "A_SETUP";
   else if(m_memory.Execution.PermissionScore >= 60.0)
      m_memory.Execution.ExecutionGrade = "B_SETUP";
   else if(m_memory.Execution.PermissionScore >= m_requiredPermissionScore)
      m_memory.Execution.ExecutionGrade = "C_SETUP";

   //==================================
   // Confidence Level
   //==================================
   if(m_memory.Execution.PermissionScore >= 80.0)
      m_memory.Execution.ConfidenceLevel = "HIGH";
   else if(m_memory.Execution.PermissionScore >= 60.0)
      m_memory.Execution.ConfidenceLevel = "MEDIUM";
      m_memory.Execution.ConfluenceScore =
   m_memory.Execution.PermissionScore;

if(m_memory.Execution.ConfidenceLevel == "MEDIUM")
   m_memory.Execution.ConfluenceScore += 5.0;
else if(m_memory.Execution.ConfidenceLevel == "HIGH")
   m_memory.Execution.ConfluenceScore += 10.0;

if(m_memory.Execution.ConfluenceScore > 100.0)
   m_memory.Execution.ConfluenceScore = 100.0;
   m_memory.Execution.RecommendedRiskPercent = 0.0;

if(m_memory.Execution.ConfluenceScore >= 80.0)
   m_memory.Execution.RecommendedRiskPercent = 1.00;
else if(m_memory.Execution.ConfluenceScore >= 60.0)
   m_memory.Execution.RecommendedRiskPercent = 0.75;
else if(m_memory.Execution.ConfluenceScore >= 40.0)
   m_memory.Execution.RecommendedRiskPercent = 0.50;
}


  bool HasExecutionPermission()
{
   if(m_memory == NULL)
      return false;

   if(m_memory.Structure.Bias == BIAS_NEUTRAL)
{
   m_memory.Execution.AuditReason = "NO_STRUCTURE_BIAS";
   SetPrimaryBlockReason("NO_STRUCTURE_BIAS");
   MRH_Log("EXECUTION_ENGINE", "AUDIT", "AuditReason=NO_STRUCTURE_BIAS");
   return false;
}

   if(m_memory.Structure.State == STRUCTURE_RANGE)
{
   m_memory.Execution.AuditReason = "STRUCTURE_RANGE";
   SetPrimaryBlockReason("STRUCTURE_RANGE");
   MRH_Log("EXECUTION_ENGINE", "AUDIT", "AuditReason=STRUCTURE_RANGE");
   return false;
}

  if(!m_memory.OB.Valid)
{
   m_memory.Execution.AuditReason = "NO_VALID_OB";
   MRH_Log("EXECUTION_ENGINE", "AUDIT", "AuditReason=NO_VALID_OB");
   // return false;
}

   if(m_memory.OB.Invalidated)
{
   m_memory.Execution.AuditReason = "OB_INVALIDATED";
   SetPrimaryBlockReason("OB_INVALIDATED");
   MRH_Log("EXECUTION_ENGINE", "AUDIT", "AuditReason=OB_INVALIDATED");
   return false;
}

   if(m_memory.Liquidity.TargetLiquidity <= 0.0)
{
   m_memory.Execution.AuditReason = "NO_TARGET_LIQUIDITY";
   SetPrimaryBlockReason("NO_TARGET_LIQUIDITY");
   MRH_Log("EXECUTION_ENGINE", "AUDIT", "AuditReason=NO_TARGET_LIQUIDITY");
   return false;
}

  if(!m_memory.Execution.ScoreApproved)
{
   m_memory.Execution.AuditReason = "LOW_PERMISSION_SCORE";
   SetPrimaryBlockReason("LOW_PERMISSION_SCORE");
   MRH_Log("EXECUTION_ENGINE", "AUDIT", "AuditReason=LOW_PERMISSION_SCORE");
   return false;
}


// STEP136.1 - Real Entry Decision Audit
MRH_Log("EXECUTION_ENGINE",
        "STEP136_REAL_ENTRY_DECISION_AUDIT",
        "PermissionScore=" +
        DoubleToString(m_memory.Execution.PermissionScore, 1) +
        " | RequiredScore=" +
        DoubleToString(m_requiredPermissionScore, 1) +
        " | ScoreApproved=" +
        string(m_memory.Execution.ScoreApproved ? "TRUE" : "FALSE") +
        " | StructureScore=" +
        DoubleToString(m_memory.Execution.StructureScore, 1) +
        " | LiquidityScore=" +
        DoubleToString(m_memory.Liquidity.LiquidityScore, 1) +
        " | OBScore=" +
        DoubleToString(m_memory.Execution.OBScore, 1) +
        " | OBValid=" +
        string(m_memory.OB.Valid ? "TRUE" : "FALSE") +
        " | ExternalBuyQualified=" +
        string(m_memory.Liquidity.ExternalBuyCandidateQualified ? "TRUE" : "FALSE") +
        " | ExternalSellQualified=" +
        string(m_memory.Liquidity.ExternalSellCandidateQualified ? "TRUE" : "FALSE") +
        " | ExternalBuySweepActive=" +
        string(m_memory.Liquidity.ExternalBuySweepActive ? "TRUE" : "FALSE") +
        " | ExternalSellSweepActive=" +
        string(m_memory.Liquidity.ExternalSellSweepActive ? "TRUE" : "FALSE") +
        " | ExternalBuyDisplacement=" +
        string(m_memory.Liquidity.ExternalBuyDisplacementConfirmed ? "TRUE" : "FALSE") +
        " | ExternalSellDisplacement=" +
        string(m_memory.Liquidity.ExternalSellDisplacementConfirmed ? "TRUE" : "FALSE"));

   m_memory.Execution.AuditReason = "EXECUTION_ALLOWED";
   MRH_Log("EXECUTION_ENGINE", "AUDIT", "AuditReason=EXECUTION_ALLOWED");

   return true;
}

void BuildExecutionSetup()
{
   if(m_memory == NULL)
      return;

   if(!HasExecutionPermission())
      return;
      
if(!m_memory.OB.Valid)
{
   MRH_Log("EXECUTION_ENGINE",
           "SETUP_BLOCKED",
           "Reason=NO_OB_FOR_ENTRY_SL | PermissionApproved=true | Action=WAIT_FOR_VALID_ENTRY_MODEL");

   return;
}

   double riskDistance = 0.0;

   // SELL
   if(m_memory.Structure.Bias == BIAS_BEARISH)
   {
      m_memory.Execution.EntryPrice = m_memory.OB.Low;
      m_memory.Execution.StopLoss   = m_memory.OB.High;

      riskDistance =
         m_memory.Execution.StopLoss -
         m_memory.Execution.EntryPrice;

      m_memory.Execution.TakeProfit =
         m_memory.Execution.EntryPrice -
         (riskDistance * 2.0);
   }

   // BUY
   else if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      m_memory.Execution.EntryPrice = m_memory.OB.High;
      m_memory.Execution.StopLoss   = m_memory.OB.Low;

      riskDistance =
         m_memory.Execution.EntryPrice -
         m_memory.Execution.StopLoss;

      m_memory.Execution.TakeProfit =
         m_memory.Execution.EntryPrice +
         (riskDistance * 2.0);
   }

   if(riskDistance <= 0.0)
{
   MRH_Log("EXECUTION_ENGINE",
           "SETUP_BLOCKED",
           "Reason=INVALID_RISK_DISTANCE"
           " | Entry=" + DoubleToString(m_memory.Execution.EntryPrice, _Digits) +
           " | SL=" + DoubleToString(m_memory.Execution.StopLoss, _Digits) +
           " | OB.Valid=" + IntegerToString((int)m_memory.OB.Valid) +
           " | OB.High=" + DoubleToString(m_memory.OB.High, _Digits) +
           " | OB.Low=" + DoubleToString(m_memory.OB.Low, _Digits));

   return;
}


// STEP131A - Entry Location Audit
double currentMarketPrice = 0.0;

if(m_memory.Structure.Bias == BIAS_BULLISH)
   currentMarketPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
else if(m_memory.Structure.Bias == BIAS_BEARISH)
   currentMarketPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

bool priceInsideOB =
   currentMarketPrice >= m_memory.OB.Low &&
   currentMarketPrice <= m_memory.OB.High;

double distanceToPlannedEntry =
   MathAbs(currentMarketPrice - m_memory.Execution.EntryPrice);


// STEP131B - OB penetration audit
double obRange = m_memory.OB.High - m_memory.OB.Low;
double penetrationPercent = 0.0;

if(obRange > 0.0)
{
   if(m_memory.Structure.Bias == BIAS_BEARISH)
   {
      penetrationPercent =
         ((currentMarketPrice - m_memory.OB.Low) / obRange) * 100.0;
   }
   else if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      penetrationPercent =
         ((m_memory.OB.High - currentMarketPrice) / obRange) * 100.0;
   }
}


MRH_Log("EXECUTION_ENGINE",
        "STEP131A_ENTRY_LOCATION",
        "Bias=" + IntegerToString((int)m_memory.Structure.Bias) +
        " | MarketPrice=" + DoubleToString(currentMarketPrice, _Digits) +
        " | PlannedEntry=" + DoubleToString(m_memory.Execution.EntryPrice, _Digits) +
        " | PlannedSL=" + DoubleToString(m_memory.Execution.StopLoss, _Digits) +
        " | OBHigh=" + DoubleToString(m_memory.OB.High, _Digits) +
        " | OBLow=" + DoubleToString(m_memory.OB.Low, _Digits) +
        " | PriceInsideOB=" + (priceInsideOB ? "TRUE" : "FALSE") +
        " | DistanceToEntry=" + DoubleToString(distanceToPlannedEntry, _Digits) +
        " | PlannedRiskDistance=" + DoubleToString(riskDistance, _Digits) +
        " | Timeframe=" + EnumToString(_Period) +
        " | OBRange=" + DoubleToString(obRange, _Digits) +
        " | PenetrationPercent=" + DoubleToString(penetrationPercent, 2));
        
        
        if(!priceInsideOB)
{
   m_memory.Execution.EntrySignal = false;
   m_memory.Execution.State = EXECUTION_BLOCKED;
   m_memory.Execution.AuditReason = "PRICE_OUTSIDE_OB";

   MRH_Log("EXECUTION_ENGINE",
           "STEP131_ENTRY_BLOCKED",
           "Reason=PRICE_OUTSIDE_OB"
           " | MarketPrice=" + DoubleToString(currentMarketPrice, _Digits) +
           " | OBHigh=" + DoubleToString(m_memory.OB.High, _Digits) +
           " | OBLow=" + DoubleToString(m_memory.OB.Low, _Digits) +
           " | PenetrationPercent=" +
           DoubleToString(penetrationPercent, 2));

   return;
}
        
   m_memory.Execution.EntrySignal = true;
   m_memory.Execution.State = EXECUTION_READY;

   MRH_Log("EXECUTION_ENGINE",
           "READY",
           "Execution setup created");
}

   void Update()
   {
      if(m_memory == NULL)
         return;

      CalculatePermissionScore();
      
           /*
      // STEP49 - Execution Strictness Layer
      // No valid OB = no execution permission, no A_SETUP, no risk
      if(!m_memory.OB.Valid || m_memory.OB.Invalidated)
      {
         ...
      }
*/

      if(HasExecutionPermission())
      {
         m_memory.Execution.State = EXECUTION_WAITING;
         MRH_Log("EXECUTION_ENGINE", "PERMISSION", "Execution permission granted by score");
         BuildExecutionSetup();
      }
      else
      {
         m_memory.Execution.State = EXECUTION_BLOCKED;
         m_memory.Execution.EntrySignal = false;
      }

      MRH_Log("EXECUTION_ENGINE",
              "DEBUG",
              "PermissionScore=" + DoubleToString(m_memory.Execution.PermissionScore, 1) +
              " | ScoreApproved=" + IntegerToString((int)m_memory.Execution.ScoreApproved));

     string detailMessage =
   "LiquidityScore=" + DoubleToString(m_memory.Liquidity.LiquidityScore, 1) +
   " | StructureScore=" + DoubleToString(m_memory.Execution.StructureScore, 1) +
   " | OBScore=" + DoubleToString(m_memory.Execution.OBScore, 1) +
   " | PermissionScore=" + DoubleToString(m_memory.Execution.PermissionScore, 1) +
   " | RequiredScore=" + DoubleToString(m_requiredPermissionScore, 1) +
   " | Grade=" + m_memory.Execution.ExecutionGrade +
   " | Confidence=" + m_memory.Execution.ConfidenceLevel +
   " | ConfluenceScore=" + DoubleToString(m_memory.Execution.ConfluenceScore, 1) +
   " | RecommendedRisk=" + DoubleToString(m_memory.Execution.RecommendedRiskPercent, 2);

MRH_Log("EXECUTION_ENGINE", "DEBUG_DETAIL", detailMessage);

MRH_Log("EXECUTION_ENGINE",
        "STEP123_PRIMARY_BLOCK",
        "AuditReason=" + m_memory.Execution.AuditReason +
        " | PrimaryBlockReason=" + m_memory.Execution.PrimaryBlockReason);
   }
   
   
};

#endif