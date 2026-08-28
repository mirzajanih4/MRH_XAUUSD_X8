#ifndef MRH_LIQUIDITY_ENGINE_MQH
#define MRH_LIQUIDITY_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

class CLiquidityEngine
{
private:
   CSharedMemory* m_memory;

public:
   CLiquidityEngine()
   {
      m_memory = NULL;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("LIQUIDITY_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }
// STEP134.9A - External Sweep Event Memory Initialization
m_memory.Liquidity.ExternalBuySweepActive = false;
m_memory.Liquidity.ExternalBuySweepLevel  = 0.0;
m_memory.Liquidity.ExternalBuySweepTime   = 0;

m_memory.Liquidity.ExternalSellSweepActive = false;
m_memory.Liquidity.ExternalSellSweepLevel  = 0.0;
m_memory.Liquidity.ExternalSellSweepTime   = 0;
// STEP135.3 - External Displacement State Initialization
m_memory.Liquidity.ExternalBuyDisplacementConfirmed  = false;
m_memory.Liquidity.ExternalBuyDisplacementTime       = 0;

m_memory.Liquidity.ExternalSellDisplacementConfirmed = false;
m_memory.Liquidity.ExternalSellDisplacementTime      = 0;
      MRH_Log("LIQUIDITY_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }

  void DetectEqualHighLow()
{
   if(m_memory == NULL)
      return;

   // STEP134.6C - Dual External Candidate Audit
   bool externalBuyCandidateFound  = false;
   bool externalSellCandidateFound = false;

   m_memory.Liquidity.EqualHighDetected = false;
   m_memory.Liquidity.EqualLowDetected  = false;
   m_memory.Liquidity.EqualHighLevel    = 0.0;
   m_memory.Liquidity.EqualLowLevel     = 0.0;
   m_memory.Liquidity.PoolStrength = LIQUIDITY_WEAK;
   m_memory.Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
   m_memory.Liquidity.LiquidityRank = 1;
   m_memory.Liquidity.ExternalLiquidityQualified = false;
   m_memory.Liquidity.ExternalLiquidityLevel = 0.0;
   m_memory.Liquidity.ExternalLiquiditySide = EXTERNAL_SIDE_UNKNOWN;
   m_memory.Liquidity.ExternalLiquidityStructureAligned = false;
   m_memory.Liquidity.ExternalLiquidityLocationQualified = false;
   m_memory.Liquidity.ExternalLiquidityStrength = LIQUIDITY_WEAK;
   m_memory.Liquidity.ExternalLiquidityRank = 0;
// STEP134.7B - Independent External Candidate Runtime Reset
m_memory.Liquidity.ExternalBuyCandidateQualified = false;
m_memory.Liquidity.ExternalBuyCandidateLevel = 0.0;
m_memory.Liquidity.ExternalBuyCandidateStrength = LIQUIDITY_WEAK;
m_memory.Liquidity.ExternalBuyCandidateRank = 0;

m_memory.Liquidity.ExternalSellCandidateQualified = false;
m_memory.Liquidity.ExternalSellCandidateLevel = 0.0;
m_memory.Liquidity.ExternalSellCandidateStrength = LIQUIDITY_WEAK;
m_memory.Liquidity.ExternalSellCandidateRank = 0;

   double tolerancePrice = 100 * _Point;
   int bars = Bars(_Symbol, _Period);

   if(bars < 12)
      return;

   for(int i = 2; i <= 10; i++)
   {
      double highA = iHigh(_Symbol, _Period, i);
      double highB = iHigh(_Symbol, _Period, i + 1);

      if(MathAbs(highA - highB) <= tolerancePrice)
      {
         m_memory.Liquidity.EqualHighDetected = true;
         m_memory.Liquidity.EqualHighLevel = (highA + highB) / 2.0;

         if(i >= 6)
         {
            externalBuyCandidateFound = true;
m_memory.Liquidity.ExternalBuyCandidateQualified = true;
m_memory.Liquidity.ExternalBuyCandidateLevel =
   m_memory.Liquidity.EqualHighLevel;
            m_memory.Liquidity.LiquidityType = EXTERNAL_LIQUIDITY;
            m_memory.Liquidity.ExternalLiquidityQualified = true;
            m_memory.Liquidity.ExternalLiquidityLevel =
               m_memory.Liquidity.EqualHighLevel;
            m_memory.Liquidity.ExternalLiquiditySide =
               EXTERNAL_SIDE_BUY;
         }
         else
         {
            m_memory.Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
         }

         double diff = MathAbs(highA - highB);

         if(diff <= 20 * _Point)
            m_memory.Liquidity.PoolStrength = LIQUIDITY_STRONG;
         else if(diff <= 50 * _Point)
            m_memory.Liquidity.PoolStrength = LIQUIDITY_MEDIUM;
         else
            m_memory.Liquidity.PoolStrength = LIQUIDITY_WEAK;

         m_memory.Liquidity.LiquidityRank = 1;

         if(m_memory.Liquidity.LiquidityType == EXTERNAL_LIQUIDITY)
            m_memory.Liquidity.LiquidityRank += 3;

         if(m_memory.Liquidity.PoolStrength == LIQUIDITY_MEDIUM)
            m_memory.Liquidity.LiquidityRank += 1;
         else if(m_memory.Liquidity.PoolStrength == LIQUIDITY_STRONG)
            m_memory.Liquidity.LiquidityRank += 2;

         // STEP134.5C - Preserve External BUY candidate state
         if(m_memory.Liquidity.ExternalLiquidityQualified &&
            m_memory.Liquidity.ExternalLiquiditySide == EXTERNAL_SIDE_BUY)
         {
            m_memory.Liquidity.ExternalLiquidityStrength =
               m_memory.Liquidity.PoolStrength;

            m_memory.Liquidity.ExternalLiquidityRank =
               m_memory.Liquidity.LiquidityRank;
               m_memory.Liquidity.ExternalBuyCandidateStrength =
   m_memory.Liquidity.PoolStrength;

m_memory.Liquidity.ExternalBuyCandidateRank =
   m_memory.Liquidity.LiquidityRank;
         }

         break;
      }
   }

   for(int i = 2; i <= 10; i++)
   {
      double lowA = iLow(_Symbol, _Period, i);
      double lowB = iLow(_Symbol, _Period, i + 1);

      if(MathAbs(lowA - lowB) <= tolerancePrice)
      {
         m_memory.Liquidity.EqualLowDetected = true;
         m_memory.Liquidity.EqualLowLevel = (lowA + lowB) / 2.0;

         if(i >= 6)
         {
            externalSellCandidateFound = true;
m_memory.Liquidity.ExternalSellCandidateQualified = true;
m_memory.Liquidity.ExternalSellCandidateLevel =
   m_memory.Liquidity.EqualLowLevel;
            m_memory.Liquidity.LiquidityType = EXTERNAL_LIQUIDITY;
            m_memory.Liquidity.ExternalLiquidityQualified = true;
            m_memory.Liquidity.ExternalLiquidityLevel =
               m_memory.Liquidity.EqualLowLevel;
            m_memory.Liquidity.ExternalLiquiditySide =
               EXTERNAL_SIDE_SELL;
         }
         else
         {
            m_memory.Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
         }

         double diff = MathAbs(lowA - lowB);

         if(diff <= 20 * _Point)
            m_memory.Liquidity.PoolStrength = LIQUIDITY_STRONG;
         else if(diff <= 50 * _Point)
            m_memory.Liquidity.PoolStrength = LIQUIDITY_MEDIUM;
         else
            m_memory.Liquidity.PoolStrength = LIQUIDITY_WEAK;

         m_memory.Liquidity.LiquidityRank = 1;

         if(m_memory.Liquidity.LiquidityType == EXTERNAL_LIQUIDITY)
            m_memory.Liquidity.LiquidityRank += 3;

         if(m_memory.Liquidity.PoolStrength == LIQUIDITY_MEDIUM)
            m_memory.Liquidity.LiquidityRank += 1;
         else if(m_memory.Liquidity.PoolStrength == LIQUIDITY_STRONG)
            m_memory.Liquidity.LiquidityRank += 2;

         // STEP134.5C - Preserve External SELL candidate state
         if(m_memory.Liquidity.ExternalLiquidityQualified &&
            m_memory.Liquidity.ExternalLiquiditySide == EXTERNAL_SIDE_SELL)
         {
            m_memory.Liquidity.ExternalLiquidityStrength =
               m_memory.Liquidity.PoolStrength;

            m_memory.Liquidity.ExternalLiquidityRank =
               m_memory.Liquidity.LiquidityRank;
               m_memory.Liquidity.ExternalSellCandidateStrength =
   m_memory.Liquidity.PoolStrength;

m_memory.Liquidity.ExternalSellCandidateRank =
   m_memory.Liquidity.LiquidityRank;
         }

         break;
      }
   }

   // STEP134.3H - External state consistency
   if(m_memory.Liquidity.ExternalLiquidityQualified)
   {
      m_memory.Liquidity.LiquidityType = EXTERNAL_LIQUIDITY;
   }
   else
   {
      m_memory.Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
   }

   // STEP134.6A - Directional Structure Alignment
   m_memory.Liquidity.ExternalLiquidityStructureAligned = false;

   if(m_memory.Liquidity.ExternalLiquidityQualified)
   {
      if(m_memory.Structure.Bias == BIAS_BULLISH &&
         m_memory.Liquidity.ExternalLiquiditySide == EXTERNAL_SIDE_BUY)
      {
         m_memory.Liquidity.ExternalLiquidityStructureAligned = true;
      }
      else if(m_memory.Structure.Bias == BIAS_BEARISH &&
              m_memory.Liquidity.ExternalLiquiditySide == EXTERNAL_SIDE_SELL)
      {
         m_memory.Liquidity.ExternalLiquidityStructureAligned = true;
      }
   }
   
   // STEP134.6D - Dual External Candidate Runtime Audit
MRH_Log("LIQUIDITY_ENGINE",
        "STEP134_DUAL_EXTERNAL_AUDIT",
        "BuyCandidate=" +
        (externalBuyCandidateFound ? "TRUE" : "FALSE") +
        " | SellCandidate=" +
        (externalSellCandidateFound ? "TRUE" : "FALSE") +
        " | SelectedSide=" +
        EnumToString(m_memory.Liquidity.ExternalLiquiditySide) +
        " | SelectedLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalLiquidityLevel, _Digits));
        
        // STEP134.7D - Independent BUY/SELL Candidate Audit
MRH_Log("LIQUIDITY_ENGINE",
        "STEP134_EXTERNAL_CANDIDATE_STATE_AUDIT",
        "BuyQualified=" +
        (m_memory.Liquidity.ExternalBuyCandidateQualified ? "TRUE" : "FALSE") +
        " | BuyLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalBuyCandidateLevel, _Digits) +
        " | BuyRank=" +
        IntegerToString(m_memory.Liquidity.ExternalBuyCandidateRank) +
        " | BuyStrength=" +
        EnumToString(m_memory.Liquidity.ExternalBuyCandidateStrength) +
        " | SellQualified=" +
        (m_memory.Liquidity.ExternalSellCandidateQualified ? "TRUE" : "FALSE") +
        " | SellLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalSellCandidateLevel, _Digits) +
        " | SellRank=" +
        IntegerToString(m_memory.Liquidity.ExternalSellCandidateRank) +
        " | SellStrength=" +
        EnumToString(m_memory.Liquidity.ExternalSellCandidateStrength) +
        " | Bias=" +
        EnumToString(m_memory.Structure.Bias));
        
}
   void DetectLiquidityLevels()
   {
      if(m_memory == NULL)
         return;
      m_memory.Liquidity.PriorityTarget = false;
      m_memory.Liquidity.BuySideLiquidity  = m_memory.Structure.LastSwingHigh;
      m_memory.Liquidity.SellSideLiquidity = m_memory.Structure.LastSwingLow;

      if(m_memory.Structure.Bias == BIAS_BULLISH)
      {
         m_memory.Liquidity.State = LIQUIDITY_BUY_SIDE;

         if(m_memory.Liquidity.EqualHighDetected &&
            m_memory.Liquidity.EqualHighLevel > 0.0)
            m_memory.Liquidity.TargetLiquidity = m_memory.Liquidity.EqualHighLevel;
         else
            m_memory.Liquidity.TargetLiquidity = m_memory.Liquidity.BuySideLiquidity;
            if(m_memory.Liquidity.LiquidityRank >= 3 &&
            m_memory.Liquidity.TargetLiquidity > 0.0)
{
            m_memory.Liquidity.PriorityTarget = true;
}
      }
      else if(m_memory.Structure.Bias == BIAS_BEARISH)
      {
         m_memory.Liquidity.State = LIQUIDITY_SELL_SIDE;

         if(m_memory.Liquidity.EqualLowDetected &&
            m_memory.Liquidity.EqualLowLevel > 0.0)
            m_memory.Liquidity.TargetLiquidity = m_memory.Liquidity.EqualLowLevel;
         else
            m_memory.Liquidity.TargetLiquidity = m_memory.Liquidity.SellSideLiquidity;
            if(m_memory.Liquidity.LiquidityRank >= 3 &&
   m_memory.Liquidity.TargetLiquidity > 0.0)
{
   m_memory.Liquidity.PriorityTarget = true;
}
      }
      else
      {
         m_memory.Liquidity.State = LIQUIDITY_BALANCED;
         m_memory.Liquidity.TargetLiquidity = 0.0;
         m_memory.Liquidity.LiquidityScore = 0.0;

m_memory.Liquidity.LiquidityScore += m_memory.Liquidity.LiquidityRank * 10.0;

if(m_memory.Liquidity.PriorityTarget)
   m_memory.Liquidity.LiquidityScore += 20.0;

if(m_memory.Liquidity.SweepDetected)
   m_memory.Liquidity.LiquidityScore += 15.0;

if(m_memory.Liquidity.LiquidityScore > 100.0)
   m_memory.Liquidity.LiquidityScore = 100.0;
      }
   }

   void DetectSweep()
   {
      if(m_memory == NULL)
         return;

      m_memory.Liquidity.SweepDetected = false;
      m_memory.Liquidity.SweepType = SWEEP_NONE;

      double highPrice  = iHigh(_Symbol, _Period, 1);
      double lowPrice   = iLow(_Symbol, _Period, 1);
      double closePrice = iClose(_Symbol, _Period, 1);
      double openPrice  = iOpen(_Symbol, _Period, 1);
      // STEP135.5 - Displacement Candle Metrics
double candleRange = highPrice - lowPrice;
double candleBody  = MathAbs(closePrice - openPrice);
double bodyRatio   = (candleRange > 0.0 ? candleBody / candleRange : 0.0);


// STEP135.8 - Sweep Timing Normalization Foundation
datetime currentCandleTime = iTime(_Symbol, _Period, 1);

int buyBarsSinceSweep  = -1;
int sellBarsSinceSweep = -1;



bool buyDirectionAligned  = (closePrice < openPrice);
bool sellDirectionAligned = (closePrice > openPrice);

      // STEP134.8A - Sweep Source Audit
MRH_Log("LIQUIDITY_ENGINE",
        "STEP134_SWEEP_SOURCE_AUDIT",
        "HighPrice=" +
        DoubleToString(highPrice, _Digits) +
        " | LowPrice=" +
        DoubleToString(lowPrice, _Digits) +
        " | ClosePrice=" +
        DoubleToString(closePrice, _Digits) +
        " | BuySideLiquidity=" +
        DoubleToString(m_memory.Liquidity.BuySideLiquidity, _Digits) +
        " | SellSideLiquidity=" +
        DoubleToString(m_memory.Liquidity.SellSideLiquidity, _Digits) +
        " | ExternalBuyQualified=" +
        (m_memory.Liquidity.ExternalBuyCandidateQualified ? "TRUE" : "FALSE") +
        " | ExternalBuyLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalBuyCandidateLevel, _Digits) +
        " | ExternalSellQualified=" +
        (m_memory.Liquidity.ExternalSellCandidateQualified ? "TRUE" : "FALSE") +
        " | ExternalSellLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalSellCandidateLevel, _Digits));
        
        // STEP134.8B - External Sweep Candidate Audit
bool externalBuySweepCandidate  = false;
bool externalSellSweepCandidate = false;

// BUY-side external liquidity:
// price trades above the level, then closes back below it
if(m_memory.Liquidity.ExternalBuyCandidateQualified &&
   m_memory.Liquidity.ExternalBuyCandidateLevel > 0.0)
{
   if(highPrice >
      m_memory.Liquidity.ExternalBuyCandidateLevel &&
      closePrice <
      m_memory.Liquidity.ExternalBuyCandidateLevel)
   {
      externalBuySweepCandidate = true;
   }
}

// SELL-side external liquidity:
// price trades below the level, then closes back above it
if(m_memory.Liquidity.ExternalSellCandidateQualified &&
   m_memory.Liquidity.ExternalSellCandidateLevel > 0.0)
{
   if(lowPrice <
      m_memory.Liquidity.ExternalSellCandidateLevel &&
      closePrice >
      m_memory.Liquidity.ExternalSellCandidateLevel)
   {
      externalSellSweepCandidate = true;
   }
}

MRH_Log("LIQUIDITY_ENGINE",
        "STEP134_EXTERNAL_SWEEP_CANDIDATE_AUDIT",
        "BuyCandidateQualified=" +
        (m_memory.Liquidity.ExternalBuyCandidateQualified ? "TRUE" : "FALSE") +
        " | BuyLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalBuyCandidateLevel, _Digits) +
        " | BuySweepCandidate=" +
        (externalBuySweepCandidate ? "TRUE" : "FALSE") +
        " | SellCandidateQualified=" +
        (m_memory.Liquidity.ExternalSellCandidateQualified ? "TRUE" : "FALSE") +
        " | SellLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalSellCandidateLevel, _Digits) +
        " | SellSweepCandidate=" +
        (externalSellSweepCandidate ? "TRUE" : "FALSE") +
        " | High=" +
        DoubleToString(highPrice, _Digits) +
        " | Low=" +
        DoubleToString(lowPrice, _Digits) +
        " | Close=" +
        DoubleToString(closePrice, _Digits));
        
// STEP134.8C - External Level Interaction Audit
string externalBuyInteraction  = "NO_CANDIDATE";
string externalSellInteraction = "NO_CANDIDATE";

// BUY-side External Liquidity
if(m_memory.Liquidity.ExternalBuyCandidateQualified &&
   m_memory.Liquidity.ExternalBuyCandidateLevel > 0.0)
{
   double buyLevel =
      m_memory.Liquidity.ExternalBuyCandidateLevel;

   if(highPrice <= buyLevel)
   {
      externalBuyInteraction = "NO_TOUCH";
   }
  else if(closePrice < buyLevel)
{
   externalBuyInteraction = "SWEPT_AND_REJECTED";

   // STEP134.9B - External BUY Sweep Event Capture
   m_memory.Liquidity.ExternalBuySweepActive = true;
   m_memory.Liquidity.ExternalBuySweepLevel  = buyLevel;
   m_memory.Liquidity.ExternalBuySweepTime   = iTime(_Symbol, _Period, 1);
}
   else
   {
      externalBuyInteraction = "BROKEN_AND_ACCEPTED";
   }
}

// SELL-side External Liquidity
if(m_memory.Liquidity.ExternalSellCandidateQualified &&
   m_memory.Liquidity.ExternalSellCandidateLevel > 0.0)
{
   double sellLevel =
      m_memory.Liquidity.ExternalSellCandidateLevel;

   if(lowPrice >= sellLevel)
   {
      externalSellInteraction = "NO_TOUCH";
   }
   else if(closePrice > sellLevel)
{
   externalSellInteraction = "SWEPT_AND_REJECTED";

   // STEP134.9B - External SELL Sweep Event Capture
   m_memory.Liquidity.ExternalSellSweepActive = true;
   m_memory.Liquidity.ExternalSellSweepLevel  = sellLevel;
   m_memory.Liquidity.ExternalSellSweepTime   = iTime(_Symbol, _Period, 1);
}
   else
   {
      externalSellInteraction = "BROKEN_AND_ACCEPTED";
   }
}

// STEP135.8 - Normalized Bars Since External Sweep
if(m_memory.Liquidity.ExternalBuySweepActive &&
   m_memory.Liquidity.ExternalBuySweepTime > 0)
{
   int buyShift =
      iBarShift(_Symbol,
                _Period,
                m_memory.Liquidity.ExternalBuySweepTime,
                false);

   if(buyShift >= 1)
      buyBarsSinceSweep = buyShift - 1;
}

if(m_memory.Liquidity.ExternalSellSweepActive &&
   m_memory.Liquidity.ExternalSellSweepTime > 0)
{
   int sellShift =
      iBarShift(_Symbol,
                _Period,
                m_memory.Liquidity.ExternalSellSweepTime,
                false);

   if(sellShift >= 1)
      sellBarsSinceSweep = sellShift - 1;
}

// STEP135.10A - External Sweep Memory Expiration

if(m_memory.Liquidity.ExternalBuySweepActive &&
   buyBarsSinceSweep > 2)
{
   m_memory.Liquidity.ExternalBuySweepActive = false;
   m_memory.Liquidity.ExternalBuySweepLevel  = 0.0;
   m_memory.Liquidity.ExternalBuySweepTime   = 0;

   buyBarsSinceSweep = -1;
}

if(m_memory.Liquidity.ExternalSellSweepActive &&
   sellBarsSinceSweep > 2)
{
   m_memory.Liquidity.ExternalSellSweepActive = false;
   m_memory.Liquidity.ExternalSellSweepLevel  = 0.0;
   m_memory.Liquidity.ExternalSellSweepTime   = 0;

   sellBarsSinceSweep = -1;
}


// STEP135.9A - External Displacement Candidate Audit
bool externalBuyDisplacementCandidate  = false;
bool externalSellDisplacementCandidate = false;

// BUY-side liquidity sweep should produce bearish displacement
if(m_memory.Liquidity.ExternalBuySweepActive &&
   buyBarsSinceSweep >= 0 &&
   buyBarsSinceSweep <= 2 &&
   buyDirectionAligned &&
   bodyRatio >= 0.60)
{
   externalBuyDisplacementCandidate = true;
}

// SELL-side liquidity sweep should produce bullish displacement
if(m_memory.Liquidity.ExternalSellSweepActive &&
   sellBarsSinceSweep >= 0 &&
   sellBarsSinceSweep <= 2 &&
   sellDirectionAligned &&
   bodyRatio >= 0.60)
{
   externalSellDisplacementCandidate = true;
}


MRH_Log("LIQUIDITY_ENGINE",
        "STEP134_EXTERNAL_INTERACTION_AUDIT",
        "BuyInteraction=" +
        externalBuyInteraction +
        " | BuyLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalBuyCandidateLevel, _Digits) +
        " | SellInteraction=" +
        externalSellInteraction +
        " | SellLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalSellCandidateLevel, _Digits) +
        " | High=" +
        DoubleToString(highPrice, _Digits) +
        " | Low=" +
        DoubleToString(lowPrice, _Digits) +
        " | Close=" +
        DoubleToString(closePrice, _Digits));


// STEP135.9B - External Displacement Candidate Runtime Audit
MRH_Log("LIQUIDITY_ENGINE",
        "STEP135_DISPLACEMENT_CANDIDATE_AUDIT",
        "BuyCandidate=" +
        string(externalBuyDisplacementCandidate ? "TRUE" : "FALSE") +
        " | BuyBarsSinceSweep=" +
        IntegerToString(buyBarsSinceSweep) +
        " | BuyDirectionAligned=" +
        string(buyDirectionAligned ? "TRUE" : "FALSE") +
        " | SellCandidate=" +
        string(externalSellDisplacementCandidate ? "TRUE" : "FALSE") +
        " | SellBarsSinceSweep=" +
        IntegerToString(sellBarsSinceSweep) +
        " | SellDirectionAligned=" +
        string(sellDirectionAligned ? "TRUE" : "FALSE") +
        " | BodyRatio=" +
        DoubleToString(bodyRatio, 3));

// STEP135.9C - Displacement Threshold Audit
bool buyThresholdAuditEligible =
   (m_memory.Liquidity.ExternalBuySweepActive &&
    buyBarsSinceSweep >= 0 &&
    buyBarsSinceSweep <= 2 &&
    buyDirectionAligned);

bool sellThresholdAuditEligible =
   (m_memory.Liquidity.ExternalSellSweepActive &&
    sellBarsSinceSweep >= 0 &&
    sellBarsSinceSweep <= 2 &&
    sellDirectionAligned);

MRH_Log("LIQUIDITY_ENGINE",
        "STEP135_DISPLACEMENT_THRESHOLD_AUDIT",
        "BuyEligible=" +
        string(buyThresholdAuditEligible ? "TRUE" : "FALSE") +
        " | BuyBarsSinceSweep=" +
        IntegerToString(buyBarsSinceSweep) +
        " | SellEligible=" +
        string(sellThresholdAuditEligible ? "TRUE" : "FALSE") +
        " | SellBarsSinceSweep=" +
        IntegerToString(sellBarsSinceSweep) +
        " | BodyRatio=" +
        DoubleToString(bodyRatio, 3) +
        " | Pass060=" +
        string(bodyRatio >= 0.60 ? "TRUE" : "FALSE") +
        " | Pass055=" +
        string(bodyRatio >= 0.55 ? "TRUE" : "FALSE") +
        " | Pass050=" +
        string(bodyRatio >= 0.50 ? "TRUE" : "FALSE"));


// STEP134.9C - External Sweep Event Memory Audit
MRH_Log("LIQUIDITY_ENGINE",
        "STEP134_EXTERNAL_SWEEP_MEMORY_AUDIT",
        "BuyActive=" +
        string(m_memory.Liquidity.ExternalBuySweepActive ? "TRUE" : "FALSE") +
        " | BuyLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalBuySweepLevel, _Digits) +
        " | BuyTime=" +
        TimeToString(m_memory.Liquidity.ExternalBuySweepTime,
                     TIME_DATE | TIME_MINUTES) +
        " | SellActive=" +
        string(m_memory.Liquidity.ExternalSellSweepActive ? "TRUE" : "FALSE") +
        " | SellLevel=" +
        DoubleToString(m_memory.Liquidity.ExternalSellSweepLevel, _Digits) +
        " | SellTime=" +
        TimeToString(m_memory.Liquidity.ExternalSellSweepTime,
                     TIME_DATE | TIME_MINUTES));
// STEP135.7 - Sweep-to-Displacement Timing Runtime Audit
MRH_Log("LIQUIDITY_ENGINE",
        "STEP135_DISPLACEMENT_METRICS_AUDIT",
        "Open=" +
        DoubleToString(openPrice, _Digits) +
        " | High=" +
        DoubleToString(highPrice, _Digits) +
        " | Low=" +
        DoubleToString(lowPrice, _Digits) +
        " | Close=" +
        DoubleToString(closePrice, _Digits) +
        " | Range=" +
        DoubleToString(candleRange, _Digits) +
        " | Body=" +
        DoubleToString(candleBody, _Digits) +
        " | BodyRatio=" +
        DoubleToString(bodyRatio, 3) +
        " | CurrentCandleTime=" +
        TimeToString(currentCandleTime, TIME_DATE | TIME_MINUTES) +
        " | BuySweepActive=" +
        string(m_memory.Liquidity.ExternalBuySweepActive ? "TRUE" : "FALSE") +
        " | BuyBarsSinceSweep=" +
        IntegerToString(buyBarsSinceSweep) +
        " | BuyDirectionAligned=" +
        string(buyDirectionAligned ? "TRUE" : "FALSE") +
        " | SellSweepActive=" +
        string(m_memory.Liquidity.ExternalSellSweepActive ? "TRUE" : "FALSE") +
        " | SellBarsSinceSweep=" +
        IntegerToString(sellBarsSinceSweep) +
        " | SellDirectionAligned=" +
        string(sellDirectionAligned ? "TRUE" : "FALSE"));

// Legacy Sweep Logic - unchanged
if(m_memory.Liquidity.BuySideLiquidity > 0.0 &&
   highPrice > m_memory.Liquidity.BuySideLiquidity &&
   closePrice < m_memory.Liquidity.BuySideLiquidity)
{
   m_memory.Liquidity.SweepDetected = true;
   m_memory.Liquidity.SweepType = SWEEP_BUY_SIDE;
   m_memory.Liquidity.State = LIQUIDITY_BUY_SIDE;
   return;
}

if(m_memory.Liquidity.SellSideLiquidity > 0.0 &&
   lowPrice < m_memory.Liquidity.SellSideLiquidity &&
   closePrice > m_memory.Liquidity.SellSideLiquidity)
{
   m_memory.Liquidity.SweepDetected = true;
   m_memory.Liquidity.SweepType = SWEEP_SELL_SIDE;
   m_memory.Liquidity.State = LIQUIDITY_SELL_SIDE;
   return;
}
}
 void DebugLiquidityState()
{
   if(m_memory == NULL)
      return;

   string stateText = "BALANCED";

   if(m_memory.Liquidity.State == LIQUIDITY_BUY_SIDE)
      stateText = "BUY_SIDE";
   else if(m_memory.Liquidity.State == LIQUIDITY_SELL_SIDE)
      stateText = "SELL_SIDE";

   string sweepText = m_memory.Liquidity.SweepDetected ? "true" : "false";

   string sweepTypeText = "NONE";

   if(m_memory.Liquidity.SweepType == SWEEP_BUY_SIDE)
      sweepTypeText = "BUY_SIDE";
   else if(m_memory.Liquidity.SweepType == SWEEP_SELL_SIDE)
      sweepTypeText = "SELL_SIDE";

   string eqhText = m_memory.Liquidity.EqualHighDetected ? "true" : "false";
   string eqlText = m_memory.Liquidity.EqualLowDetected ? "true" : "false";

   string poolStrengthText = "WEAK";

   if(m_memory.Liquidity.PoolStrength == LIQUIDITY_MEDIUM)
      poolStrengthText = "MEDIUM";
   else if(m_memory.Liquidity.PoolStrength == LIQUIDITY_STRONG)
      poolStrengthText = "STRONG";

   string liquidityTypeText = "INTERNAL";

   if(m_memory.Liquidity.LiquidityType == EXTERNAL_LIQUIDITY)
      liquidityTypeText = "EXTERNAL";

   string priorityText = "false";

   if(m_memory.Liquidity.PriorityTarget)
      priorityText = "true";

   //==================================================
   // Liquidity Score Calculation
   //==================================================
   m_memory.Liquidity.LiquidityScore = 0.0;

   m_memory.Liquidity.LiquidityScore +=
      m_memory.Liquidity.LiquidityRank * 10.0;

   if(m_memory.Liquidity.PriorityTarget)
      m_memory.Liquidity.LiquidityScore += 20.0;

   if(m_memory.Liquidity.SweepDetected)
      m_memory.Liquidity.LiquidityScore += 15.0;

   if(m_memory.Liquidity.LiquidityScore > 100.0)
      m_memory.Liquidity.LiquidityScore = 100.0;

   MRH_Log("LIQUIDITY_ENGINE",
           "DEBUG",
           "State=" + stateText +
           " | Target=" +
           DoubleToString(m_memory.Liquidity.TargetLiquidity, _Digits) +
           " | Strength=" + poolStrengthText +
           " | Type=" + liquidityTypeText +
           " | Rank=" +
           IntegerToString(m_memory.Liquidity.LiquidityRank) +
           " | Priority=" + priorityText +
           " | Score=" +
           DoubleToString(m_memory.Liquidity.LiquidityScore, 1));

   // STEP134.5D - External Candidate State Isolation Audit
   MRH_Log("LIQUIDITY_ENGINE",
           "STEP134_EXTERNAL_LIQUIDITY_AUDIT",
           "Qualified=" +
           (m_memory.Liquidity.ExternalLiquidityQualified ? "TRUE" : "FALSE") +
           " | Level=" +
           DoubleToString(m_memory.Liquidity.ExternalLiquidityLevel, _Digits) +
           " | Type=" +
           liquidityTypeText +
           " | Rank=" +
           IntegerToString(m_memory.Liquidity.LiquidityRank) +
           " | Strength=" +
           poolStrengthText +
           " | Side=" +
           EnumToString(m_memory.Liquidity.ExternalLiquiditySide) +
           " | StructureAligned=" +
           (m_memory.Liquidity.ExternalLiquidityStructureAligned
            ? "TRUE"
            : "FALSE") +
           " | ExternalRank=" +
           IntegerToString(m_memory.Liquidity.ExternalLiquidityRank) +
           " | ExternalStrength=" +
           EnumToString(m_memory.Liquidity.ExternalLiquidityStrength));

   // STEP134.2A - External Liquidity Relationship Audit
   MRH_Log("LIQUIDITY_ENGINE",
           "STEP134_EXTERNAL_RELATION_AUDIT",
           "ExternalLevel=" +
           DoubleToString(m_memory.Liquidity.ExternalLiquidityLevel, _Digits) +
           " | LastSwingHigh=" +
           DoubleToString(m_memory.Structure.LastSwingHigh, _Digits) +
           " | LastSwingLow=" +
           DoubleToString(m_memory.Structure.LastSwingLow, _Digits) +
           " | TargetLiquidity=" +
           DoubleToString(m_memory.Liquidity.TargetLiquidity, _Digits) +
           " | Bias=" +
           EnumToString(m_memory.Structure.Bias));
}
   void Update()
   {
      if(m_memory == NULL)
         return;

      DetectEqualHighLow();
      DetectLiquidityLevels();
      DetectSweep();
      DebugLiquidityState();

      MRH_Log("LIQUIDITY_ENGINE", "UPDATE", "New bar update");
   }
};

#endif
