#ifndef MRH_EXECUTION_ENGINE_MQH
#define MRH_EXECUTION_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>
#include <MRH_XAUUSD_X8/Core/Logger.mqh>

class CExecutionEngine
{
private:
   CSharedMemory* m_memory;
   double m_requiredPermissionScore;

public:
   CExecutionEngine()
   {
      m_memory = NULL;
      m_requiredPermissionScore = 40.0;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;

      if(m_memory == NULL)
      {
         MRH_Log("EXECUTION_ENGINE", "ERROR", "SharedMemory is NULL");
         return false;
      }

      MRH_Log("EXECUTION_ENGINE", "INIT", "Initialized with SharedMemory");
      return true;
   }
void CalculatePermissionScore()
{
   if(m_memory == NULL)
      return;

   //==================================
   // Reset
   //==================================
   m_memory.Execution.PermissionScore = 0.0;
   m_memory.Execution.StructureScore  = 0.0;
   m_memory.Execution.OBScore         = 0.0;

   m_memory.Execution.ScoreApproved   = false;
   m_memory.Execution.ExecutionGrade  = "BLOCKED";
   m_memory.Execution.ConfidenceLevel = "LOW";

   //==================================
   // Structure Score
   //==================================
   if(m_memory.Structure.Bias != BIAS_NEUTRAL)
      m_memory.Execution.StructureScore = 20.0;

   //==================================
   // OB Score
   //==================================
  if(m_memory.OB.Valid)
   m_memory.Execution.OBScore = m_memory.OB.OBScore;
   //==================================
   // Final Permission Score
   //==================================
   m_memory.Execution.PermissionScore =
      m_memory.Liquidity.LiquidityScore +
      m_memory.Execution.StructureScore +
      m_memory.Execution.OBScore;

   //==================================
   // Approval
   //==================================
   if(m_memory.Execution.PermissionScore >= m_requiredPermissionScore)
      m_memory.Execution.ScoreApproved = true;

   //==================================
   // Execution Grade
   //==================================
   if(m_memory.Execution.PermissionScore >= 80.0)
      m_memory.Execution.ExecutionGrade = "A_SETUP";
   else if(m_memory.Execution.PermissionScore >= 60.0)
      m_memory.Execution.ExecutionGrade = "B_SETUP";
   else if(m_memory.Execution.PermissionScore >= m_requiredPermissionScore)
      m_memory.Execution.ExecutionGrade = "C_SETUP";

   //==================================
   // Confidence Level
   //==================================
   if(m_memory.Execution.PermissionScore >= 80.0)
      m_memory.Execution.ConfidenceLevel = "HIGH";
   else if(m_memory.Execution.PermissionScore >= 60.0)
      m_memory.Execution.ConfidenceLevel = "MEDIUM";
      m_memory.Execution.ConfluenceScore =
   m_memory.Execution.PermissionScore;

if(m_memory.Execution.ConfidenceLevel == "MEDIUM")
   m_memory.Execution.ConfluenceScore += 5.0;
else if(m_memory.Execution.ConfidenceLevel == "HIGH")
   m_memory.Execution.ConfluenceScore += 10.0;

if(m_memory.Execution.ConfluenceScore > 100.0)
   m_memory.Execution.ConfluenceScore = 100.0;
   m_memory.Execution.RecommendedRiskPercent = 0.0;

if(m_memory.Execution.ConfluenceScore >= 80.0)
   m_memory.Execution.RecommendedRiskPercent = 1.00;
else if(m_memory.Execution.ConfluenceScore >= 60.0)
   m_memory.Execution.RecommendedRiskPercent = 0.75;
else if(m_memory.Execution.ConfluenceScore >= 40.0)
   m_memory.Execution.RecommendedRiskPercent = 0.50;
}
   bool HasExecutionPermission()
{
   if(m_memory == NULL)
      return false;

   if(m_memory.Structure.Bias == BIAS_NEUTRAL)
      return false;

   if(m_memory.Structure.State == STRUCTURE_RANGE)
      return false;

   if(!m_memory.OB.Valid)
      return false;

   if(m_memory.OB.Invalidated)
      return false;

   if(m_memory.Liquidity.TargetLiquidity <= 0.0)
      return false;

   if(!m_memory.Execution.ScoreApproved)
      return false;

   return true;
}
   void Update()
   {
      if(m_memory == NULL)
         return;

      CalculatePermissionScore();
      
            // STEP49 - Execution Strictness Layer
      // No valid OB = no execution permission, no A_SETUP, no risk
      if(!m_memory.OB.Valid || m_memory.OB.Invalidated)
      {
         m_memory.Execution.ScoreApproved = false;
         m_memory.Execution.PermissionScore = 0.0;
         m_memory.Execution.ConfluenceScore = 0.0;
         m_memory.Execution.ExecutionGrade = "BLOCKED";
         m_memory.Execution.ConfidenceLevel = "LOW";
         m_memory.Execution.RecommendedRiskPercent = 0.0;
         m_memory.Execution.EntrySignal = false;
      }

      if(HasExecutionPermission())
      {
         m_memory.Execution.State = EXECUTION_WAITING;
         MRH_Log("EXECUTION_ENGINE", "PERMISSION", "Execution permission granted by score");
      }
      else
      {
         m_memory.Execution.State = EXECUTION_BLOCKED;
         m_memory.Execution.EntrySignal = false;
      }

      MRH_Log("EXECUTION_ENGINE",
              "DEBUG",
              "PermissionScore=" + DoubleToString(m_memory.Execution.PermissionScore, 1) +
              " | ScoreApproved=" + IntegerToString((int)m_memory.Execution.ScoreApproved));

     string detailMessage =
   "LiquidityScore=" + DoubleToString(m_memory.Liquidity.LiquidityScore, 1) +
   " | StructureScore=" + DoubleToString(m_memory.Execution.StructureScore, 1) +
   " | OBScore=" + DoubleToString(m_memory.Execution.OBScore, 1) +
   " | PermissionScore=" + DoubleToString(m_memory.Execution.PermissionScore, 1) +
   " | RequiredScore=" + DoubleToString(m_requiredPermissionScore, 1) +
   " | Grade=" + m_memory.Execution.ExecutionGrade +
   " | Confidence=" + m_memory.Execution.ConfidenceLevel +
   " | ConfluenceScore=" + DoubleToString(m_memory.Execution.ConfluenceScore, 1) +
   " | RecommendedRisk=" + DoubleToString(m_memory.Execution.RecommendedRiskPercent, 2);

MRH_Log("EXECUTION_ENGINE", "DEBUG_DETAIL", detailMessage);
   }
};

#endif