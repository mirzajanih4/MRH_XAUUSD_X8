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

      MRH_Log("LIQUIDITY_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }

   void DetectEqualHighLow()
   {
      if(m_memory == NULL)
         return;

      m_memory.Liquidity.EqualHighDetected = false;
      m_memory.Liquidity.EqualLowDetected  = false;
      m_memory.Liquidity.EqualHighLevel    = 0.0;
      m_memory.Liquidity.EqualLowLevel     = 0.0;
      m_memory.Liquidity.PoolStrength = LIQUIDITY_WEAK;
      m_memory.Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
      m_memory.Liquidity.LiquidityRank = 1;
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
   m_memory.Liquidity.LiquidityType = EXTERNAL_LIQUIDITY;
else
   m_memory.Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
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
   m_memory.Liquidity.LiquidityType = EXTERNAL_LIQUIDITY;
else
   m_memory.Liquidity.LiquidityType = INTERNAL_LIQUIDITY;
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
break;
         }
      }
   }

   void DetectLiquidityLevels()
   {
      if(m_memory == NULL)
         return;

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
      }
      else if(m_memory.Structure.Bias == BIAS_BEARISH)
      {
         m_memory.Liquidity.State = LIQUIDITY_SELL_SIDE;

         if(m_memory.Liquidity.EqualLowDetected &&
            m_memory.Liquidity.EqualLowLevel > 0.0)
            m_memory.Liquidity.TargetLiquidity = m_memory.Liquidity.EqualLowLevel;
         else
            m_memory.Liquidity.TargetLiquidity = m_memory.Liquidity.SellSideLiquidity;
      }
      else
      {
         m_memory.Liquidity.State = LIQUIDITY_BALANCED;
         m_memory.Liquidity.TargetLiquidity = 0.0;
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
 MRH_Log("LIQUIDITY_ENGINE",
        "DEBUG",
        "State=" + stateText +
        " | Target=" + DoubleToString(m_memory.Liquidity.TargetLiquidity, _Digits) +
        " | Strength=" + poolStrengthText +
        " | Type=" + liquidityTypeText +
        " | Rank=" + IntegerToString(m_memory.Liquidity.LiquidityRank));
  
  
           
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