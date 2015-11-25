Add-Type -TypeDefinition @'
   public enum IdempotentProcessMode
   {
      Get,
      Test,
      Set
   }
'@

Add-Type -TypeDefinition @'
    public enum IdempotentEnsure
    {
        Absent,
        Present
    }
'@

Add-Type -TypeDefinition @'
    public enum IdempotentResult
    {
        __unused = 0,
        NoChangeRequired = 1,
        RequiredChangesApplied = 2
    }
'@
