#ifndef MRH_STRUCTURE_ENGINE_MQH
#define MRH_STRUCTURE_ENGINE_MQH
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
class CStructureEngine
{
private:
   CSharedMemory* m_memory;
   int m_swingSize;
public:
   CStructureEngine()
   {
      m_memory = NULL;
      m_swingSize = 2;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("STRUCTURE_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("STRUCTURE_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }
bool IsValidIndex(int index)
{
   if(index < m_swingSize)
      return false;

   return true;
}
bool IsSwingHigh(int index)
{
   if(!IsValidIndex(index))
      return false;

   double centerHigh = iHigh(_Symbol, _Period, index);

   for(int i = 1; i <= m_swingSize; i++)
   {
      if(centerHigh <= iHigh(_Symbol, _Period, index - i))
         return false;

      if(centerHigh <= iHigh(_Symbol, _Period, index + i))
         return false;
   }

   return true;
}

bool IsSwingLow(int index)
{
   if(!IsValidIndex(index))
      return false;

   double centerLow = iLow(_Symbol, _Period, index);

   for(int i = 1; i <= m_swingSize; i++)
   {
      if(centerLow >= iLow(_Symbol, _Period, index - i))
         return false;

      if(centerLow >= iLow(_Symbol, _Period, index + i))
         return false;
   }

   return true;
}
void DetectLatestSwing()
{
   if(m_memory == NULL)
      return;

   int bars = Bars(_Symbol, _Period);

   if(bars < 20)
      return;

   for(int i = m_swingSize + 1; i < 100 && i < bars - m_swingSize; i++)
   {
      if(IsSwingHigh(i))
      {
         m_memory.Structure.PreviousSwingHigh =
         m_memory.Structure.LastSwingHigh;

         m_memory.Structure.LastSwingHigh =
          iHigh(_Symbol, _Period, i);
          if(m_memory.Structure.PreviousSwingHigh > 0.0)
{
   if(m_memory.Structure.LastSwingHigh >
      m_memory.Structure.PreviousSwingHigh)
   {
      m_memory.Structure.LastSwingClass = SWING_CLASS_HH;
   }
   else
   {
      m_memory.Structure.LastSwingClass = SWING_CLASS_LH;
   }
}
         m_memory.Structure.LastSwingType = SWING_HIGH;
         datetime swingTime = iTime(_Symbol, _Period, i);

if(swingTime == m_memory.Structure.LastProcessedSwingTime)
{
   return;
}

m_memory.Structure.LastSwingTime = swingTime;
m_memory.Structure.LastProcessedSwingTime = swingTime;

         MRH_Log("STRUCTURE_ENGINE", "SWING_HIGH", "Latest swing high detected");
         return;
      }

      if(IsSwingLow(i))
      {
         m_memory.Structure.PreviousSwingLow =
         m_memory.Structure.LastSwingLow;

         m_memory.Structure.LastSwingLow =
          iLow(_Symbol, _Period, i);
          if(m_memory.Structure.PreviousSwingLow > 0.0)
{
   if(m_memory.Structure.LastSwingLow >
      m_memory.Structure.PreviousSwingLow)
   {
      m_memory.Structure.LastSwingClass = SWING_CLASS_HL;
   }
   else
   {
      m_memory.Structure.LastSwingClass = SWING_CLASS_LL;
   }
}
         m_memory.Structure.LastSwingType = SWING_LOW;
         datetime swingTime = iTime(_Symbol, _Period, i);

if(swingTime == m_memory.Structure.LastProcessedSwingTime)
{
   return;
}

m_memory.Structure.LastSwingTime = swingTime;
m_memory.Structure.LastProcessedSwingTime = swingTime;

         MRH_Log("STRUCTURE_ENGINE", "SWING_LOW", "Latest swing low detected");
         return;
      }
   }
}
void UpdateInitialBias()
{
   if(m_memory == NULL)
      return;

   if(m_memory.Structure.LastSwingHigh <= 0.0 ||
      m_memory.Structure.LastSwingLow  <= 0.0)
   {
      m_memory.Structure.Bias  = BIAS_NEUTRAL;
      m_memory.Structure.State = STRUCTURE_RANGE;
      return;
   }

  if(m_memory.Structure.LastSwingClass == SWING_CLASS_HH ||
   m_memory.Structure.LastSwingClass == SWING_CLASS_HL)
{
   m_memory.Structure.Bias  = BIAS_BULLISH;
   m_memory.Structure.State = STRUCTURE_TRENDING;

   MRH_Log("STRUCTURE_ENGINE",
           "BIAS",
           "Bullish structure sequence detected");

   return;
}

if(m_memory.Structure.LastSwingClass == SWING_CLASS_LH ||
   m_memory.Structure.LastSwingClass == SWING_CLASS_LL)
{
   m_memory.Structure.Bias  = BIAS_BEARISH;
   m_memory.Structure.State = STRUCTURE_TRENDING;

   MRH_Log("STRUCTURE_ENGINE",
           "BIAS",
           "Bearish structure sequence detected");

   return;
}

   m_memory.Structure.Bias  = BIAS_NEUTRAL;
   m_memory.Structure.State = STRUCTURE_RANGE;
}
void DetectStructureBreak()
{
   if(m_memory == NULL)
      return;

   double closePrice = iClose(_Symbol, _Period, 1);
   datetime closeTime = iTime(_Symbol, _Period, 1);

   if(m_memory.Structure.LastSwingHigh > 0.0 &&
      closePrice > m_memory.Structure.LastSwingHigh)
   {
      if(m_memory.Structure.Bias == BIAS_BEARISH)
      {
         if(m_memory.Structure.LastSwingClass == SWING_CLASS_HH ||
   m_memory.Structure.LastSwingClass == SWING_CLASS_HL)
{
   m_memory.Structure.LastCHOCH = closeTime;
   m_memory.Structure.Bias = BIAS_BULLISH;
   m_memory.Structure.State = STRUCTURE_TRANSITION;

   MRH_Log("STRUCTURE_ENGINE",
           "CHOCH",
           "Bullish CHOCH confirmed by HH/HL reversal");

   return;
}
      }

      if(m_memory.Structure.LastSwingClass == SWING_CLASS_HH ||
   m_memory.Structure.LastSwingClass == SWING_CLASS_HL)
{
   m_memory.Structure.LastBOS = closeTime;
   m_memory.Structure.Bias = BIAS_BULLISH;
   m_memory.Structure.State = STRUCTURE_TRENDING;

   MRH_Log("STRUCTURE_ENGINE",
           "BOS",
           "Bullish BOS confirmed by HH/HL structure");

   return;
}
   }

   if(m_memory.Structure.LastSwingLow > 0.0 &&
      closePrice < m_memory.Structure.LastSwingLow)
   {
      if(m_memory.Structure.Bias == BIAS_BULLISH)
      {
         if(m_memory.Structure.LastSwingClass == SWING_CLASS_LH ||
   m_memory.Structure.LastSwingClass == SWING_CLASS_LL)
{
   m_memory.Structure.LastCHOCH = closeTime;
   m_memory.Structure.Bias = BIAS_BEARISH;
   m_memory.Structure.State = STRUCTURE_TRANSITION;

   MRH_Log("STRUCTURE_ENGINE",
           "CHOCH",
           "Bearish CHOCH confirmed by LH/LL reversal");

   return;
}
      }

      if(m_memory.Structure.LastSwingClass == SWING_CLASS_LH ||
   m_memory.Structure.LastSwingClass == SWING_CLASS_LL)
{
   m_memory.Structure.LastBOS = closeTime;
   m_memory.Structure.Bias = BIAS_BEARISH;
   m_memory.Structure.State = STRUCTURE_TRENDING;

   MRH_Log("STRUCTURE_ENGINE",
           "BOS",
           "Bearish BOS confirmed by LH/LL structure");

   return;
}
   }
}
void DebugStructureState()
{
   if(m_memory == NULL)
      return;

   string biasText = "NEUTRAL";

   if(m_memory.Structure.Bias == BIAS_BULLISH)
      biasText = "BULLISH";
   else if(m_memory.Structure.Bias == BIAS_BEARISH)
      biasText = "BEARISH";

   string stateText = "RANGE";

   if(m_memory.Structure.State == STRUCTURE_TRENDING)
      stateText = "TRENDING";
   else if(m_memory.Structure.State == STRUCTURE_TRANSITION)
      stateText = "TRANSITION";

   string swingClassText = "NONE";

   if(m_memory.Structure.LastSwingClass == SWING_CLASS_HH)
      swingClassText = "HH";
   else if(m_memory.Structure.LastSwingClass == SWING_CLASS_HL)
      swingClassText = "HL";
   else if(m_memory.Structure.LastSwingClass == SWING_CLASS_LH)
      swingClassText = "LH";
   else if(m_memory.Structure.LastSwingClass == SWING_CLASS_LL)
      swingClassText = "LL";

   MRH_Log("STRUCTURE_ENGINE",
           "DEBUG",
           "Bias=" + biasText +
           " | State=" + stateText +
           " | LastHigh=" + DoubleToString(m_memory.Structure.LastSwingHigh, _Digits) +
           " | LastLow=" + DoubleToString(m_memory.Structure.LastSwingLow, _Digits) +
           " | SwingClass=" + swingClassText);
}
  void Update()
{
   if(m_memory == NULL)
   {
      return;
   }

   DetectLatestSwing();
   UpdateInitialBias();
   DetectStructureBreak();
   DebugStructureState();
   MRH_Log("STRUCTURE_ENGINE", "UPDATE", "New bar update");
}
};

#endif