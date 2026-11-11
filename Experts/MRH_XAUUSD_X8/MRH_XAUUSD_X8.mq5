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


   // STEP136.17G12.8P - Final execution gate audit only
   // No changes to execution permissions

   if(SharedMemory.Execution.State == EXECUTION_READY ||
      SharedMemory.Execution.EntrySignal)
   {
      MRH_Log("EXECUTION_LAYER",
              "STEP136_17G12_8P_GATE_AUDIT",
              "State=" +
              IntegerToString((int)SharedMemory.Execution.State) +
              " | EntrySignal=" +
              (SharedMemory.Execution.EntrySignal ? "TRUE" : "FALSE") +
              " | RiskApproved=" +
              (SharedMemory.Risk.RiskApproved ? "TRUE" : "FALSE") +
              " | TradingAllowed=" +
              (SharedMemory.Safety.TradingAllowed ? "TRUE" : "FALSE") +
              " | LotSize=" +
              DoubleToString(SharedMemory.Risk.LotSize, 2) +
              " | OpenPosition=" +
              (MRH_HasOpenPositionByMagic() ? "TRUE" : "FALSE"));
   }


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

   
   // STEP136.17G12.9P - Real execution path audit only

   if(!MRH_CanExecuteTrade())
   {
      MRH_Log("EXECUTION_LAYER",
              "STEP136_17G12_9P_EXEC_PATH_AUDIT",
              "FinalGate=BLOCKED");
      return;
   }

   MRH_Log("EXECUTION_LAYER",
           "STEP136_17G12_9P_EXEC_PATH_AUDIT",
           "FinalGate=PASSED");


   // STEP136.17G12.10F.3 - Pre-send consumed BOS audit
   // Audit only - does not block execution

   datetime currentBOS = SharedMemory.Structure.LastBOS;

   // STEP136.17G12.10F.5H11.3K.1
   // Fail closed when no confirmed BOS identity exists after restart
   if(currentBOS <= 0)
   {
      MRH_Log("EXECUTION_LAYER",
              "STEP136_17G12_10F_5H11_3K_1_NO_BOS_BLOCK",
              "Reason=NO_CONFIRMED_BOS");
      return;
   }

   if(currentBOS > 0)
   {
   
      // STEP136.17G12.10F.5H11.3C
      // Prevent execution using a BOS opposite to current bias

      if(SharedMemory.Structure.LastBOSDirection !=
         SharedMemory.Structure.Bias)
      {
         MRH_Log(
            "EXECUTION_LAYER",
            "STEP136_17G12_10F_5H11_3C_DIRECTION_MISMATCH_BLOCK",
            "Bias=" +
            EnumToString(SharedMemory.Structure.Bias) +
            " | BOSDirection=" +
            EnumToString(SharedMemory.Structure.LastBOSDirection) +
            " | CurrentBOS=" +
            TimeToString(currentBOS,
                         TIME_DATE | TIME_MINUTES)
         );

         return;
      }

   
      string bosKey =
         "MRHX8_BOS_" +
         IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
         "_" + IntegerToString(MagicNumber) +
         "_" + _Symbol +
         "_" + IntegerToString((int)_Period) +
         "_" + IntegerToString((int)SharedMemory.Structure.Bias);

      bool previouslyStored = GlobalVariableCheck(bosKey);
      datetime storedBOS = 0;

      // STEP136.17G12.10F.5H11.3K.2
      // Reject invalid legacy BOS timestamps without modifying Global Variables
      if(previouslyStored)
   {
      double storedBOSValue = GlobalVariableGet(bosKey);

      storedBOS = (datetime)(long)storedBOSValue;

      if(storedBOSValue < (double)D'2000.01.01 00:00' ||
      storedBOSValue > (double)TimeCurrent())
   {
      MRH_Log(
         "EXECUTION_LAYER",
         "STEP136_17G12_10F_5H11_3K_2_LEGACY_LOCK_BLOCK",
         "Key=" + bosKey +
         " | Value=" + DoubleToString(storedBOSValue, 2) +
         " | Reason=INVALID_BOS_TIMESTAMP"
      );

      return;
   }
}


      bool sameConsumedBOS =
         (previouslyStored && storedBOS == currentBOS);
         
         
         
      // STEP136.17G12.10F.5H11.2
      // Cross-timeframe entry read audit only

      string crossTFReadKey =
         "MRHX8_CTF_ENTRY_" +
         IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
         "_" + IntegerToString(MagicNumber) +
         "_" + _Symbol +
         "_" + IntegerToString(
            (int)SharedMemory.Structure.LastBOSDirection);

      bool crossTFEntryExists =
         GlobalVariableCheck(crossTFReadKey);

      datetime crossTFEntryTime = 0;

      if(crossTFEntryExists)
         crossTFEntryTime =
            (datetime)(long)GlobalVariableGet(crossTFReadKey);

      MRH_Log(
         "EXECUTION_LAYER",
         "STEP136_17G12_10F_5H11_2_CTF_READ_AUDIT",
         "TF=" + EnumToString(_Period) +
         " | Bias=" + EnumToString(SharedMemory.Structure.Bias) +
" | BOSDirection=" + EnumToString(SharedMemory.Structure.LastBOSDirection) +
         " | CTFExists=" +
         (crossTFEntryExists ? "TRUE" : "FALSE") +
         " | CTFEntryTime=" +
         (crossTFEntryExists
            ? TimeToString(crossTFEntryTime,
                           TIME_DATE | TIME_SECONDS)
            : "NONE") +
         " | SameTFStored=" +
         (previouslyStored ? "TRUE" : "FALSE")
      );

         
         

      MRH_Log("EXECUTION_LAYER",
              "STEP136_17G12_10F_3_PRE_SEND_BOS_AUDIT",
              "CurrentBOS=" +
              TimeToString(currentBOS, TIME_DATE | TIME_MINUTES) +
              " | StoredBOS=" +
              TimeToString(storedBOS, TIME_DATE | TIME_MINUTES) +
              " | PreviouslyStored=" +
              (previouslyStored ? "TRUE" : "FALSE") +
              " | SameConsumedBOS=" +
              (sameConsumedBOS ? "TRUE" : "FALSE"));



      // STEP136.17G12.10F.5H4
      // Previous confirmed entry time audit only

      string entryTimeKey = bosKey + "_ENTRY_TIME";

      bool previousEntryStored =
         GlobalVariableCheck(entryTimeKey);

      datetime previousEntryTime = 0;

      if(previousEntryStored)
         previousEntryTime =
            (datetime)(long)GlobalVariableGet(entryTimeKey);

      datetime sourceSwingTime =
         SharedMemory.Structure.LastBOSSourceSwingTime;

      bool sourceSwingAfterEntry =
         (previousEntryStored &&
          previousEntryTime > 0 &&
          sourceSwingTime > previousEntryTime);

      bool bosAfterEntry =
         (previousEntryStored &&
          previousEntryTime > 0 &&
          currentBOS > previousEntryTime);

      MRH_Log("EXECUTION_LAYER",
              "STEP136_17G12_10F_5H4_ENTRY_TIME_AUDIT",
              "PreviousEntryStored=" +
              (previousEntryStored ? "TRUE" : "FALSE") +
              " | PreviousEntryTime=" +
              TimeToString(previousEntryTime,
                           TIME_DATE | TIME_SECONDS) +
              " | CurrentBOS=" +
              TimeToString(currentBOS,
                           TIME_DATE | TIME_MINUTES) +
              " | SourceSwingTime=" +
              TimeToString(sourceSwingTime,
                           TIME_DATE | TIME_MINUTES) +
              " | SourceSwingAfterEntry=" +
              (sourceSwingAfterEntry ? "TRUE" : "FALSE") +
            
            
            
" | BOSAfterEntry=" +
(bosAfterEntry ? "TRUE" : "FALSE") +
" | LastInvalidationTime=" +
TimeToString(
   SharedMemory.Structure.LastStructureInvalidationTime,
   TIME_DATE | TIME_MINUTES) +
" | InvalidationAfterEntry=" +
((previousEntryStored &&
  previousEntryTime > 0 &&
  SharedMemory.Structure.LastStructureInvalidationTime >
     previousEntryTime) ? "TRUE" : "FALSE"));




    
      // STEP136.17G12.10F.5H11.3B
      // Conservative cross-timeframe structural rearm

     
      // STEP136.17G12.10F.5H11.3E
      // Prefer the latest confirmed entry reference

      bool crossTFOnly =
         crossTFEntryExists &&
         crossTFEntryTime > 0 &&
         (!previousEntryStored ||
          previousEntryTime <= 0 ||
          crossTFEntryTime > previousEntryTime);


      if((previouslyStored && !sameConsumedBOS) ||
         crossTFOnly)
      {
         datetime referenceEntryTime =
            crossTFOnly
            ? crossTFEntryTime
            : previousEntryTime;

         bool referenceEntryStored =
            crossTFOnly
            ? crossTFEntryExists
            : previousEntryStored;

         datetime pullbackSwingTime = 0;

         if(SharedMemory.Structure.Bias == BIAS_BULLISH)
            pullbackSwingTime =
               SharedMemory.Structure.LastSwingLowTime;

         else if(SharedMemory.Structure.Bias == BIAS_BEARISH)
            pullbackSwingTime =
               SharedMemory.Structure.LastSwingHighTime;

         bool structuralRearmApproved =
            referenceEntryStored &&
            referenceEntryTime > 0 &&
            (crossTFOnly || currentBOS > storedBOS) &&
            currentBOS > referenceEntryTime &&
            sourceSwingTime > referenceEntryTime &&
            sourceSwingTime < currentBOS &&
            pullbackSwingTime > referenceEntryTime &&
            pullbackSwingTime < currentBOS &&
            SharedMemory.Structure.LastBOSDirection ==
               SharedMemory.Structure.Bias &&
            SharedMemory.Structure.State ==
               STRUCTURE_TRENDING;

         if(!structuralRearmApproved)
         {
            MRH_Log(
               "EXECUTION_LAYER",
               "STEP136_17G12_10F_5H11_3B_REARM_BLOCK",
               "Reason=NO_CONFIRMED_NEW_STRUCTURE_CYCLE" +
               " | Source=" +
               (crossTFOnly ? "CROSS_TF" : "SAME_TF") +
               " | CurrentBOS=" +
               TimeToString(currentBOS,
                            TIME_DATE | TIME_MINUTES) +
               " | PreviousEntry=" +
               TimeToString(referenceEntryTime,
                            TIME_DATE | TIME_MINUTES) +
               " | SourceSwing=" +
               TimeToString(sourceSwingTime,
                            TIME_DATE | TIME_MINUTES) +
               " | PullbackSwing=" +
               TimeToString(pullbackSwingTime,
                            TIME_DATE | TIME_MINUTES));

            return;
         }
      }


      // STEP136.17G12.10F.4
      // Block repeated execution of a consumed BOS

      if(sameConsumedBOS)
      {
         MRH_Log("EXECUTION_LAYER",
                 "STEP136_17G12_10F_4_DUPLICATE_BOS_BLOCK",
                 "BOS=" +
                 TimeToString(currentBOS,
                              TIME_DATE | TIME_MINUTES) +
                 " | Reason=ALREADY_CONSUMED");

         return;
      }
   }



   double lot = MRH_NormalizeVolume(SharedMemory.Risk.LotSize);

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
   
   
   
   // STEP136.17G12.9J - Market execution risk guard
   // Protect risk budget before sending an order

   MqlTick executionTick;

   if(!SymbolInfoTick(_Symbol, executionTick) ||
      executionTick.bid <= 0.0 ||
      executionTick.ask < executionTick.bid)
   {
      MRH_Log("EXECUTION_LAYER",
              "RISK_BLOCKED",
              "Invalid execution tick");
      return;
   }

   ENUM_ORDER_TYPE riskOrderType;
   double worstCaseEntry = 0.0;

   // 30 points matches current trade deviation setting
   double slippageBuffer = 30.0 * _Point;

   if(SharedMemory.Structure.Bias == BIAS_BULLISH)
   {
      riskOrderType = ORDER_TYPE_BUY;
      worstCaseEntry = executionTick.ask + slippageBuffer;
   }
   else if(SharedMemory.Structure.Bias == BIAS_BEARISH)
   {
      riskOrderType = ORDER_TYPE_SELL;
      worstCaseEntry = executionTick.bid - slippageBuffer;
   }
   else
   {
      return;
   }

   double estimatedProfit = 0.0;

   if(!OrderCalcProfit(riskOrderType,
                       _Symbol,
                       lot,
                       worstCaseEntry,
                       sl,
                       estimatedProfit))
   {
      MRH_Log("EXECUTION_LAYER",
              "RISK_BLOCKED",
              "Market risk calculation failed");
      return;
   }

   double riskPercent =
      MathMin(SharedMemory.Risk.RiskPercent, 0.50);

   double riskBudget =
      AccountInfoDouble(ACCOUNT_BALANCE) *
      riskPercent / 100.0;

   double estimatedLoss = -estimatedProfit;

   if(riskBudget <= 0.0 ||
      estimatedLoss <= 0.0 ||
      estimatedLoss > riskBudget)
   {
      MRH_Log("EXECUTION_LAYER",
              "STEP136_17G12_9J_RISK_BLOCKED",
              "EstimatedLoss=" +
              DoubleToString(estimatedLoss, 2) +
              " | RiskBudget=" +
              DoubleToString(riskBudget, 2));
      return;
   }

   MRH_Log("EXECUTION_LAYER",
           "STEP136_17G12_9J_RISK_APPROVED",
           "WorstCaseEntry=" +
           DoubleToString(worstCaseEntry, _Digits) +
           " | EstimatedLoss=" +
           DoubleToString(estimatedLoss, 2) +
           " | RiskBudget=" +
           DoubleToString(riskBudget, 2));

   

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



   // STEP136.17G12.8 - Broker execution result audit only
   // Does not change trade decisions or setup consumption

   uint brokerRetcode = Trade.ResultRetcode();
   ulong brokerDeal = Trade.ResultDeal();
   ulong brokerOrder = Trade.ResultOrder();

   bool brokerConfirmed =
      (result &&
       brokerRetcode == TRADE_RETCODE_DONE &&
       brokerDeal > 0);

   MRH_Log("EXECUTION_LAYER",
           "STEP136_17G12_8_BROKER_CONFIRMATION_AUDIT",
           "SendResult=" + (result ? "TRUE" : "FALSE") +
           " | Retcode=" + IntegerToString((int)brokerRetcode) +
           " | Deal=" + IntegerToString((long)brokerDeal) +
           " | Order=" + IntegerToString((long)brokerOrder) +
         
" | BrokerConfirmed=" +
(brokerConfirmed ? "TRUE" : "FALSE") +
" | Bias=" +
EnumToString(SharedMemory.Structure.Bias) +
" | BOSTime=" +
TimeToString(SharedMemory.Structure.LastBOS,
             TIME_DATE | TIME_MINUTES) +
" | SwingHighTime=" +
TimeToString(SharedMemory.Structure.LastSwingHighTime,
             TIME_DATE | TIME_MINUTES) +
" | SwingLowTime=" +
TimeToString(SharedMemory.Structure.LastSwingLowTime,
             TIME_DATE | TIME_MINUTES) +
" | OBHigh=" +
DoubleToString(SharedMemory.OB.High, _Digits) +
" | OBLow=" +
DoubleToString(SharedMemory.OB.Low, _Digits));



   // STEP136.17G12.10F.2
   // Persist confirmed BOS identity - audit only

   if(brokerConfirmed)
   {
      datetime confirmedBOS =
         SharedMemory.Structure.LastBOS;

      if(confirmedBOS > 0)
      {
         string setupKey =
            "MRHX8_BOS_" +
            IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
            "_" + IntegerToString(MagicNumber) +
            "_" + _Symbol +
            "_" + IntegerToString((int)_Period) +
            "_" + IntegerToString((int)SharedMemory.Structure.Bias);

        
         datetime savedTime =
            GlobalVariableSet(setupKey, (double)confirmedBOS);

         // STEP136.17G12.10F.5H3.1
         // Persist confirmed entry timestamp for rearm audit
         // Does not change execution permission

         
         datetime savedEntryTime = 0;

         if(savedTime > 0)
            savedEntryTime = GlobalVariableSet(
               setupKey + "_ENTRY_TIME",
               (double)TimeCurrent());


         if(savedTime > 0)
            GlobalVariablesFlush();


         // STEP136.17G12.10F.5H11.1
         // Shared cross-timeframe entry reference
         // Persistence only - no execution decision changes

        
if(savedEntryTime > 0)
{
   string crossTFEntryKey =
      "MRHX8_CTF_ENTRY_" +
      IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
      "_" + IntegerToString(MagicNumber) +
      "_" + _Symbol +
      "_" + IntegerToString(
         (int)SharedMemory.Structure.LastBOSDirection);

   datetime crossTFSaved =
      GlobalVariableSet(
         crossTFEntryKey,
         (double)TimeCurrent());

   if(crossTFSaved > 0)
      GlobalVariablesFlush();



   // STEP136.17G12.10F.5H11.3A
   // Persist confirmed source swing reference

   datetime sourceSwingTime =
      SharedMemory.Structure.LastBOSSourceSwingTime;

   if(crossTFSaved > 0 && sourceSwingTime > 0)
   {
      string crossTFSwingKey =
         crossTFEntryKey + "_SWING";

      datetime swingSaved =
         GlobalVariableSet(
            crossTFSwingKey,
            (double)sourceSwingTime);

      if(swingSaved > 0)
         GlobalVariablesFlush();

      MRH_Log(
         "EXECUTION_LAYER",
         "STEP136_17G12_10F_5H11_3A_SWING_WRITE_AUDIT",
         "SourceSwing=" +
         TimeToString(sourceSwingTime,
                      TIME_DATE | TIME_MINUTES) +
         " | Persisted=" +
         (swingSaved > 0 ? "TRUE" : "FALSE")
      );
   }



   MRH_Log(
      "EXECUTION_LAYER",
      "STEP136_17G12_10F_5H11_1_CTF_WRITE_AUDIT",
      "Key=" + crossTFEntryKey +
      " | Persisted=" +
      (crossTFSaved > 0 ? "TRUE" : "FALSE")
   );
}


        
         MRH_Log("EXECUTION_LAYER",
                 "STEP136_17G12_10F_2_SETUP_CONSUMPTION_AUDIT",
                 "Deal=" + IntegerToString((long)brokerDeal) +
                 " | BOS=" +
                 TimeToString(confirmedBOS,
                              TIME_DATE | TIME_MINUTES) +
                 " | Direction=" +
                 EnumToString(SharedMemory.Structure.LastBOSDirection) +
                 " | BrokenLevel=" +
                 DoubleToString(SharedMemory.Structure.LastBOSBrokenLevel,
                                _Digits) +
                 " | SourceSwingTime=" +
                 TimeToString(
                    SharedMemory.Structure.LastBOSSourceSwingTime,
                    TIME_DATE | TIME_MINUTES) +
             
                 " | Persisted=" +
                    (savedTime > 0 ? "TRUE" : "FALSE") +
                 " | EntryTimePersisted=" +
                    (savedEntryTime > 0 ? "TRUE" : "FALSE"));


      }
      else
      {
         MRH_Log("EXECUTION_LAYER",
                 "STEP136_17G12_10F_2_SETUP_CONSUMPTION_AUDIT",
                 "Deal=" + IntegerToString((long)brokerDeal) +
                 " | Persisted=FALSE | Reason=NO_VALID_BOS");
      }
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



   // STEP136.17G12.10F.5H10.1
   // Startup persistence audit - no execution changes

   string lockPrefix =
      "MRHX8_BOS_" +
      IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) +
      "_" + IntegerToString(MagicNumber) +
      "_" + _Symbol +
      "_" + IntegerToString((int)_Period) + "_";

   string buyLockKey =
      lockPrefix + IntegerToString((int)BIAS_BULLISH);

   string sellLockKey =
      lockPrefix + IntegerToString((int)BIAS_BEARISH);

   bool buyLockExists = GlobalVariableCheck(buyLockKey);
   bool sellLockExists = GlobalVariableCheck(sellLockKey);

   MRH_Log("SYSTEM",
           "STEP136_17G12_10F_5H10_1_STARTUP_LOCK_AUDIT",
           "BuyLockExists=" +
           (buyLockExists ? "TRUE" : "FALSE") +
           " | SellLockExists=" +
           (sellLockExists ? "TRUE" : "FALSE") +
           " | TF=" + EnumToString(_Period));



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