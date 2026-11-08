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
   
   
   // STEP136.17G12.8U - Stop distance audit only
   // No changes to safety decisions

   int brokerStopsLevel =
      (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   int brokerFreezeLevel =
      (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

   MRH_Log("SAFETY_MANAGER",
           "STEP136_17G12_8U_STOP_DISTANCE_AUDIT",
           "Entry=" + DoubleToString(entry, _Digits) +
           " | SL=" + DoubleToString(sl, _Digits) +
           " | Point=" + DoubleToString(_Point, 5) +
           " | DistancePoints=" + DoubleToString(distancePoints, 1) +
           " | InternalMinPoints=" + DoubleToString(m_minStopDistancePoints, 1) +
           " | BrokerStopsLevel=" + IntegerToString(brokerStopsLevel) +
           " | BrokerFreezeLevel=" + IntegerToString(brokerFreezeLevel));

   
   // STEP136.17G12.8W - Stop geometry audit only
   // No changes to safety decisions

   MqlTick auditTick;
   bool tickValid = SymbolInfoTick(_Symbol, auditTick);

   string direction = "UNKNOWN";
   bool slSideValid = false;
   double marketStopDistancePoints = -1.0;

   if(tickValid && auditTick.bid > 0.0 && auditTick.ask > 0.0)
   {
      if(m_memory.Structure.Bias == BIAS_BULLISH)
      {
         direction = "BUY";
         slSideValid = (sl < auditTick.bid);
         marketStopDistancePoints =
            (auditTick.bid - sl) / _Point;
      }
      else if(m_memory.Structure.Bias == BIAS_BEARISH)
      {
         direction = "SELL";
         slSideValid = (sl > auditTick.ask);
         marketStopDistancePoints =
            (sl - auditTick.ask) / _Point;
      }
   }

   MRH_Log("SAFETY_MANAGER",
           "STEP136_17G12_8W_STOP_GEOMETRY_AUDIT",
           "Direction=" + direction +
           " | Bid=" + DoubleToString(tickValid ? auditTick.bid : 0.0, _Digits) +
           " | Ask=" + DoubleToString(tickValid ? auditTick.ask : 0.0, _Digits) +
           " | Entry=" + DoubleToString(entry, _Digits) +
           " | SL=" + DoubleToString(sl, _Digits) +
           " | SL side valid=" + (slSideValid ? "TRUE" : "FALSE") +
           " | MarketStopDistancePoints=" +
           DoubleToString(marketStopDistancePoints, 1));



   // STEP136.17G12.8Y - Dynamic stop policy shadow audit
   // Audit only: existing 300-point rule remains active

   double dynamicMinPoints =
      MathMax(10.0,
              (double)MathMax(brokerStopsLevel,
                              brokerFreezeLevel));

   bool dynamicStopApproved =
      (tickValid &&
       auditTick.bid > 0.0 &&
       auditTick.ask >= auditTick.bid &&
       slSideValid &&
       marketStopDistancePoints >= dynamicMinPoints);

   bool legacyStopApproved =
      (distancePoints >= m_minStopDistancePoints);

   MRH_Log("SAFETY_MANAGER",
           "STEP136_17G12_8Y_DYNAMIC_STOP_AUDIT",
           "LegacyApproved=" +
           (legacyStopApproved ? "TRUE" : "FALSE") +
           " | DynamicApproved=" +
           (dynamicStopApproved ? "TRUE" : "FALSE") +
           " | MarketDistance=" +
           DoubleToString(marketStopDistancePoints, 1) +
           " | DynamicMin=" +
           DoubleToString(dynamicMinPoints, 1) +
           " | LegacyMin=" +
           DoubleToString(m_minStopDistancePoints, 1));



   


   
   // STEP136.17G12.10A - Dynamic stop execution validation

   if(!tickValid ||
      auditTick.bid <= 0.0 ||
      auditTick.ask < auditTick.bid ||
      !slSideValid)
      return false;

   double spreadPoints =
      (auditTick.ask - auditTick.bid) / _Point;

   double requiredDistancePoints =
      MathMax(dynamicMinPoints, spreadPoints);

   bool stopApproved =
      (marketStopDistancePoints >= requiredDistancePoints);

   MRH_Log("SAFETY_MANAGER",
           "STEP136_17G12_10A_DYNAMIC_STOP_DECISION",
           "Approved=" +
           (stopApproved ? "TRUE" : "FALSE") +
           " | MarketDistance=" +
           DoubleToString(marketStopDistancePoints, 1) +
           " | RequiredDistance=" +
           DoubleToString(requiredDistancePoints, 1) +
           " | Spread=" +
           DoubleToString(spreadPoints, 1));

   return stopApproved;

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

   string accountKey = IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN));
   string dateKey = IntegerToString(dt.year) + "_" +
                    IntegerToString(dt.mon) + "_" +
                    IntegerToString(dt.day);

   string baseKey = "MRHX8_" + accountKey + "_" +
                    IntegerToString(270127) + "_" + dateKey;

   string balanceKey = baseKey + "_BAL";
   string lockKey = baseKey + "_LOCK";

   
if(GlobalVariableCheck(balanceKey))
{
   m_dayStartBalance = GlobalVariableGet(balanceKey);

   MRH_Log("SAFETY_MANAGER",
           "STEP136_10C_BASELINE_SOURCE",
           "Source=RESTORED_FROM_GLOBAL_VARIABLE" +
           StringFormat(" | Balance=%.2f", m_dayStartBalance));
}
else
{
   m_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   if(m_dayStartBalance > 0.0)
   {
      GlobalVariableSet(balanceKey, m_dayStartBalance);
      GlobalVariablesFlush();
   }

   MRH_Log("SAFETY_MANAGER",
           "STEP136_10C_BASELINE_SOURCE",
           "Source=NEW_BASELINE_CREATED" +
           StringFormat(" | Balance=%.2f", m_dayStartBalance));
}


   bool previouslyLocked =
      GlobalVariableCheck(lockKey) &&
      GlobalVariableGet(lockKey) > 0.0;

// STEP136.10D - Synchronize daily loss lock
// with the persisted lock at initialization/day rollover.
m_memory.Safety.DailyLossLimitHit = previouslyLocked;
m_memory.Safety.KillSwitch = previouslyLocked;


   m_memory.Safety.DailyLossPercent = 0.0;

   MRH_Log("SAFETY_MANAGER",
           "STEP136_10B_BASELINE",
           "DayStartBalance=" + DoubleToString(m_dayStartBalance, 2) +
           " | RestoredLock=" + (previouslyLocked ? "TRUE" : "FALSE") +
           " | Date=" + dateKey);
           
           
MRH_Log("SAFETY_MANAGER",
        "STEP136_10H_ROLLOVER_AUDIT",
        "Date=" + dateKey +
        " | KillSwitch=" +
        (m_memory.Safety.KillSwitch ? "TRUE" : "FALSE") +
        " | DailyLossLimitHit=" +
        (m_memory.Safety.DailyLossLimitHit ? "TRUE" : "FALSE"));

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

// STEP136.10B - Persist daily loss lock
MqlDateTime lockDate;
TimeToStruct(TimeCurrent(), lockDate);

string lockKey =
   "MRHX8_" +
   IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
   "_270127_" +
   IntegerToString(lockDate.year) + "_" +
   IntegerToString(lockDate.mon) + "_" +
   IntegerToString(lockDate.day) +
   "_LOCK";

GlobalVariableSet(lockKey, 1.0);
GlobalVariablesFlush();

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
