public without sharing class AsyncJobExecutor {
    private static final String LOG_SEPARATOR = '\n\n';

    private static AsyncJobService asyncJobService = new AsyncJobService();

    private AsyncJob__c asyncJob;

    private Datetime startTime;
    private Datetime endTime;

    private Long cpuTimeStart;
    private Long cpuTimeEnd;

    public AsyncJobExecutor(AsyncJob__c asyncJob) {
        this.asyncJob = asyncJob;
    }

    public static void executeNow(Id asyncJobId) {
        AsyncJob__c asyncJob = [
            SELECT Id, Status__c, JobName__c, ExecutionCount__c, MaxExecutionCount__c, IsRecursive__c, RetryInterval__c, ScheduleTime__c, ResultLog__c, LastExecutionTime__c, LastExecutionStatus__c, Params__c, CreatedById, CreatedDate
            FROM AsyncJob__c
            WHERE Id = :asyncJobId
        ];

        new AsyncJobExecutor(asyncJob).execute();
    }

    public void execute() {
        AsyncJobResult result;

        this.makeQueued();
        this.addExecutionCount();

        this.startTime = Datetime.now();
        this.cpuTimeStart = Limits.getCpuTime();

        try {
            ASyncJobHandler handler = asyncJobService.toAsyncJobHandler(this.asyncJob);
            result = handler.execute();
        } catch (Exception e) {
            result = AsyncJobResult.toFailedResult(e.getMessage());
        } finally {
            this.endTime = Datetime.now();
            this.cpuTimeEnd = Limits.getCpuTime();
        }
        this.processResult(result);
    }

    private void processResult(AsyncJobResult result) {
        switch on result.status {
            when COMPLETED {
                this.processCompletedResult();
            }
            when SUCCESS {
                this.processSuccessResult();
            }
            when RETRY_LATER {
                this.processRetryLaterResult();
            }
            when FAILED {
                this.processFailedResult();
            }
            when FATAL_ERROR {
                this.closeFailedAsyncJob();
            }
        }

        this.setLastExecutionTime();
        this.setLastExecutionStatus(result.status);
        this.addResultLog(result);

        this.updateAsyncJob();
    }

    private void processCompletedResult() {
        this.closeSucceededAsyncJob();
    }

    private void processSuccessResult() {
        if (this.isRecursive()) {
            this.rescheduleAsyncJob();
        } else {
            this.processCompletedResult();
        }
    }

    private void processRetryLaterResult() {
        if (this.areExecutionLimitsReached()) {
            this.closeFailedAsyncJob();
        } else {
            this.rescheduleAsyncJob();
        }
    }

    private void processFailedResult() {
        if (this.isRecursive()) {
            this.rescheduleAsyncJob();
        } else {
            this.closeFailedAsyncJob();
        }
    }

    private Boolean areExecutionLimitsReached() {
        return this.asyncJob.ExecutionCount__c >= this.asyncJob.MaxExecutionCount__c;
    }

    private Boolean isRecursive() {
        return this.asyncJob.IsRecursive__c;
    }

    private void closeSucceededAsyncJob() {
        this.asyncJob.Status__c = AsyncJobConstants.STATUS.COMPLETED;
    }

    private void closeFailedAsyncJob() {
        this.asyncJob.Status__c = AsyncJobConstants.STATUS.FAILED;
    }

    private void addExecutionCount() {
        this.asyncJob.ExecutionCount__c = (this.asyncJob.ExecutionCount__c ?? 0) + 1;
    }

    private void setLastExecutionTime() {
        this.asyncJob.LastExecutionTime__c = this.endTime;
    }

    private void setLastExecutionStatus(AsyncJobResult.AsyncJobStatus status) {
        this.asyncJob.LastExecutionStatus__c = status.name();
    }

    private void rescheduleAsyncJob() {
        this.asyncJob.ScheduleTime__c = this.asyncJob.ScheduleTime__c.addMinutes((Integer) this.asyncJob.RetryInterval__c);
    }

    private void addResultLog(AsyncJobResult result) {
        List<String> logLines = new List<String>{
            'Execution Time: ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss.S \'GMT\'', 'GMT'),
            'Execution Longevity: ' + (this.endTime.getTime() - this.startTime.getTime()) + ' ms',
            'CPU Time: ' + (this.cpuTimeEnd - this.cpuTimeStart) + ' of ' + Limits.getCpuTime() + ' ms',
            'Status: ' + String.valueOf(result.status),
            'Message: ' + String.valueOf(result.message)
        };

        String resultLog = String.isNotBlank(this.asyncJob.ResultLog__c) ? this.asyncJob.ResultLog__c + LOG_SEPARATOR + String.join(logLines, '\n') : String.join(logLines, '\n');

        this.asyncJob.ResultLog__c = resultLog.right(4000);
    }

    private void makeQueued() {
        this.asyncJob.Status__c = AsyncJobConstants.STATUS.QUEUED;
    }

    private void updateAsyncJob() {
        update this.asyncJob;
    }
}