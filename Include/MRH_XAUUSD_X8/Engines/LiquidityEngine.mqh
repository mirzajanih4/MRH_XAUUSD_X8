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
void DetectLiquidityLevels()
{
   if(m_memory == NULL)
      return;

   m_memory.Liquidity.BuySideLiquidity  = m_memory.Structure.LastSwingHigh;
   m_memory.Liquidity.SellSideLiquidity = m_memory.Structure.LastSwingLow;

   if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      m_memory.Liquidity.State = LIQUIDITY_BUY_SIDE;
      m_memory.Liquidity.TargetLiquidity = m_memory.Liquidity.BuySideLiquidity;
   }
   else if(m_memory.Structure.Bias == BIAS_BEARISH)
   {
      m_memory.Liquidity.State = LIQUIDITY_SELL_SIDE;
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

   double highPrice  = iHigh(_Symbol, _Period, 1);
   double lowPrice   = iLow(_Symbol, _Period, 1);
   double closePrice = iClose(_Symbol, _Period, 1);

   if(m_memory.Liquidity.BuySideLiquidity > 0.0)
   {
      if(highPrice > m_memory.Liquidity.BuySideLiquidity &&
         closePrice < m_memory.Liquidity.BuySideLiquidity)
      {
         m_memory.Liquidity.SweepDetected = true;
         m_memory.Liquidity.State = LIQUIDITY_BUY_SIDE;

         MRH_Log("LIQUIDITY_ENGINE", "SWEEP", "Buy-side liquidity sweep detected");
         return;
      }
   }

   if(m_memory.Liquidity.SellSideLiquidity > 0.0)
   {
      if(lowPrice < m_memory.Liquidity.SellSideLiquidity &&
         closePrice > m_memory.Liquidity.SellSideLiquidity)
      {
         m_memory.Liquidity.SweepDetected = true;
         m_memory.Liquidity.State = LIQUIDITY_SELL_SIDE;

         MRH_Log("LIQUIDITY_ENGINE", "SWEEP", "Sell-side liquidity sweep detected");
         return;
      }
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

   string sweepText = "false";

   if(m_memory.Liquidity.SweepDetected)
      sweepText = "true";

   MRH_Log("LIQUIDITY_ENGINE",
           "DEBUG",
           "State=" + stateText +
           " | BuySide=" + DoubleToString(m_memory.Liquidity.BuySideLiquidity, _Digits) +
           " | SellSide=" + DoubleToString(m_memory.Liquidity.SellSideLiquidity, _Digits) +
           " | Target=" + DoubleToString(m_memory.Liquidity.TargetLiquidity, _Digits) +
           " | Sweep=" + sweepText);
}
   void Update()
   {
      if(m_memory == NULL)
         return;
   DetectLiquidityLevels();
   DetectSweep();
   DebugLiquidityState();
      MRH_Log("LIQUIDITY_ENGINE", "UPDATE", "New bar update");
   }
};

#endif