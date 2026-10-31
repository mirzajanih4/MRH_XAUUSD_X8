//+------------------------------------------------------------------+
//| MRH_XAUUSD_X8.mq5                                                |
//| Compile-Safe Baseline                                            |
//+------------------------------------------------------------------+
#property strict
#property version   "1.000"

#include <Trade/Trade.mqh>

#include <MRH_XAUUSD_X8/Core/Types.mqh>
#include <MRH_XAUUSD_X8/Core/Constants.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
#include <MRH_XAUUSD_X8/Core/Utilities.mqh>
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>

#include <MRH_XAUUSD_X8/Engines/StructureEngine.mqh>
#include <MRH_XAUUSD_X8/Engines/LiquidityEngine.mqh>
#include <MRH_XAUUSD_X8/Engines/OBEngine.mqh>
#include <MRH_XAUUSD_X8/Engines/ExecutionEngine.mqh>
#include <MRH_XAUUSD_X8/Engines/RiskManager.mqh>
#include <MRH_XAUUSD_X8/Engines/SafetyManager.mqh>
#include <MRH_XAUUSD_X8/Engines/TradeManagementEngine.mqh>
#include <MRH_XAUUSD_X8/Engines/MLDatasetEngine.mqh>
#include <MRH_XAUUSD_X8/Engines/ArchitectureAuditEngine.mqh>
//--- Inputs
input bool EnableLiveTrading = false;
input int ExecutionCooldownSeconds = 300;
input long MagicNumber = 270127;
//--- Trade object
CTrade Trade;

//--- Engine instances
CSharedMemory           SharedMemory;
CStructureEngine        StructureEngine;
CLiquidityEngine        LiquidityEngine;
COBEngine               OBEngine;
CExecutionEngine        ExecutionEngine;
CRiskManager            RiskManager;
CSafetyManager          SafetyManager;
CTradeManagementEngine  TradeManagementEngine;
CMLDatasetEngine        MLDatasetEngine;
CArchitectureAuditEngine ArchitectureAuditEngine;
datetime LastExecutionTime = 0;
//+------------------------------------------------------------------+
//| Final execution gate                                             |
//+------------------------------------------------------------------+
bool MRH_BrokerSafetyCheck()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "Terminal trading is not allowed");
      return false;
   }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "MQL trading is not allowed");
      return false;
   }

   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "Account trading is not allowed");
      return false;
   }

   
ENUM_SYMBOL_TRADE_MODE symbolTradeMode =
   (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(
      _Symbol, SYMBOL_TRADE_MODE);

if(symbolTradeMode != SYMBOL_TRADE_MODE_FULL)
{
   MRH_Log("BROKER_SAFETY",
           "BLOCKED",
           "Symbol does not allow full trading mode");
   return false;
}

ENUM_ACCOUNT_TRADE_MODE tradeMode =
   (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);

if(tradeMode != ACCOUNT_TRADE_MODE_DEMO)
{
   MRH_Log("BROKER_SAFETY", "BLOCKED", "Only DEMO accounts are allowed");
   return false;
}
   return true;
   }
   
   
bool MRH_StopsSafetyCheck()
{
   double sl = SharedMemory.Execution.StopLoss;
   double tp = SharedMemory.Execution.TakeProfit;

   if(sl <= 0.0 || tp <= 0.0)
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED",
              "SL/TP is invalid");
      return false;
   }

   MqlTick tick;

   if(!SymbolInfoTick(_Symbol, tick) ||
      tick.bid <= 0.0 ||
      tick.ask <= 0.0 ||
      tick.ask < tick.bid)
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED",
              "Invalid market Bid/Ask");
      return false;
   }

   int stopsLevel =
      (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   int freezeLevel =
      (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

   double minDistance =
      MathMax(stopsLevel, freezeLevel) * _Point;

   if(minDistance <= 0.0)
      minDistance = 10 * _Point;

   double slDistance = 0.0;
   double tpDistance = 0.0;

   
   // STEP136.8D - Align safety direction with real order direction
   if(SharedMemory.Structure.Bias == BIAS_BULLISH)
   {
      // BUY: validate SL/TP against current Bid
      slDistance = tick.bid - sl;
      tpDistance = tp - tick.bid;
   }
   else if(SharedMemory.Structure.Bias == BIAS_BEARISH)
   {
      // SELL: validate SL/TP against current Ask
      slDistance = sl - tick.ask;
      tpDistance = tick.ask - tp;
   }
   else
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED",
              "Invalid structure bias for stops safety");
      return false;
   }


   if(slDistance < minDistance ||
      tpDistance < minDistance)
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED",
              "Market-price SL/TP safety failed" +
              StringFormat(
                 " | Bid=%.2f | Ask=%.2f"
                 " | SL=%.2f | TP=%.2f"
                 " | SLDistance=%.2f"
                 " | TPDistance=%.2f"
                 " | MinDistance=%.2f",
                 tick.bid,
                 tick.ask,
                 sl,
                 tp,
                 slDistance,
                 tpDistance,
                 minDistance));
      return false;
   }

   return true;
}

