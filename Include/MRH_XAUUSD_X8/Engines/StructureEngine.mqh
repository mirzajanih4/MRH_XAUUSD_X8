#ifndef MRH_STRUCTURE_ENGINE_MQH
#define MRH_STRUCTURE_ENGINE_MQH
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>
class CStructureEngine
{
private:
   CSharedMemory* m_memory;
   int m_swingSize;
   int m_atrHandle;
   
public:
   CStructureEngine()
   {
      m_memory = NULL;
      m_swingSize = 2;
      m_atrHandle = INVALID_HANDLE;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("STRUCTURE_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

// STEP133.2A - ATR handle foundation
m_atrHandle = iATR(_Symbol, _Period, 14);

if(m_atrHandle == INVALID_HANDLE)
{
   MRH_Log("STRUCTURE_ENGINE",
           "ERROR",
           "ATR handle creation failed");

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
   datetime swingTime = iTime(_Symbol, _Period, i);

   // STEP134.4J-FIX - Reject duplicate before state mutation
   if(swingTime == m_memory.Structure.LastProcessedSwingTime)
   {
      return;
   }

   m_memory.Structure.PreviousSwingHigh =
      m_memory.Structure.LastSwingHigh;
      
m_memory.Structure.LastSwingHigh =
   iHigh(_Symbol, _Period, i);

// STEP134.4F - Independent High Swing Classification
m_memory.Structure.LastSwingClass     = SWING_CLASS_NONE;
m_memory.Structure.LastSwingHighClass = SWING_CLASS_NONE;

if(m_memory.Structure.PreviousSwingHigh > 0.0)
{
   if(m_memory.Structure.LastSwingHigh >
      m_memory.Structure.PreviousSwingHigh)
   {
      m_memory.Structure.LastSwingClass =
         SWING_CLASS_HH;

      m_memory.Structure.LastSwingHighClass =
         SWING_CLASS_HH;
   }
   else
   {
      m_memory.Structure.LastSwingClass =
         SWING_CLASS_LH;

      m_memory.Structure.LastSwingHighClass =
         SWING_CLASS_LH;
   }
}
         m_memory.Structure.LastSwingType = SWING_HIGH;
         



m_memory.Structure.LastSwingTime = swingTime;
m_memory.Structure.LastProcessedSwingTime = swingTime;


// STEP134.4H - Structure Swing Pair Audit
MRH_Log("STRUCTURE_ENGINE",
        "STEP134_SWING_PAIR_AUDIT",
        "Detected=HIGH" +
        " | Index=" + IntegerToString(i) +
        " | LastSwingHigh=" +
        DoubleToString(m_memory.Structure.LastSwingHigh, _Digits) +
        " | PreviousSwingHigh=" +
        DoubleToString(m_memory.Structure.PreviousSwingHigh, _Digits) +
        " | LastSwingLow=" +
        DoubleToString(m_memory.Structure.LastSwingLow, _Digits) +
        " | HighClass=" +
        EnumToString(m_memory.Structure.LastSwingHighClass) +
        " | LowClass=" +
        EnumToString(m_memory.Structure.LastSwingLowClass) +
        " | SwingClass=" +
        EnumToString(m_memory.Structure.LastSwingClass) +
        " | Bias=" +
        EnumToString(m_memory.Structure.Bias));

MRH_Log("STRUCTURE_ENGINE",
        "SWING_HIGH",
        "Latest swing high detected");

return;
}

if(IsSwingLow(i))
{
   datetime swingTime = iTime(_Symbol, _Period, i);

   if(swingTime == m_memory.Structure.LastProcessedSwingTime)
   {
      return;
   }

   m_memory.Structure.PreviousSwingLow =
      m_memory.Structure.LastSwingLow;

   m_memory.Structure.LastSwingLow =
      iLow(_Symbol, _Period, i);

   // STEP134.4G - Independent Low Swing Classification
   m_memory.Structure.LastSwingClass    = SWING_CLASS_NONE;
   m_memory.Structure.LastSwingLowClass = SWING_CLASS_NONE;

   if(m_memory.Structure.PreviousSwingLow > 0.0)
   {
      if(m_memory.Structure.LastSwingLow >
         m_memory.Structure.PreviousSwingLow)
      {
         m_memory.Structure.LastSwingClass =
            SWING_CLASS_HL;

         m_memory.Structure.LastSwingLowClass =
            SWING_CLASS_HL;
      }
      else
      {
         m_memory.Structure.LastSwingClass =
            SWING_CLASS_LL;

         m_memory.Structure.LastSwingLowClass =
            SWING_CLASS_LL;
      }
   }

   m_memory.Structure.LastSwingType = SWING_LOW;

   m_memory.Structure.LastSwingTime = swingTime;
   m_memory.Structure.LastProcessedSwingTime = swingTime;

   // STEP134.4I - Structure Swing Pair Audit
   MRH_Log("STRUCTURE_ENGINE",
           "STEP134_SWING_PAIR_AUDIT",
           "Detected=LOW" +
           " | Index=" + IntegerToString(i) +
           " | LastSwingHigh=" +
           DoubleToString(m_memory.Structure.LastSwingHigh, _Digits) +
           " | LastSwingLow=" +
           DoubleToString(m_memory.Structure.LastSwingLow, _Digits) +
           " | PreviousSwingLow=" +
           DoubleToString(m_memory.Structure.PreviousSwingLow, _Digits) +
           " | HighClass=" +
           EnumToString(m_memory.Structure.LastSwingHighClass) +
           " | LowClass=" +
           EnumToString(m_memory.Structure.LastSwingLowClass) +
           " | SwingClass=" +
           EnumToString(m_memory.Structure.LastSwingClass) +
           " | Bias=" +
           EnumToString(m_memory.Structure.Bias));

   MRH_Log("STRUCTURE_ENGINE",
           "SWING_LOW",
           "Latest swing low detected");

   return;
}
   }
}


void UpdateInitialBias()
{
   if(m_memory == NULL)
      return;

   // STEP134.4L - Pair-Based Structure Bias

   // Both sides of structure must first be classified.
   if(m_memory.Structure.LastSwingHighClass == SWING_CLASS_NONE ||
      m_memory.Structure.LastSwingLowClass  == SWING_CLASS_NONE)
   {
      m_memory.Structure.Bias  = BIAS_NEUTRAL;
      m_memory.Structure.State = STRUCTURE_RANGE;
      return;
   }

   // Confirmed bullish structure: HH + HL
   if(m_memory.Structure.LastSwingHighClass == SWING_CLASS_HH &&
      m_memory.Structure.LastSwingLowClass  == SWING_CLASS_HL)
   {
      m_memory.Structure.Bias  = BIAS_BULLISH;
      m_memory.Structure.State = STRUCTURE_TRENDING;

      MRH_Log("STRUCTURE_ENGINE",
              "BIAS",
              "Bullish structure confirmed by HH + HL");

      return;
   }

   // Confirmed bearish structure: LH + LL
   if(m_memory.Structure.LastSwingHighClass == SWING_CLASS_LH &&
      m_memory.Structure.LastSwingLowClass  == SWING_CLASS_LL)
   {
      m_memory.Structure.Bias  = BIAS_BEARISH;
      m_memory.Structure.State = STRUCTURE_TRENDING;

      MRH_Log("STRUCTURE_ENGINE",
              "BIAS",
              "Bearish structure confirmed by LH + LL");

      return;
   }

   // Mixed structure:
   // HH + LL or LH + HL
   m_memory.Structure.Bias  = BIAS_NEUTRAL;
   m_memory.Structure.State = STRUCTURE_TRANSITION;
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

void UpdateVolatilityContext()
{
   if(m_memory == NULL)
      return;

   if(m_atrHandle == INVALID_HANDLE)
      return;

   double atrBuffer[21];

   if(CopyBuffer(m_atrHandle, 0, 1, 21, atrBuffer) != 21)
      return;

   m_memory.Structure.CurrentATR = atrBuffer[0];

   double atrSum = 0.0;

   for(int i = 1; i < 21; i++)
      atrSum += atrBuffer[i];

  double averageATR = atrSum / 20.0;

double atrRatio = 0.0;

if(averageATR > 0.0)
   atrRatio = m_memory.Structure.CurrentATR / averageATR;

// STEP133.4C - Experimental volatility classification
m_memory.Structure.VolatilityState = VOL_STATE_NORMAL;

if(atrRatio < 0.85)
{
   m_memory.Structure.VolatilityState = VOL_STATE_LOW;
}
else if(atrRatio >= 1.30)
{
   m_memory.Structure.VolatilityState = VOL_STATE_HIGH;
}

// Temporary production context remains unchanged
// STEP133.5 - Map experimental state into Market Context
if(m_memory.Structure.VolatilityState == VOL_STATE_HIGH)
{
   m_memory.Structure.VolatilityContext = VOLATILITY_ELEVATED;
}
else
{
   m_memory.Structure.VolatilityContext = VOLATILITY_NORMAL;
}

// STEP133.6C - Volatility regime candidate
m_memory.Structure.VolatilityRegimeCandidate =
   (m_memory.Structure.VolatilityContext == VOLATILITY_ELEVATED ||
    m_memory.Structure.VolatilityContext == VOLATILITY_EXTREME);


MRH_Log("STRUCTURE_ENGINE",
        "STEP133_ATR_AUDIT",
        "CurrentATR=" +
        DoubleToString(m_memory.Structure.CurrentATR, _Digits) +
        " | AverageATR20=" +
        DoubleToString(averageATR, _Digits) +
        " | ATRRatio=" +
        DoubleToString(atrRatio, 2) +
        " | VolatilityState=" +
        EnumToString(m_memory.Structure.VolatilityState));
}

void UpdateNewsContext()
{
   if(m_memory == NULL)
      return;

   // STEP133.9C - Temporary news baseline
   m_memory.Structure.NewsContext = NEWS_CONTEXT_NONE;
}


void UpdateMarketRegime()
{
   if(m_memory == NULL)
      return;

   // STEP133.7A - Volatility candidate integration
   m_memory.Structure.MarketRegime = REGIME_NORMAL;

   if(m_memory.Structure.VolatilityRegimeCandidate)
   {
      m_memory.Structure.MarketRegime = REGIME_MEDIUM_EVENT;
   }
   
   // STEP133.8C - Trigger requirement audit mapping
if(m_memory.Structure.MarketRegime == REGIME_MEDIUM_EVENT)
{
   m_memory.Structure.TriggerRequirement =
      TRIGGER_STRONG_CONFIRMATION;
}
else
{
   m_memory.Structure.TriggerRequirement =
      TRIGGER_STANDARD_CONFIRMATION;
}
   
}

void UpdateMarketContext()
{
   if(m_memory == NULL)
      return;

   

   // STEP132.7 / STEP132.8
   // Broker-independent summer session detection using GMT
   MqlDateTime currentGMT;
   TimeToStruct(TimeGMT(), currentGMT);

   int hour = currentGMT.hour;

   m_memory.Structure.MarketSession = SESSION_UNKNOWN;

   if(hour >= 0 && hour < 7)
   {
      m_memory.Structure.MarketSession = SESSION_ASIA;
   }
   else if(hour >= 7 && hour < 12)
   {
      m_memory.Structure.MarketSession = SESSION_LONDON;
   }
   else if(hour >= 12 && hour < 16)
   {
      m_memory.Structure.MarketSession =
         SESSION_LONDON_NEW_YORK_OVERLAP;
   }
   else if(hour >= 16 && hour < 21)
   {
      m_memory.Structure.MarketSession = SESSION_NEW_YORK;
   }
   
   // STEP132.9C - Active session context
m_memory.Structure.ActiveTradingSession =
   (m_memory.Structure.MarketSession == SESSION_LONDON ||
    m_memory.Structure.MarketSession == SESSION_NEW_YORK ||
    m_memory.Structure.MarketSession == SESSION_LONDON_NEW_YORK_OVERLAP);
    
    UpdateVolatilityContext();
 
    UpdateNewsContext();
   
    UpdateMarketRegime();
}
  void Update()
{
   if(m_memory == NULL)
   {
      return;
   }

   DetectLatestSwing();
   UpdateInitialBias();
   
   // STEP134.4M - Pair Bias Isolation Audit
MRH_Log("STRUCTURE_ENGINE",
        "STEP134_PAIR_BIAS_AUDIT",
        "HighClass=" +
        EnumToString(m_memory.Structure.LastSwingHighClass) +
        " | LowClass=" +
        EnumToString(m_memory.Structure.LastSwingLowClass) +
        " | BiasBeforeBreak=" +
        EnumToString(m_memory.Structure.Bias) +
        " | StateBeforeBreak=" +
        EnumToString(m_memory.Structure.State));
        
   DetectStructureBreak();
   UpdateMarketContext();
   DebugStructureState();

   // STEP132.2 - Market Regime Runtime Audit
 
 MqlDateTime serverTime;
datetime currentServerTime = TimeCurrent();
datetime currentGMTTime    = TimeGMT();

TimeToStruct(currentServerTime, serverTime);

int serverGMTOffsetHours =
   (int)MathRound(
      (double)(currentServerTime - currentGMTTime) / 3600.0
   );

MRH_Log("STRUCTURE_ENGINE",
        "STEP132_MARKET_CONTEXT",
        "ServerTime=" +
        TimeToString(currentServerTime, TIME_DATE | TIME_MINUTES) +
        " | ServerHour=" +
        IntegerToString(serverTime.hour) +
        " | GMTTime=" +
        TimeToString(currentGMTTime, TIME_DATE | TIME_MINUTES) +
        " | ServerGMTOffsetHours=" +
        IntegerToString(serverGMTOffsetHours) +
        " | Regime=" +
        EnumToString(m_memory.Structure.MarketRegime) +
        " | TriggerRequirement=" +
        EnumToString(m_memory.Structure.TriggerRequirement) +
        " | Session=" +
        EnumToString(m_memory.Structure.MarketSession) +
        " | ActiveTradingSession=" +
        (m_memory.Structure.ActiveTradingSession ? "TRUE" : "FALSE") +
        " | VolatilityContext=" +
        EnumToString(m_memory.Structure.VolatilityContext) +
        " | NewsContext=" +
        EnumToString(m_memory.Structure.NewsContext) +
        " | VolatilityRegimeCandidate=" +
        (m_memory.Structure.VolatilityRegimeCandidate ? "TRUE" : "FALSE") +
        " | CurrentATR=" +
        DoubleToString(m_memory.Structure.CurrentATR, _Digits));
        MRH_Log("STRUCTURE_ENGINE", "UPDATE", "New bar update");
}
};
#endif