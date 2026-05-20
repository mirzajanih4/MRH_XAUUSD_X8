#ifndef MRH_LOGGER_MQH
#define MRH_LOGGER_MQH

//==================================================
// Standard Logger
//==================================================
void MRH_Log(string engine, string state, string message)
{
   Print("[",
         TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
         "] [", engine,
         "] [", state,
         "] ", message);
}

#endif