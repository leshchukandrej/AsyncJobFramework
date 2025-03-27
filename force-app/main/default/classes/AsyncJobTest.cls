@IsTest
public class AsyncJobTest {

    private static final String ACTION = 'DummyAction';
    private static final String ACTION_WITH_EXCEPTION = 'DummyActionWithException';
    private static final STRING ACTION_NON_EXISTING = 'DummyActionNonExisting';

    static {
        AsyncJobService.mockAsyncJobHandlerByJobName = new Map<String, String>{
            ACTION => DummyActionAsyncJobHandler.class.getName(),
            ACTION_WITH_EXCEPTION => DummyActionWithExceptionAsyncJobHandler.class.getName(),
            ACTION_NON_EXISTING => 'AsyncJobTest.NonExistingClass'
        };
    }

    @IsTest
    static void test_batch_execution() {
        insertAsyncJobs(ACTION, AsyncJobResult.AsyncJobStatus.SUCCESS);

        Test.startTest();
        AsyncJobBatch.startJob();
        Test.stopTest();

        assertJobExecutions(ACTION, AsyncJobConstants.STATUS.IN_PROGRESS, 0);
    }

    @IsTest
    static void test_invokable_execution_when_success() {
        Set<Id> jobIds = insertAsyncJobs(ACTION, AsyncJobResult.AsyncJobStatus.SUCCESS);

        Test.startTest();
        AsyncJobInvokable.invoke(new List<Id>(jobIds));
        Test.stopTest();

        assertJobExecutions(ACTION, AsyncJobConstants.STATUS.COMPLETED, 1);
    }

    @IsTest
    static void test_invokable_execution_when_failed() {
        Set<Id> jobIds = insertAsyncJobs(ACTION, AsyncJobResult.AsyncJobStatus.FAILED);

        Test.startTest();
        AsyncJobInvokable.invoke(new List<Id>(jobIds));
        Test.stopTest();

        assertJobExecutions(ACTION, AsyncJobConstants.STATUS.FAILED, 1);
    }

    @IsTest
    static void test_invokable_execution_when_retry_later() {
        Set<Id> jobIds = insertAsyncJobs(ACTION, AsyncJobResult.AsyncJobStatus.RETRY_LATER);

        Test.startTest();
        AsyncJobInvokable.invoke(new List<Id>(jobIds));
        Test.stopTest();

        assertJobExecutions(ACTION, AsyncJobConstants.STATUS.QUEUED, 1);
    }

    @IsTest
    static void test_invokable_execution_when_completed() {
        Set<Id> jobIds = insertAsyncJobs(ACTION, AsyncJobResult.AsyncJobStatus.COMPLETED);

        Test.startTest();
        AsyncJobInvokable.invoke(new List<Id>(jobIds));
        Test.stopTest();

        assertJobExecutions(ACTION, AsyncJobConstants.STATUS.COMPLETED, 1);
    }

    @IsTest
    static void test_invokable_execution_when_error_not_handled() {
        Set<Id> jobIds = insertAsyncJobs(ACTION_WITH_EXCEPTION, AsyncJobResult.AsyncJobStatus.SUCCESS);

        Test.startTest();
        AsyncJobInvokable.invoke(new List<Id>(jobIds));
        Test.stopTest();


        assertJobExecutions(ACTION_WITH_EXCEPTION, AsyncJobConstants.STATUS.FAILED, 1);
    }

    @IsTest
    static void test_invokable_execution_when_no_handler_found() {
        Set<Id> jobIds = insertAsyncJobs(ACTION_NON_EXISTING, AsyncJobResult.AsyncJobStatus.SUCCESS);

        Test.startTest();
        AsyncJobInvokable.invoke(new List<Id>(jobIds));
        Test.stopTest();

        assertJobExecutions(ACTION_NON_EXISTING, AsyncJobConstants.STATUS.FAILED, 1);
    }

    @IsTest
    static void test_recursive_execution() {
        AsyncJob__c job = new AsyncJobBuilder(ACTION)
            .setParams(new Map<String, Object>{
                'status' => AsyncJobResult.AsyncJobStatus.SUCCESS
            })
            .setScheduleTime(DateTime.now())
            .makeRecursive()
            .build();

        insert job;

        Test.startTest();
        AsyncJobInvokable.invoke(new List<Id>{job.Id});
        Test.stopTest();

        assertJobExecutions(ACTION, AsyncJobConstants.STATUS.QUEUED, 1);
    }

    @IsTest
    static void cover_exception_classes() {
        AsyncJobException.doNothing();
        AsyncJobFatalException.doNothing();
    }

    @IsTest
    static void cover_job_builder() {
        new AsyncJobBuilder(ACTION)
            .setParams(new Map<String, Object>{
                'status' => AsyncJobResult.AsyncJobStatus.SUCCESS
            })
            .setScheduleTime(DateTime.now())
            .setRetryInterval(5)
            .setMaxExecutionCount(10)
            .makeRecursive()
            .build();
    }

    @IsTest
    static void cover_async_job_result() {
        AsyncJobResult.toSuccessResult('message');
        AsyncJobResult.toCompletedResult('message');
        AsyncJobResult.toFailedResult('message');
        AsyncJobResult.toRetryLaterResult('message');
        AsyncJobResult.toFatalErrorResult('message');
    }


    static Set<Id> insertAsyncJobs(String actionName, AsyncJobResult.AsyncJobStatus status) {
        List<AsyncJob__c> jobs = new List<AsyncJob__c>();
        for (Integer i = 0; i < 49; i++) {
            jobs.add(
                new AsyncJobBuilder(actionName)
                    .setParams(new Map<String, Object>{
                        'status' => status
                    })
                    .setScheduleTime(DateTime.now())
                    .build()
            );
        }
        insert jobs;
        return new Map<id, AsyncJob__c>(jobs).keySet();
    }

    static void assertJobExecutions(String actionName, String expectedStatus, Integer expectedExecutionCount) {
        for (AsyncJob__c job : AsyncJobTestUtils.findJobsByActionName(actionName)) {
            assertJobExecution(job, expectedStatus, expectedExecutionCount);
        }
    }

    static void assertJobExecution(AsyncJob__c job, String expectedStatus, Integer expectedExecutionCount) {
        Assert.areEqual(expectedStatus, job.Status__c, 'Status should be ' + expectedStatus);
        Assert.areEqual(expectedExecutionCount, job.ExecutionCount__c, 'Execution count should be ' + expectedExecutionCount);
    }


    public class DummyActionAsyncJobHandler extends AsyncJobHandler {

        public DummyActionParams params;

        public override void setParams(String params) {
            this.params = (DummyActionParams) JSON.deserialize(params, DummyActionParams.class);
        }

        public override AsyncJobResult execute() {
            return new AsyncJobResult(params.status);
        }
    }

    public class DummyActionWithExceptionAsyncJobHandler extends AsyncJobHandler {
        public override AsyncJobResult execute() {
            throw new AsyncJobException('Expected excpetion thrown');
        }
    }

    public class DummyActionParams {
        public AsyncJobResult.AsyncJobStatus status;
    }


}