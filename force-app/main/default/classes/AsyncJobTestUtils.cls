@IsTest
public without sharing class AsyncJobTestUtils {

    public static void executeAsync(String jobName) {
        AsyncJob__c job = findFirstQueuedJobByActionName(jobName);

        if (job == null) {
            throw new AsyncJobException('No queued job found for action name: ' + jobName);
        }

        AsyncJobInvokable.executeAsync(job.Id);
    }

    public static AsyncJob__c findFirstQueuedJobByActionName(String jobName) {
        List<AsyncJob__c> jobs = findJobsByActionName(jobName);

        for (AsyncJob__c job : jobs) {
            if (job.Status__c == AsyncJobConstants.STATUS.QUEUED) {
                return job;
            }
        }

        return null;
    }

    public static AsyncJob__c findFirstJobByActionName(String jobName) {
        List<AsyncJob__c> jobs = findJobsByActionName(jobName);

        return jobs.isEmpty() ? null : jobs[0];
    }

    public static Boolean hasQueuedJobsByActionName(String jobName) {
        return findFirstQueuedJobByActionName(jobName) != null;
    }

    public static List<AsyncJob__c> findQueuedJobsByActionName(String jobName) {
        List<AsyncJob__c> jobs = findJobsByActionName(jobName);

        for (AsyncJob__c job : jobs) {
            if (job.Status__c == AsyncJobConstants.STATUS.QUEUED) {
                jobs.add(job);
            }
        }

        return jobs;
    }

    public static List<AsyncJob__c> findJobsByActionName(String jobName) {
        return [
            SELECT Id, JobName__c, Status__c, LastExecutionStatus__c, ScheduleTime__c, LastExecutionTime__c, ExecutionCount__c, ResultLog__c
            FROM AsyncJob__c
            WHERE JobName__c = :jobName
        ];
    }

}