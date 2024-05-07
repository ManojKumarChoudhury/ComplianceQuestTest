public class ScheduleDailyTask_Manoj implements Schedulable{
    public void execute(SchedulableContext context) {
        List<PermissionSetAssignment> assignedUsers = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'CQ Admin'];
        List<Id> userIds = new List<Id>();
        for(PermissionSetAssignment a : assignedUsers)
        {
            userIds.add(a.AssigneeId);
        }
        List<User> usList = [SELECT Id, Profile.Name FROM User WHERE Profile.Name = 'System Administrator' And Id IN :userIds];
        if(!usList.isEmpty()){
            system.enqueueJob(new CheckEverydaytask_Manoj());
        }   
    }
}

/*
ScheduleDailyTask_Manoj dailyRun = new ScheduleDailyTask_Manoj();
String sch = '0 0 6 * ? *';  // run class daily at 6 AM
String jobID = System.schedule('Check Product', sch, dailyRun);
*/