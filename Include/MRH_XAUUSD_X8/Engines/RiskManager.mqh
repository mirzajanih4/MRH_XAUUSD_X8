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

double rawLot = riskMoney / valuePerLot;

// STEP126B - Risk Audit Log
MRH_Log("RISK_MANAGER",
        "STEP126B_RISK_AUDIT",
        "Balance=" + DoubleToString(balance, 2) +
        " | RiskPercent=" + DoubleToString(m_memory.Risk.RiskPercent, 2) +
        " | RiskMoney=" + DoubleToString(riskMoney, 2) +
        " | Entry=" + DoubleToString(entry, _Digits) +
        " | SL=" + DoubleToString(sl, _Digits) +
        " | StopDistance=" + DoubleToString(stopDistance, _Digits) +
        " | TickValue=" + DoubleToString(tickValue, 5) +
        " | TickSize=" + DoubleToString(tickSize, _Digits) +
        " | ValuePerLot=" + DoubleToString(valuePerLot, 2) +
        " | RawLot=" + DoubleToString(rawLot, 4));

   double lot = rawLot;
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lot < minLot)
   lot = minLot;

// STEP128A - XAUUSD balance-based volume cap
// Rule: max 0.01 lot per 1000 account balance
double balanceLotCap = (balance / 1000.0) * 0.01;

if(balanceLotCap < minLot)
   balanceLotCap = minLot;

if(lot > balanceLotCap)
   lot = balanceLotCap;

if(lot > maxLot)
   lot = maxLot;

lot = MathFloor(lot / lotStep) * lotStep;

MRH_Log("RISK_MANAGER",
        "STEP128A_VOLUME_CAP",
        "Balance=" + DoubleToString(balance, 2) +
        " | RawLot=" + DoubleToString(rawLot, 4) +
        " | BalanceLotCap=" + DoubleToString(balanceLotCap, 4) +
        " | FinalLot=" + DoubleToString(lot, 2));

return lot;
}
void DebugRiskState()
{
   if(m_memory == NULL)
      return;

   string approvedText = "false";

   if(m_memory.Risk.RiskApproved)
      approvedText = "true";
string executionRiskText = "false";

if(m_memory.Risk.ExecutionRiskApproved)
   executionRiskText = "true";
   
   MRH_Log("RISK_MANAGER",
           "DEBUG",
           "Approved=" + approvedText +
           " | ExecutionRiskApproved=" + executionRiskText +
           " | RecommendedRisk=" + DoubleToString(m_memory.Execution.RecommendedRiskPercent, 2) +
           " | RiskPercent=" + DoubleToString(m_memory.Risk.RiskPercent, 2) +
           " | RiskProfile=" + m_memory.Risk.RiskProfile +
           " | BlockReason=" + m_memory.Risk.RiskBlockReason +
           " | LotSize=" + DoubleToString(m_memory.Risk.LotSize, 2) +
           " | CalculatedLotSize=" + DoubleToString(m_memory.Risk.CalculatedLotSize, 2) +
           " | Drawdown=" + DoubleToString(m_memory.Risk.CurrentDrawdown, 2));
}
  void Update()
{
   if(m_memory == NULL)
      return;

   m_memory.Risk.RiskApproved = false;
   m_memory.Risk.ExecutionRiskApproved = false;
   m_memory.Risk.RiskBlockReason = "NONE";

   if(HasRiskPermission())
   {
      m_memory.Risk.RiskApproved = true;
      m_memory.Risk.ExecutionRiskApproved = true;
      
      // STEP126A - Emergency demo risk cap
m_memory.Risk.RiskPercent = m_memory.Execution.RecommendedRiskPercent;

if(m_memory.Risk.RiskPercent > 0.50)
   m_memory.Risk.RiskPercent = 0.50;

      m_memory.Risk.RiskProfile = "NO_RISK";

      if(m_memory.Execution.ConfluenceScore >= 80.0)
         m_memory.Risk.RiskProfile = "LOW_RISK";
      else if(m_memory.Execution.ConfluenceScore >= 60.0)
         m_memory.Risk.RiskProfile = "MEDIUM_RISK";
      else if(m_memory.Execution.ConfluenceScore >= 40.0)
         m_memory.Risk.RiskProfile = "HIGH_RISK";

      m_memory.Risk.LotSize = CalculateBasicLotSize();
      m_memory.Risk.CalculatedLotSize = m_memory.Risk.LotSize;

      MRH_Log("RISK_MANAGER", "APPROVED", "Risk permission granted");
   }
   else
   {
      m_memory.Risk.RiskBlockReason = "NO_EXECUTION_PERMISSION";
      m_memory.Risk.LotSize = 0.0;
      m_memory.Risk.CalculatedLotSize = 0.0;
      m_memory.Risk.RiskApproved = false;
      m_memory.Risk.ExecutionRiskApproved = false;
      m_memory.Risk.RiskPercent = 0.0;
      m_memory.Risk.RiskProfile = "NO_RISK";
   }

   DebugRiskState();

   MRH_Log("RISK_MANAGER", "UPDATE", "New bar update");
}
};
#endif