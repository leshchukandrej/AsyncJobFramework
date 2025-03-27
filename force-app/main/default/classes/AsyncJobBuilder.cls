public virtual class AsyncJobBuilder {

    private AsyncJob__c asyncJob;

    public AsyncJobBuilder(String jobName) {
        this.asyncJob = new AsyncJob__c(
            JobName__c = jobName
        );
    }

    public AsyncJobBuilder setParentJobId(Id parentJobId) {
        return this.setValue(AsyncJob__c.ParentJobId__c, parentJobId);
    }

    public AsyncJobBuilder setScheduleTime(Datetime scheduleTime) {
        return this.setValue(AsyncJob__c.ScheduleTime__c, scheduleTime);
    }

    public AsyncJobBuilder setRetryInterval(Integer retryIntervalInMinutes) {
        return this.setValue(AsyncJob__c.RetryInterval__c, retryIntervalInMinutes);
    }

    public AsyncJobBuilder setMaxExecutionCount(Integer maxExecutionCount) {
        return this.setValue(AsyncJob__c.MaxExecutionCount__c, maxExecutionCount);
    }

    public AsyncJobBuilder makeRecursive() {
        return this.setValue(AsyncJob__c.IsRecursive__c, true);
    }

    public AsyncJobBuilder setParams(Map<String, Object> params) {
        return this.setParams(JSON.serialize(params));
    }

    public AsyncJobBuilder setParams(String params) {
        return this.setValue(AsyncJob__c.Params__c, params);
    }

    public AsyncJob__c build() {
        if (this.asyncJob.ParentJobId__c == null) {
            this.setParentJobId(AsyncJobHandler.jobId);
        }

        if (this.asyncJob.ScheduleTime__c == null) {
            this.setScheduleTime(Datetime.now());
            //execute immediately
            this.setValue(AsyncJob__c.Status__c, AsyncJobConstants.STATUS.IN_PROGRESS);
        }

        return this.asyncJob;
    }

    private AsyncJobBuilder setValue(SObjectField field, Object value) {
        this.asyncJob.put(field, value);
        return this;
    }

}