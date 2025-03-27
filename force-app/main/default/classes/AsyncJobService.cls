public without sharing class AsyncJobService {

    @TestVisible
    private static String CACHE_PARTITION_NAME = 'local.AsyncJobBatchId';
    private static String CACHE_KEY_ACTIVE_JOB_BATCH_ID = 'activeJobBatchId';

    public static final List<String> ACTIVE_JOB_STATUSES = new List<String>{
        AsyncJobConstants.STATUS.QUEUED,
        AsyncJobConstants.STATUS.IN_PROGRESS
    };

    @TestVisible
    private static Map<String, String> mockAsyncJobHandlerByJobName;


    //ToDO add logic to work with cache on ASyncJobBatchId
    public static Boolean isBatchJobActive() {
        try {
            Cache.OrgPartition cachePart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
            return (Id) cachePart.get(CACHE_KEY_ACTIVE_JOB_BATCH_ID) != null;
        } catch (Exception ex) {
            return false;
        }
    }

    //ToDO add logic to work with cache on ASyncJobBatchId
    public static void setBatchJobId(String batchJobId) {
        try {
            Cache.OrgPartition cachePart = Cache.Org.getPartition(CACHE_PARTITION_NAME);
            cachePart.put(CACHE_KEY_ACTIVE_JOB_BATCH_ID, batchJobId);
        } catch (Exception ex) {
        }
    }

    @Future
    public static void restartExecutionProcessAsync(Set<Id> jobIds) {
        updateStatus(jobIds, AsyncJobConstants.STATUS.HOLD);
        updateStatus(jobIds, AsyncJobConstants.STATUS.IN_PROGRESS);
    }

    public AsyncJobHandler toAsyncJobHandler(AsyncJob__c job) {
        String asyncJobHanderClass = getAsyncJobHandlerClass(job.JobName__c);

        if (asyncJobHanderClass == null) {
            throw new AsyncJobException('Active Async job handler class not found for job: ' + job.JobName__c);
        }

        Type handlerType = Type.forName(asyncJobHanderClass);

        if (handlerType == null) {
            throw new AsyncJobException('Async Job handler class "' + asyncJobHanderClass + '" not exist for job: ' + job.JobName__c);
        }

        AsyncJobHandler.jobId = job.Id;
        AsyncJobHandler.createdById = job.CreatedById;

        AsyncJobHandler handler = (AsyncJobHandler) handlerType.newInstance();

        handler.apexClassName = asyncJobHanderClass;
        handler.isRecursive = job.IsRecursive__c;
        handler.createdDate = job.CreatedDate;
        handler.lastExecutionTime = job.LastExecutionTime__c;
        handler.lastExecutionStatus = job.LastExecutionStatus__c;
        handler.executionCount = (Integer) job.ExecutionCount__c;
        handler.maxExecutionCount = (Integer) job.MaxExecutionCount__c;

        handler.setParams(job.Params__c);

        return handler;
    }

    private static void updateStatus(Set<Id> jobIds, String status) {
        List<AsyncJob__c> asyncJobs = new List<AsyncJob__c>();

        for (Id jobId : jobIds) {
            asyncJobs.add(new AsyncJob__c(
                Id = jobId,
                Status__c = status
            ));
        }

        Database.update(asyncJobs, false);
    }

    private String getAsyncJobHandlerClass(String jobName) {
        if (String.isBlank(jobName)) {
            return null;
        }

        if (mockAsyncJobHandlerByJobName != null) {
            return mockAsyncJobHandlerByJobName.get(jobName);
        }

        List<AsyncJobAction__mdt> jobActions = [SELECT Id, AsyncJobHandler__c FROM AsyncJobAction__mdt WHERE JobName__c = :jobName and IsActive__c = TRUE LIMIT 1];

        return jobActions.isEmpty() ? null : jobActions[0].AsyncJobHandler__c;
    }
}