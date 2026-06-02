#ifndef MRH_OB_ENGINE_MQH
#define MRH_OB_ENGINE_MQH
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
class COBEngine
{
private:
   CSharedMemory* m_memory;

public:
   COBEngine()
   {
      m_memory = NULL;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("OB_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("OB_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }
void DetectBasicOB()
{
   if(m_memory == NULL)
      return;

   m_memory.OB.Valid = false;

   if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      // آخرین کندل نزولی قبل از حرکت صعودی ساده
      if(iClose(_Symbol, _Period, 2) < iOpen(_Symbol, _Period, 2))
      {
         m_memory.OB.High = iHigh(_Symbol, _Period, 2);
         m_memory.OB.Low  = iLow(_Symbol, _Period, 2);
         m_memory.OB.Valid = true;
         m_memory.OB.Strength = OB_MEDIUM;

         MRH_Log("OB_ENGINE", "VALID", "Basic bullish OB detected");
      }
   }
   else if(m_memory.Structure.Bias == BIAS_BEARISH)
   {
      // آخرین کندل صعودی قبل از حرکت نزولی ساده
      if(iClose(_Symbol, _Period, 2) > iOpen(_Symbol, _Period, 2))
      {
         m_memory.OB.High = iHigh(_Symbol, _Period, 2);
         m_memory.OB.Low  = iLow(_Symbol, _Period, 2);
         m_memory.OB.Valid = true;
         m_memory.OB.Strength = OB_MEDIUM;
    
         MRH_Log("OB_ENGINE", "VALID", "Basic bearish OB detected");
      }
   }
}
void CheckOBLifecycle()
{
   if(m_memory == NULL)
      return;

   if(!m_memory.OB.Valid)
      return;

   double highPrice  = iHigh(_Symbol, _Period, 1);
   double lowPrice   = iLow(_Symbol, _Period, 1);
   double closePrice = iClose(_Symbol, _Period, 1);

   // Mitigation: price touches OB zone
   if(highPrice >= m_memory.OB.Low && lowPrice <= m_memory.OB.High)
   {
      m_memory.OB.Mitigated = true;
      MRH_Log("OB_ENGINE", "MITIGATED", "OB zone touched");
   }

   // Bullish OB invalidation
   if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      if(closePrice < m_memory.OB.Low)
      {
         m_memory.OB.Invalidated = true;
         m_memory.OB.Valid = false;
         MRH_Log("OB_ENGINE", "INVALIDATED", "Bullish OB invalidated");
      }
   }

   // Bearish OB invalidation
   if(m_memory.Structure.Bias == BIAS_BEARISH)
   {
      if(closePrice > m_memory.OB.High)
      {
         m_memory.OB.Invalidated = true;
         m_memory.OB.Valid = false;
         MRH_Log("OB_ENGINE", "INVALIDATED", "Bearish OB invalidated");
      }
   }
}
void DebugOBState()
{
   if(m_memory == NULL)
      return;

   string validText = "false";
   string mitigatedText = "false";
   string invalidatedText = "false";

   if(m_memory.OB.Valid)
      validText = "true";

   if(m_memory.OB.Mitigated)
      mitigatedText = "true";

   if(m_memory.OB.Invalidated)
      invalidatedText = "true";

   MRH_Log("OB_ENGINE",
           "DEBUG",
           "Valid=" + validText +
           " | High=" + DoubleToString(m_memory.OB.High, _Digits) +
           " | Low=" + DoubleToString(m_memory.OB.Low, _Digits) +
           " | Strength=" + IntegerToString((int)m_memory.OB.Strength) +
           " | Mitigated=" + mitigatedText +
           " | Invalidated=" + invalidatedText);
}
   void Update()
{
   if(m_memory == NULL)
   {
      return;
   }

   DetectBasicOB();
   CheckOBLifecycle();
   DebugOBState();
   MRH_Log("OB_ENGINE", "UPDATE", "New bar update");
}
};

#endif