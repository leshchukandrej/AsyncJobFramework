public without sharing class AsyncJobBatch implements Database.Batchable<SObject> {
    
    public static final String BATCH_JOB_NAME = 'AsyncJobBatch';

    private static final Integer BATCH_SIZE = 50;

    private AsyncJobBatch() {
    }

    public static Id startJob() {
        if (AsyncJobService.isBatchJobActive()) {
            throw new AsyncJobException('Batch job is already running');
        }

        Id jobId = Database.executeBatch(new AsyncJobBatch(), BATCH_SIZE);

        AsyncJobService.setBatchJobId(jobId);

        return jobId;
    }

    public static void abortJob() {
        AsyncJobService.setBatchJobId(null);
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        AsyncJobService.setBatchJobId(context.getJobId());

        return Database.getQueryLocator([
            SELECT Id
            FROM AsyncJob__c
            WHERE Status__c = :AsyncJobConstants.STATUS.QUEUED
            AND ScheduleTime__c <= :Datetime.now()
            AND AreExecutionLimitsReached__c = FALSE
        ]);
    }

    public void execute(Database.BatchableContext context, List<AsyncJob__c> jobs) {
        List<AsyncJob__c> jobsToExecute = new List<AsyncJob__c>();

        for (AsyncJob__c job : jobs) {
            jobsToExecute.add(new AsyncJob__c(
                Id = job.Id,
                Status__c = AsyncJobConstants.STATUS.IN_PROGRESS
            ));
        }

        update jobsToExecute;
    }

    public void finish(Database.BatchableContext context) {
        String jobName = Test.isRunningTest() ? BATCH_JOB_NAME + '-' + context.getJobId() : BATCH_JOB_NAME;
        AsyncJobService.setBatchJobId(System.scheduleBatch(new AsyncJobBatch(), jobName, 1, BATCH_SIZE));
    }
}