bool MRH_MarginSafetyCheck()
{
   double lot = SharedMemory.Risk.LotSize;

   if(lot <= 0.0)
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "Lot size is invalid for margin check");
      return false;
   }

   ENUM_ORDER_TYPE orderType;

   if(SharedMemory.Structure.Bias == BIAS_BULLISH)
      orderType = ORDER_TYPE_BUY;
   else if(SharedMemory.Structure.Bias == BIAS_BEARISH)
      orderType = ORDER_TYPE_SELL;
   else
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "No valid bias for margin check");
      return false;
   }

   double price = 0.0;

   if(orderType == ORDER_TYPE_BUY)
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   else
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(price <= 0.0)
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "Invalid price for margin check");
      return false;
   }

   double margin = 0.0;

   if(!OrderCalcMargin(orderType, _Symbol, lot, price, margin))
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "OrderCalcMargin failed");
      return false;
   }

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   if(margin > freeMargin)
   {
      MRH_Log("BROKER_SAFETY", "BLOCKED", "Not enough free margin");
      return false;
   }

   return true;
}
bool MRH_ExecutionThrottleCheck()
{
   if(LastExecutionTime == 0)
      return true;

   int elapsed = (int)(TimeCurrent() - LastExecutionTime);

   if(elapsed >= ExecutionCooldownSeconds)
      return true;

   MRH_Log("BROKER_SAFETY", "BLOCKED", "Execution cooldown is active");
   return false;
}
bool MRH_HasOpenPositionByMagic()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);

      if(ticket == 0)
         continue;

      string posSymbol = PositionGetString(POSITION_SYMBOL);
      long posMagic    = PositionGetInteger(POSITION_MAGIC);

      if(posSymbol == _Symbol && posMagic == MagicNumber)
         return true;
   }

   return false;
}


bool MRH_CanExecuteTrade()
{
   // First confirm that a real execution candidate exists
   if(SharedMemory.Execution.State != EXECUTION_READY)
      return false;

   if(!SharedMemory.Execution.EntrySignal)
      return false;

   if(!SharedMemory.Risk.RiskApproved)
      return false;

   if(!SharedMemory.Safety.TradingAllowed)
      return false;

   if(SharedMemory.Risk.LotSize <= 0.0)
      return false;

   if(MRH_HasOpenPositionByMagic())
      return false;

   // Only then run broker-level checks
   if(!MRH_BrokerSafetyCheck())
      return false;

   if(!MRH_StopsSafetyCheck())
      return false;

   if(!MRH_MarginSafetyCheck())
      return false;

   if(!MRH_ExecutionThrottleCheck())
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Dry execution logger                                             |
//+------------------------------------------------------------------+
double MRH_NormalizeVolume(double volume);
void MRH_DryExecutionCheck()
{
   if(!MRH_CanExecuteTrade())
      return;

   // STEP136.9D - Dry-run final volume audit
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double requestedLot = SharedMemory.Risk.LotSize;
   double allowedLot = MathFloor(balance / 1000.0) * 0.01;
   double finalLot = MRH_NormalizeVolume(requestedLot);
   double brokerMinLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   MRH_Log("EXECUTION_LAYER",
           "STEP136_9D_VOLUME_AUDIT",
           "BalanceUSD=" + DoubleToString(balance, 2) +
           " | RequestedLot=" + DoubleToString(requestedLot, 2) +
           " | AllowedLot=" + DoubleToString(allowedLot, 2) +
           " | FinalLot=" + DoubleToString(finalLot, 2) +
           " | BrokerMinLot=" + DoubleToString(brokerMinLot, 2) +
           " | VolumeValid=" + (finalLot > 0.0 && finalLot <= allowedLot + 1e-8 ? "TRUE" : "FALSE"));

   MRH_Log("EXECUTION_LAYER",
           "READY_TO_EXECUTE",
           "DirectionBias=" + IntegerToString((int)SharedMemory.Structure.Bias) +
           " | Lot=" + DoubleToString(SharedMemory.Risk.LotSize, 2) +
           " | Entry=" + DoubleToString(SharedMemory.Execution.EntryPrice, _Digits) +
           " | SL=" + DoubleToString(SharedMemory.Execution.StopLoss, _Digits) +
           " | TP=" + DoubleToString(SharedMemory.Execution.TakeProfit, _Digits));
}

//+------------------------------------------------------------------+
//| Real execution skeleton                                          |
//+------------------------------------------------------------------+

double MRH_NormalizeVolume(double volume)
{
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(minLot <= 0.0 || maxLot < minLot || lotStep <= 0.0)
      return 0.0;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);

   // STEP136.9B - Maximum 0.01 lot per 1000 account currency units
   double allowedLot = MathFloor(balance / 1000.0) * 0.01;

   volume = MathMin(volume, allowedLot);
   volume = MathMin(volume, maxLot);

   if(volume < minLot)
      return 0.0;

   volume = MathFloor((volume + 1e-10) / lotStep) * lotStep;
   volume = NormalizeDouble(volume, 8);

   if(volume < minLot)
      return 0.0;

   return volume;
}


