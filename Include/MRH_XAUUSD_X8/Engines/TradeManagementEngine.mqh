#ifndef MRH_TRADE_MANAGEMENT_ENGINE_MQH
#define MRH_TRADE_MANAGEMENT_ENGINE_MQH
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
class CTradeManagementEngine
{
private:
   CSharedMemory* m_memory;

public:
   CTradeManagementEngine()
   {
      m_memory = NULL;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("TRADE_MANAGEMENT_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("TRADE_MANAGEMENT_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }
void UpdateTradeStateMemory()
{
   if(m_memory == NULL)
      return;

   if(m_memory.Risk.RiskApproved &&
      m_memory.Execution.EntrySignal &&
      m_memory.Execution.State == EXECUTION_READY)
   {
      m_memory.Trade.State = TRADE_ACTIVE;

      MRH_Log("TRADE_MANAGEMENT_ENGINE", "STATE", "Virtual trade state activated");
      return;
   }

   m_memory.Trade.State = TRADE_NONE;
}
void CalculateCurrentRR()
{
   if(m_memory == NULL)
      return;

   m_memory.Trade.CurrentRR = 0.0;

   if(m_memory.Trade.State != TRADE_ACTIVE)
      return;

   double entry = m_memory.Execution.EntryPrice;
   double sl    = m_memory.Execution.StopLoss;

   if(entry <= 0.0 || sl <= 0.0)
      return;

   double riskDistance = MathAbs(entry - sl);

   if(riskDistance <= 0.0)
      return;

   double currentPrice = iClose(_Symbol, _Period, 1);

   if(m_memory.Structure.Bias == BIAS_BULLISH)
      m_memory.Trade.CurrentRR = (currentPrice - entry) / riskDistance;

   else if(m_memory.Structure.Bias == BIAS_BEARISH)
      m_memory.Trade.CurrentRR = (entry - currentPrice) / riskDistance;
}
void DebugTradeState()
{
   if(m_memory == NULL)
      return;

   string stateText = "NONE";

   if(m_memory.Trade.State == TRADE_ACTIVE)
      stateText = "ACTIVE";
   else if(m_memory.Trade.State == TRADE_BE)
      stateText = "BE";
   else if(m_memory.Trade.State == TRADE_PARTIAL)
      stateText = "PARTIAL";
   else if(m_memory.Trade.State == TRADE_CLOSED)
      stateText = "CLOSED";

   string partialText = "false";
   string beText      = "false";
   string exitReasonText = m_memory.Trade.ExitReason;
   if(m_memory.Trade.PartialClosed)
      partialText = "true";

   if(m_memory.Trade.BreakEvenActivated)
      beText = "true";

  MRH_Log("TRADE_MANAGEMENT_ENGINE",
        "DEBUG",
        "State=" + stateText +
" | RR=" + DoubleToString(m_memory.Trade.CurrentRR, 2) +
" | BreakEvenRR=" + DoubleToString(m_memory.Trade.BreakEvenRR, 2) +
" | Partial=" + partialText +
        " | BE=" + beText +
        " | ExitReason=" + exitReasonText);
}
   void Update()
   {
      if(m_memory == NULL)
         return;
         if(m_memory.Trade.State == TRADE_ACTIVE)
{
   if(!m_memory.Trade.BreakEvenActivated &&
      m_memory.Trade.CurrentRR >= m_memory.Trade.BreakEvenRR)
   {
      m_memory.Trade.BreakEvenActivated = true;
      m_memory.Trade.State = TRADE_BE;

      MRH_Log("TRADE_MANAGEMENT_ENGINE",
              "BREAK_EVEN",
              "Break Even activated");
   }
}
   UpdateTradeStateMemory();
   CalculateCurrentRR();
   DebugTradeState();
      MRH_Log("TRADE_MANAGEMENT_ENGINE", "UPDATE", "New bar update");
   }
};

#endif