# AsyncJob Framework

## Overview

The AsyncJob Framework is a robust, flexible system for handling asynchronous job processing in Salesforce. It provides a structured way to execute background operations, track their progress, and manage their lifecycle.

## Key Features

- **Asynchronous Processing**: Execute operations in the background without blocking user interaction
- **Job Scheduling**: Schedule jobs for immediate or future execution
- **Progress Tracking**: Monitor job execution status and progress
- **Retry Mechanism**: Automatically retry failed jobs based on configuration
- **Error Handling**: Comprehensive error handling and logging
- **Recursive Jobs**: Support for jobs that need to execute repeatedly

## Installation

1. Deploy the components to your Salesforce org
2. Configure Custom Metadata records for your job handlers
3. Set up the scheduled batch process using AsyncJobBatch

## Configuration

### Custom Metadata Configuration

The framework uses `AsyncJobAction__mdt` custom metadata records to map job names to their handler implementations:

1. Navigate to **Setup** > **Custom Metadata Types** > **Async Job Action**
2. Create a new record with:
   - **Job Name**: A unique identifier for your job type (e.g., "EmailSender")
   - **Async Job Handler**: The Apex class name that implements the job logic (e.g., "EmailSenderJobHandler")
   - **Is Active**: Set to true to enable the job type

This configuration allows you to dynamically map job names to their handlers without changing code.

### Job Handler Implementation

Create a class that extends `AsyncJobHandler` to implement your job logic:

```java
public class YourJobHandler extends AsyncJobHandler {
    // Define your parameters class
    private YourParams params;
    
    // Override to deserialize your parameters
    public override void setParams(String params) {
        this.params = (YourParams) JSON.deserialize(params, YourParams.class);
    }
    
    // Implement the actual job execution
    public override AsyncJobResult execute() {
        try {
            // Your job logic here
            
            // Return appropriate status
            return AsyncJobResult.toSuccessResult('Job completed successfully');
        } catch (Exception e) {
            return AsyncJobResult.toFailedResult(e.getMessage());
        }
    }
    
    // Optional: Define a parameters class
    public class YourParams {
        public String someField;
        public Integer someValue;
    }
}
```

## Job Execution Approaches

The framework supports two main approaches for job execution:

### 1. Immediate Execution

When a job needs to execute immediately, the framework automatically sets its status to "In Progress":

```java
// For immediate execution
AsyncJob__c job = new AsyncJobBuilder('YourJobName')
    .setParams(new Map<String, Object>{'param1' => 'value1'})
    // No scheduleTime means execute immediately
    .build();
    
insert job;
```

The `AsyncJobBuilder` automatically sets the status to `In Progress` when no schedule time is provided, triggering immediate execution through the record-triggered flow.

### 2. Scheduled Execution

For future execution, specify a schedule time:

```java
// For scheduled execution
AsyncJob__c job = new AsyncJobBuilder('YourJobName')
    .setParams(new Map<String, Object>{'param1' => 'value1'})
    .setScheduleTime(DateTime.now().addMinutes(30))
    .build();
    
insert job;
```

The job will remain in "Queued" status until the batch process picks it up at the scheduled time.

### Triggered Flow Execution

When a job status is set to "In Progress" (either manually or automatically), a record-triggered flow (`AsyncJob_ExecuteInProgressJobs`) executes the job logic:

1. The flow is triggered when an AsyncJob record status changes to "In Progress"
2. It calls the `AsyncJobInvokable` Apex action to execute the job
3. The `AsyncJobInvokable` class uses future methods to process the job asynchronously
4. The `AsyncJobExecutor` handles the actual job execution through the appropriate handler

## Job Status Lifecycle

Jobs progress through the following statuses:

1. **Queued**: Initial status for scheduled jobs
2. **In Progress**: Job is currently executing
3. **Completed**: Job completed successfully
4. **Failed**: Job failed and exceeded retry attempts
5. **Hold**: Job is on hold (manually set)

## Advanced Configuration

### Recursive Jobs

For jobs that need to run repeatedly:

```java
AsyncJob__c job = new AsyncJobBuilder('YourJobName')
    .setParams(new Map<String, Object>{'param1' => 'value1'})
    .setIsRecursive(true)
    .setRetryInterval(15) // Minutes between executions
    .build();
```

### Retry Configuration

Configure retry behavior for failed jobs:

```java
AsyncJob__c job = new AsyncJobBuilder('YourJobName')
    .setParams(new Map<String, Object>{'param1' => 'value1'})
    .setMaxExecutionCount(5) // Max number of attempts
    .setRetryInterval(5) // Minutes between retry attempts
    .build();
```

## Best Practices

1. Keep job handlers focused on a single responsibility
2. Use appropriate return statuses based on execution results
3. Set realistic retry intervals and max execution counts
4. Include meaningful status messages for logging
5. Design job parameters to be serializable/deserializable
6. Consider parent-child relationships for dependent jobs

## Troubleshooting

- Check job status and result logs in the AsyncJob__c object
- Verify that your job name matches a valid AsyncJobAction__mdt record
- Ensure your handler class is correctly implemented and accessible
- Review execution logs for errors during job processing

## Examples

See `AsyncJobTest.cls` for examples of how to create and execute jobs.