double MRH_NormalizePrice(double price)
{
   return NormalizeDouble(price, _Digits);
}


void MRH_ExecuteTrade()
{


   if(!EnableLiveTrading)
   {
      MRH_Log("EXECUTION_LAYER", "BLOCKED", "Live trading is disabled");
      return;
   }

   if(!MRH_CanExecuteTrade())
      return;

   double lot   = MRH_NormalizeVolume(SharedMemory.Risk.LotSize);
   // STEP136.9C - Reject invalid final order volume
if(lot <= 0.0)
{
   MRH_Log("EXECUTION_LAYER",
           "BLOCKED",
           "Final normalized lot is zero or invalid");
   return;
}
   double sl    = MRH_NormalizePrice(SharedMemory.Execution.StopLoss);
   double tp    = MRH_NormalizePrice(SharedMemory.Execution.TakeProfit);
   string note  = "MRH_XAUUSD_X8";

   bool result = false;

   if(SharedMemory.Structure.Bias == BIAS_BULLISH)
   {
      result = Trade.Buy(lot, _Symbol, 0.0, sl, tp, note);
   }
   else if(SharedMemory.Structure.Bias == BIAS_BEARISH)
   {
      result = Trade.Sell(lot, _Symbol, 0.0, sl, tp, note);
   }
   else
   {
      MRH_Log("EXECUTION_LAYER", "BLOCKED", "No valid direction bias");
      return;
   }

   if(result)
{
   LastExecutionTime = TimeCurrent();

   SharedMemory.Execution.State = EXECUTION_TRIGGERED;
   MRH_Log("EXECUTION_LAYER", "EXECUTED", "Real trade sent successfully");
}
   else
{
   MRH_Log("EXECUTION_LAYER",
           "FAILED",
           "Trade send failed"
           " | Retcode=" + IntegerToString((int)Trade.ResultRetcode()) +
           " | Description=" + Trade.ResultRetcodeDescription() +
           " | Deal=" + IntegerToString((int)Trade.ResultDeal()) +
           " | Order=" + IntegerToString((int)Trade.ResultOrder()) +
           " | Volume=" + DoubleToString(Trade.ResultVolume(), 2) +
           " | Price=" + DoubleToString(Trade.ResultPrice(), _Digits) +
           " | Bid=" + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) +
           " | Ask=" + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits));
}
}

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   MRH_Log("SYSTEM", "INIT", "MRH_XAUUSD_X8 initialization started");

   Trade.SetExpertMagicNumber(270127);
   Trade.SetDeviationInPoints(30);

   SharedMemory.Init();

   StructureEngine.Init(&SharedMemory);
   LiquidityEngine.Init(&SharedMemory);
   OBEngine.Init(&SharedMemory);
   ExecutionEngine.Init(&SharedMemory);
   RiskManager.Init(&SharedMemory);
   SafetyManager.Init(&SharedMemory);
   TradeManagementEngine.Init(&SharedMemory);
   MLDatasetEngine.Init(&SharedMemory);
   ArchitectureAuditEngine.Init(&SharedMemory);
   
   MRH_Log("SYSTEM",
        "INIT_AUDIT",
        "All engines initialized successfully"
        " | SharedMemoryReady=" + IntegerToString((int)SharedMemory.Ready()));
   /*
if(!SharedMemory.Ready())
{
   MRH_Log("SYSTEM",
           "INIT_FAILED",
           "SharedMemory failed to initialize");

   return INIT_FAILED;
}
*/

   MRH_Log("SYSTEM",
           "INIT",
           "MRH_XAUUSD_X8 initialized successfully");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
   MRH_Log("SYSTEM", "DEINIT", "MRH_XAUUSD_X8 stopped");
}

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!SharedMemory.Ready())
   {
      MRH_Log("SYSTEM", "BLOCKED", "SharedMemory not ready");
      return;
   }

   if(MRH_IsNewBar(_Symbol, _Period))
   {
      SharedMemory.BeginUpdateCycle();
      
    MRH_Log("SYSTEM",
        "RUNTIME_CYCLE",
        "UpdateCycle=" + IntegerToString((int)SharedMemory.UpdateCycle));  
      
      StructureEngine.Update();
      LiquidityEngine.Update();
      OBEngine.Update();
      ExecutionEngine.Update();
      RiskManager.Update();
      SafetyManager.Update();
      if(EnableLiveTrading)
   TradeManagementEngine.Update();
      ArchitectureAuditEngine.Update();
      MLDatasetEngine.Update();
      
      if(SharedMemory.LastSnapshot.ArchitectureAuditClass == "NOT_READY")
{
   MRH_Log("SYSTEM",
           "RUNTIME_AUDIT_WARNING",
           "Architecture audit is NOT_READY during runtime"
           " | Score=" + DoubleToString(SharedMemory.LastSnapshot.ArchitectureAuditScore, 2));
}
     MRH_DryExecutionCheck();
MRH_ExecuteTrade();
   }
}