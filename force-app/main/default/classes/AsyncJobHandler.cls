public abstract without sharing class AsyncJobHandler {
    public static Id jobId;
    public static Id createdById;

    public String apexClassName;

    public Boolean isRecursive;

    public DateTime createdDate;
    public Datetime lastExecutionTime;
    public String lastExecutionStatus;

    public Integer executionCount;
    public Integer maxExecutionCount;

    public Boolean areExecutionLimitsReached() {
        return this.executionCount >= this.maxExecutionCount && !this.isRecursive;
    }

    public virtual void setParams(String params) {}

    public abstract AsyncJobResult execute();
}
