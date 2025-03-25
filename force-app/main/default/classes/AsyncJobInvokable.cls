public without sharing class AsyncJobInvokable {
 
    @InvocableMethod(label='Execute Async Job' description='Execute an Async Job')
    public static void invoke(List<Id> jobIds) {
        Set<Id> asyncJobIds = new Set<Id>(jobIds);
        asyncJobIds.removeAll(executeWherePossible(asyncJobIds));
        AsyncJobService.restartExeutionProcess(asyncJobIds);
    }

    private static Set<Id> executeWherePossible(Set<Id> asyncJobIds) {
        Set<Id> executedJobIds = new Set<Id>();

        for (Id asyncJobId : asyncJobIds) {
            if (System.Limits.getLimitFutureCalls() - 1 > System.Limits.getFutureCalls()) {
                executeAsync(asyncJobId);
                executedJobIds.add(asyncJobId);
            } else {
                break;
            }
        }

        return executedJobIds;
    }
    
    @Future(Callout=true) @TestVisible
    private static void executeAsync(Id asyncJobId) {
        AsyncJobExecutor.executeNow(asyncJobId);
    }
}