#ifndef MRH_RISK_MANAGER_MQH
#define MRH_RISK_MANAGER_MQH
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
class CRiskManager
{
private:
   CSharedMemory* m_memory;

public:
   CRiskManager()
   {
      m_memory = NULL;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("RISK_MANAGER", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("RISK_MANAGER", "INIT", "Initialized with SharedMemory");
      return true;
   }
bool HasRiskPermission()
{
   if(m_memory == NULL)
      return false;

   if(!m_memory.Execution.EntrySignal)
      return false;

   if(m_memory.Execution.State != EXECUTION_READY)
      return false;

   if(m_memory.Execution.StopLoss <= 0.0)
      return false;

   if(m_memory.Execution.EntryPrice <= 0.0)
      return false;

   if(m_memory.Execution.TakeProfit <= 0.0)
      return false;

   return true;
}
double CalculateBasicLotSize()
{
   if(m_memory == NULL)
      return 0.0;

   if(!HasRiskPermission())
      return 0.0;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (m_memory.Risk.RiskPercent / 100.0);

   double entry = m_memory.Execution.EntryPrice;
   double sl    = m_memory.Execution.StopLoss;

   double stopDistance = MathAbs(entry - sl);

   if(stopDistance <= 0.0)
      return 0.0;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickValue <= 0.0 || tickSize <= 0.0)
      return 0.0;

   double valuePerLot = stopDistance / tickSize * tickValue;

   if(valuePerLot <= 0.0)
      return 0.0;

   double lot = riskMoney / valuePerLot;

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lot < minLot)
      lot = minLot;

   if(lot > maxLot)
      lot = maxLot;

   lot = MathFloor(lot / lotStep) * lotStep;

   return lot;
}
void DebugRiskState()
{
   if(m_memory == NULL)
      return;

   string approvedText = "false";

   if(m_memory.Risk.RiskApproved)
      approvedText = "true";

   MRH_Log("RISK_MANAGER",
           "DEBUG",
           "Approved=" + approvedText +
           " | RiskPercent=" + DoubleToString(m_memory.Risk.RiskPercent, 2) +
           " | LotSize=" + DoubleToString(m_memory.Risk.LotSize, 2) +
           " | Drawdown=" + DoubleToString(m_memory.Risk.CurrentDrawdown, 2));
}
   void Update()
   {
      if(m_memory == NULL)
         return;
if(HasRiskPermission())
{
   m_memory.Risk.RiskApproved = true;
   m_memory.Risk.RiskPercent  = 0.50;
   m_memory.Risk.LotSize = CalculateBasicLotSize();
   MRH_Log("RISK_MANAGER", "APPROVED", "Risk permission granted");
}
else
{
   m_memory.Risk.LotSize = 0.0;
   m_memory.Risk.RiskApproved = false;
}
   DebugRiskState();
      MRH_Log("RISK_MANAGER", "UPDATE", "New bar update");
   }
};

#endif