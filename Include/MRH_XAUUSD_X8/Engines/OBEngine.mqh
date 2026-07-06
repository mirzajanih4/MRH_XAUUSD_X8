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
   double GetOBStrengthScore()
{
   if(m_memory == NULL)
      return 0.0;

   if(m_memory.OB.Strength == OB_WEAK)
      return 10.0;

   if(m_memory.OB.Strength == OB_MEDIUM)
      return 20.0;

   if(m_memory.OB.Strength == OB_STRONG)
      return 30.0;

   if(m_memory.OB.Strength == OB_INSTITUTIONAL)
      return 40.0;

   return 0.0;
}

bool DetectBasicOB()
{
   if(m_memory == NULL)
      return false;

   m_memory.OB.Valid = false;
   bool detected = false;

   if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      // آخرین کندل نزولی قبل از حرکت صعودی ساده
      if(iClose(_Symbol, _Period, 2) < iOpen(_Symbol, _Period, 2))
      {
         m_memory.OB.High = iHigh(_Symbol, _Period, 2);
         m_memory.OB.Low  = iLow(_Symbol, _Period, 2);
         m_memory.OB.Valid = true;
         m_memory.OB.Mitigated = false;
         m_memory.OB.Invalidated = false;
         m_memory.OB.Strength = OB_MEDIUM;
         m_memory.OB.OBScore = GetOBStrengthScore();
         m_memory.OB.Freshness = 1;
         detected = true;

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
         m_memory.OB.Mitigated = false;
         m_memory.OB.Invalidated = false;
         m_memory.OB.Strength = OB_MEDIUM;
         m_memory.OB.OBScore = GetOBStrengthScore();
         m_memory.OB.Freshness = 1;
         detected = true;

         MRH_Log("OB_ENGINE", "VALID", "Basic bearish OB detected");
      }
   }

   return detected;
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
   m_memory.OB.Freshness = 0;
   if(m_memory.OB.OBScore > 10.0)
      m_memory.OB.OBScore = 10.0;

   MRH_Log("OB_ENGINE", "MITIGATED", "OB zone touched and OBScore reduced");
}

   // Bullish OB invalidation
   if(m_memory.Structure.Bias == BIAS_BULLISH)
   {
      if(closePrice < m_memory.OB.Low)
      {
         m_memory.OB.Invalidated = true;
         m_memory.OB.Valid = false;
         m_memory.OB.OBScore = 0.0;
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
         m_memory.OB.OBScore = 0.0;
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
string strengthText = "WEAK";

if(m_memory.OB.Strength == OB_MEDIUM)
   strengthText = "MEDIUM";
else if(m_memory.OB.Strength == OB_STRONG)
   strengthText = "STRONG";
else if(m_memory.OB.Strength == OB_INSTITUTIONAL)
   strengthText = "INSTITUTIONAL";
   MRH_Log("OB_ENGINE",
           "DEBUG",
           "Valid=" + validText +
           " | High=" + DoubleToString(m_memory.OB.High, _Digits) +
           " | Low=" + DoubleToString(m_memory.OB.Low, _Digits) +
           " | Range=" + DoubleToString((m_memory.OB.High - m_memory.OB.Low), _Digits) +
           " | Strength=" + strengthText +
           " | OBScore=" + DoubleToString(m_memory.OB.OBScore, 1) +
           " | Freshness=" + IntegerToString(m_memory.OB.Freshness) +
           " | Mitigated=" + mitigatedText +
           " | Invalidated=" + invalidatedText);
}
   void Update()
{
   if(m_memory == NULL)
   {
      return;
   }

   bool newOBDetected = DetectBasicOB();

   if(newOBDetected)
   {
      MRH_Log("OB_ENGINE",
              "LIFECYCLE_SKIP",
              "New OB detected; lifecycle check skipped for this cycle");
   }
   else
   {
      CheckOBLifecycle();
   }

   DebugOBState();
  MRH_Log("OB_ENGINE",
        "STEP119A_OB_AUDIT",
        "Valid=" + (m_memory.OB.Valid ? "TRUE" : "FALSE") +
        " | Invalidated=" + (m_memory.OB.Invalidated ? "TRUE" : "FALSE") +
        " | Score=" + DoubleToString(m_memory.OB.OBScore, 1));
        
        MRH_Log("OB_ENGINE",
        "STEP120A_OB_VALUATION_AUDIT",
        "TF=" + EnumToString(_Period) +
        " | Valid=" + (m_memory.OB.Valid ? "TRUE" : "FALSE") +
        " | Mitigated=" + (m_memory.OB.Mitigated ? "TRUE" : "FALSE") +
        " | Invalidated=" + (m_memory.OB.Invalidated ? "TRUE" : "FALSE") +
        " | Freshness=" + IntegerToString(m_memory.OB.Freshness) +
        " | StrengthScore=" + DoubleToString((m_memory.OB.Valid ? GetOBStrengthScore() : 0.0), 1) +
        " | OBScore=" + DoubleToString(m_memory.OB.OBScore, 1) +
        " | High=" + DoubleToString(m_memory.OB.High, _Digits) +
        " | Low=" + DoubleToString(m_memory.OB.Low, _Digits) +
        " | Range=" + DoubleToString((m_memory.OB.High - m_memory.OB.Low), _Digits));
        
   MRH_Log("OB_ENGINE", "UPDATE", "New bar update");
}
};
#endif