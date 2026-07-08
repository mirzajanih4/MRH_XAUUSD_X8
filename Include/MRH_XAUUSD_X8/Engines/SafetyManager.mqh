#ifndef MRH_SAFETY_MANAGER_MQH
#define MRH_SAFETY_MANAGER_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

class CSafetyManager
{
private:
   CSharedMemory* m_memory;
int m_maxSpreadPoints;
double m_minStopDistancePoints;
double m_dailyLossLimitPercent;
double m_dayStartBalance;
int    m_dayOfYear;


public:
  
  CSafetyManager()
{
   m_memory = NULL;
   m_maxSpreadPoints = 80;
   m_minStopDistancePoints = 300;

   // STEP127B - Daily Loss Guard
   m_dailyLossLimitPercent = 2.0;
   m_dayStartBalance = 0.0;
   m_dayOfYear = -1;
}

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("SAFETY_MANAGER", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("SAFETY_MANAGER", "INIT", "Initialized with SharedMemory");
      return true;
   }
bool IsXAUUSDSymbol()
{
   string symbol = _Symbol;

   if(StringFind(symbol, "XAUUSD") >= 0)
      return true;

   if(StringFind(symbol, "GOLD") >= 0)
      return true;

   return false;
}
bool IsSpreadAllowed()
{
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   if(spread <= m_maxSpreadPoints)
      return true;

   return false;
}
bool IsStopDistanceAllowed()
{
   if(m_memory == NULL)
      return false;

   if(!m_memory.Execution.EntrySignal)
      return false;

   double entry = m_memory.Execution.EntryPrice;
   double sl    = m_memory.Execution.StopLoss;

   if(entry <= 0.0 || sl <= 0.0)
      return false;

   double distancePoints = MathAbs(entry - sl) / _Point;

   if(distancePoints >= m_minStopDistancePoints)
      return true;

   return false;
}

void UpdateDailyLossGuard()
{
   if(m_memory == NULL)
      return;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(m_dayOfYear != dt.day_of_year || m_dayStartBalance <= 0.0)
   {
      m_dayOfYear = dt.day_of_year;
      m_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_memory.Safety.DailyLossPercent = 0.0;
      m_memory.Safety.DailyLossLimitHit = false;
   }

   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   if(m_dayStartBalance <= 0.0)
      return;

   double lossMoney = m_dayStartBalance - currentBalance;

   if(lossMoney < 0.0)
      lossMoney = 0.0;

   m_memory.Safety.DailyLossPercent =
      (lossMoney / m_dayStartBalance) * 100.0;

MRH_Log("SAFETY_MANAGER",
        "STEP127_DAILY_LOSS_STATUS",
        "DayStartBalance=" + DoubleToString(m_dayStartBalance, 2) +
        " | CurrentBalance=" + DoubleToString(currentBalance, 2) +
        " | DailyLossPercent=" + DoubleToString(m_memory.Safety.DailyLossPercent, 2) +
        " | Limit=" + DoubleToString(m_dailyLossLimitPercent, 2) +
        " | Hit=" + (m_memory.Safety.DailyLossLimitHit ? "TRUE" : "FALSE"));

   if(m_memory.Safety.DailyLossPercent >= m_dailyLossLimitPercent)
   {
      m_memory.Safety.DailyLossLimitHit = true;
      m_memory.Safety.KillSwitch = true;

      MRH_Log("SAFETY_MANAGER",
              "STEP127_DAILY_LOSS_BLOCK",
              "DailyLossPercent=" + DoubleToString(m_memory.Safety.DailyLossPercent, 2) +
              " | Limit=" + DoubleToString(m_dailyLossLimitPercent, 2) +
              " | Action=KILL_SWITCH_ON");
   }
}

void UpdateTradingAllowed()
{
   if(m_memory == NULL)
      return;

   if(m_memory.Safety.KillSwitch)
   {
      m_memory.Safety.TradingAllowed = false;
      MRH_Log("SAFETY_MANAGER", "BLOCKED", "KillSwitch is active");
      return;
   }

   if(m_memory.Safety.SymbolAllowed &&
      m_memory.Safety.SpreadAllowed &&
      m_memory.Safety.StopDistanceAllowed)
   {
      m_memory.Safety.TradingAllowed = true;
      MRH_Log("SAFETY_MANAGER", "ALLOWED", "Trading allowed by safety layer");
      return;
   }

   m_memory.Safety.TradingAllowed = false;
}
void DebugSafetyState()
{
   if(m_memory == NULL)
      return;

   string symbolText = "false";
   string spreadText = "false";
   string stopText   = "false";
   string killText   = "false";
   string tradeText  = "false";

   if(m_memory.Safety.SymbolAllowed)
      symbolText = "true";

   if(m_memory.Safety.SpreadAllowed)
      spreadText = "true";

   if(m_memory.Safety.StopDistanceAllowed)
      stopText = "true";

   if(m_memory.Safety.KillSwitch)
      killText = "true";

   if(m_memory.Safety.TradingAllowed)
      tradeText = "true";

   MRH_Log("SAFETY_MANAGER",
           "DEBUG",
           "Symbol=" + symbolText +
           " | Spread=" + spreadText +
           " | StopDistance=" + stopText +
          " | KillSwitch=" + killText +
" | TradingAllowed=" + tradeText +
" | DailyLossPercent=" + DoubleToString(m_memory.Safety.DailyLossPercent, 2) +
" | DailyLossLimitHit=" + (m_memory.Safety.DailyLossLimitHit ? "true" : "false"));
}
   void Update()
   {
      if(m_memory == NULL)
      {
         return;
      }
      
      // STEP127D - Update daily loss guard first
UpdateDailyLossGuard();

if(m_memory.Safety.DailyLossLimitHit)
{
   m_memory.Safety.TradingAllowed = false;
   MRH_Log("SAFETY_MANAGER", "BLOCKED", "Daily loss limit hit");
   return;
}
      
if(IsXAUUSDSymbol())
{
   m_memory.Safety.SymbolAllowed = true;
}
else
{
   m_memory.Safety.SymbolAllowed  = false;
   m_memory.Safety.TradingAllowed = false;

   MRH_Log("SAFETY_MANAGER", "BLOCKED", "Symbol is not allowed for XAUUSD EA");
   return;
}
if(IsSpreadAllowed())
{
   m_memory.Safety.SpreadAllowed = true;
}
else
{
   m_memory.Safety.SpreadAllowed  = false;
   m_memory.Safety.TradingAllowed = false;

   MRH_Log("SAFETY_MANAGER", "BLOCKED", "Spread is too high");
   return;
}
if(IsStopDistanceAllowed())
{
   m_memory.Safety.StopDistanceAllowed = true;
}
else
{
   m_memory.Safety.StopDistanceAllowed = false;
   m_memory.Safety.TradingAllowed      = false;

   MRH_Log("SAFETY_MANAGER", "BLOCKED", "Stop distance is not allowed");
   return;
}
UpdateTradingAllowed();
DebugSafetyState();
   MRH_Log("SAFETY_MANAGER", "UPDATE", "New bar update");
   }
};

#endif