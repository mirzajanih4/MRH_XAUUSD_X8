#ifndef MRH_ARCHITECTURE_AUDIT_ENGINE_MQH
#define MRH_ARCHITECTURE_AUDIT_ENGINE_MQH

#include <MRH_XAUUSD_X8/Core/Types.mqh>
#include <MRH_XAUUSD_X8/Core/SharedMemory.mqh>

//==================================================
// Architecture Audit Engine
//==================================================
class CArchitectureAuditEngine
{
private:
   CSharedMemory* m_memory;

   double m_audit_score;
   string m_audit_class;
   bool   m_approved;

public:
   CArchitectureAuditEngine()
   {
      m_memory      = NULL;
      m_audit_score = 0.0;
      m_audit_class = "NOT_READY";
      m_approved    = false;
   }

   bool Init(CSharedMemory* memory)
   {
      m_memory = memory;
      return (m_memory != NULL);
   }

  void Update()
{
   if(m_memory == NULL)
      return;

   m_audit_score = 0.0;

   if(m_memory.Structure.Bias != BIAS_NEUTRAL)
      m_audit_score += 12.5;

   if(m_memory.Liquidity.LiquidityScore > 0.0)
      m_audit_score += 12.5;

   if(m_memory.OB.Valid)
      m_audit_score += 12.5;

   if(m_memory.Execution.PermissionScore > 0.0)
      m_audit_score += 12.5;

   if(m_memory.Risk.RiskProfile != "NO_RISK")
      m_audit_score += 12.5;

   if(m_memory.Safety.TradingAllowed)
      m_audit_score += 12.5;

   if(m_memory.Trade.BreakEvenRR > 0.0)
      m_audit_score += 12.5;

   if(m_memory.LastSnapshot.SnapshotTime > 0)
      m_audit_score += 12.5;

   if(m_audit_score >= 90.0)
   {
      m_audit_class = "APPROVED";
      m_approved    = true;
   }
   else if(m_audit_score >= 70.0)
   {
      m_audit_class = "REVIEW";
      m_approved    = false;
   }
   else
   {
      m_audit_class = "NOT_READY";
      m_approved    = false;
   }

   // STEP44.7A - Write Architecture Audit Result To Snapshot
   m_memory.LastSnapshot.ArchitectureAuditScore = m_audit_score;
   m_memory.LastSnapshot.ArchitectureAuditClass = m_audit_class;
   m_memory.LastSnapshot.ArchitectureApproved   = m_approved;
}

   double AuditScore() const
   {
      return m_audit_score;
   }

   string AuditClass() const
   {
      return m_audit_class;
   }

   bool Approved() const
   {
      return m_approved;
   }
};

#endif