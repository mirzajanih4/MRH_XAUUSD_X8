#ifndef MRH_EXECUTION_ENGINE_MQH
#define MRH_EXECUTION_ENGINE_MQH
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
class CExecutionEngine
{
private:
   CSharedMemory* m_memory;

public:
   CExecutionEngine()
   {
      m_memory = NULL;
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
bool HasExecutionPermission()
{
   if(m_memory == NULL)
      return false;

   if(m_memory.Structure.Bias == BIAS_NEUTRAL)
      return false;

   if(m_memory.Structure.State == STRUCTURE_RANGE)
      return false;

   if(!m_memory.OB.Valid)
      return false;

   if(m_memory.OB.Invalidated)
      return false;

   if(m_memory.Liquidity.TargetLiquidity <= 0.0)
      return false;

   return true;
}
void BuildBasicEntrySignal()
{
   if(m_memory == NULL)
      return;

   m_memory.Execution.EntrySignal = false;
   m_memory.Execution.EntryPrice  = 0.0;
   m_memory.Execution.StopLoss    = 0.0;
   m_memory.Execution.TakeProfit  = 0.0;
   m_memory.Execution.Confidence  = 0.0;

   if(!HasExecutionPermission())
      return;

   double closePrice = iClose(_Symbol, _Period, 1);

   if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      m_memory.Execution.EntrySignal = true;
      m_memory.Execution.EntryPrice  = closePrice;
      m_memory.Execution.StopLoss    = m_memory.OB.Low;
      m_memory.Execution.TakeProfit  = m_memory.Liquidity.TargetLiquidity;
      m_memory.Execution.Confidence  = 0.50;
      m_memory.Execution.State       = EXECUTION_READY;

      MRH_Log("EXECUTION_ENGINE", "SIGNAL", "Basic bullish entry signal stored");
      return;
   }

   if(m_memory.Structure.Bias == BIAS_BEARISH)
   {
      m_memory.Execution.EntrySignal = true;
      m_memory.Execution.EntryPrice  = closePrice;
      m_memory.Execution.StopLoss    = m_memory.OB.High;
      m_memory.Execution.TakeProfit  = m_memory.Liquidity.TargetLiquidity;
      m_memory.Execution.Confidence  = 0.50;
      m_memory.Execution.State       = EXECUTION_READY;

      MRH_Log("EXECUTION_ENGINE", "SIGNAL", "Basic bearish entry signal stored");
      return;
   }
}
void DebugExecutionState()
{
   if(m_memory == NULL)
      return;

   string stateText = "BLOCKED";

   if(m_memory.Execution.State == EXECUTION_WAITING)
      stateText = "WAITING";
   else if(m_memory.Execution.State == EXECUTION_READY)
      stateText = "READY";
   else if(m_memory.Execution.State == EXECUTION_TRIGGERED)
      stateText = "TRIGGERED";

   string signalText = "false";

   if(m_memory.Execution.EntrySignal)
      signalText = "true";

   MRH_Log("EXECUTION_ENGINE",
           "DEBUG",
           "State=" + stateText +
           " | Signal=" + signalText +
           " | Entry=" + DoubleToString(m_memory.Execution.EntryPrice, _Digits) +
           " | SL=" + DoubleToString(m_memory.Execution.StopLoss, _Digits) +
           " | TP=" + DoubleToString(m_memory.Execution.TakeProfit, _Digits) +
           " | Confidence=" + DoubleToString(m_memory.Execution.Confidence, 2));
}
   void Update()
   {
      if(m_memory == NULL)
         return;
if(HasExecutionPermission())
{
   m_memory.Execution.State = EXECUTION_WAITING;
   MRH_Log("EXECUTION_ENGINE", "PERMISSION", "Execution permission granted");
}
else
{
   m_memory.Execution.State = EXECUTION_BLOCKED;
   m_memory.Execution.EntrySignal = false;
}
BuildBasicEntrySignal();
DebugExecutionState();
      MRH_Log("EXECUTION_ENGINE", "UPDATE", "New bar update");
   }
};

#endif