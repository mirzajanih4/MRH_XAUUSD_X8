//+------------------------------------------------------------------+
//| MRH_XAUUSD_X8.mq5                                                |
//| Compile-Safe Baseline                                            |
//+------------------------------------------------------------------+
#property strict
#property version   "1.000"

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

//--- Engine instances
CSharedMemory SharedMemory;
CStructureEngine        StructureEngine;
CLiquidityEngine        LiquidityEngine;
COBEngine               OBEngine;
CExecutionEngine        ExecutionEngine;
CRiskManager            RiskManager;
CTradeManagementEngine  TradeManagementEngine;
CSafetyManager          SafetyManager;
CMLDatasetEngine        MLDatasetEngine;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   MRH_Log("SYSTEM", "INIT", "MRH_XAUUSD_X8 initialized successfully");
SharedMemory.Init();
StructureEngine.Init(&SharedMemory);
LiquidityEngine.Init(&SharedMemory);
OBEngine.Init(&SharedMemory);
ExecutionEngine.Init(&SharedMemory);
RiskManager.Init(&SharedMemory);
SafetyManager.Init(&SharedMemory);
TradeManagementEngine.Init(&SharedMemory);
MLDatasetEngine.Init(&SharedMemory);

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

   StructureEngine.Update();
   LiquidityEngine.Update();
   OBEngine.Update();
   ExecutionEngine.Update();
   RiskManager.Update();
   SafetyManager.Update();
   TradeManagementEngine.Update();
   MLDatasetEngine.Update();
}
}