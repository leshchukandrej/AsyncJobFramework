public class AsyncJobResult {

    public AsyncJobStatus status;
    public String message;

    public enum AsyncJobStatus {
        COMPLETED, SUCCESS, RETRY_LATER, FAILED, FATAL_ERROR
    }

    public AsyncJobResult(AsyncJobStatus status) {
        this(status, null);
    }

    public AsyncJobResult(AsyncJobStatus status, String message) {
        this.status = status;
        this.message = message;
    }

    public static AsyncJobResult toCompletedResult(String message) {
        return new AsyncJobResult(AsyncJobStatus.COMPLETED, message);
    }

    public static AsyncJobResult toSuccessResult(String message) {
        return new AsyncJobResult(AsyncJobStatus.SUCCESS, message);
    }

    public static AsyncJobResult toFailedResult(String message) {
        return new AsyncJobResult(AsyncJobStatus.FAILED, message);
    }

    public static AsyncJobResult toRetryLaterResult(String message) {
        return new AsyncJobResult(AsyncJobStatus.RETRY_LATER, message);
    }

    public static AsyncJobResult toFatalErrorResult(String message) {
        return new AsyncJobResult(AsyncJobStatus.FATAL_ERROR, message);
    }
}