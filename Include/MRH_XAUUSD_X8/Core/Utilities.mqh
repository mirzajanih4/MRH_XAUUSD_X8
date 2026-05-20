#ifndef MRH_UTILITIES_MQH
#define MRH_UTILITIES_MQH

//==================================================
// Detect New Bar
//==================================================
bool MRH_IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)
{
   static datetime lastBarTime = 0;

   datetime currentBarTime = iTime(symbol, timeframe, 0);

   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }

   return false;
}

#endif