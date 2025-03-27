public without sharing class AsyncJobConstants {

    public static AsyncJobStatus STATUS {
        get {
            return STATUS == null ? STATUS = new AsyncJobStatus() : STATUS;
        }
        private set;
    }

    public class AsyncJobStatus {
        public final String HOLD = 'Hold';
        public final String QUEUED = 'Queued';
        public final String IN_PROGRESS = 'In Progress';
        public final String COMPLETED = 'Completed';
        public final String FAILED = 'Failed';
    }
}
