public class AccountTriggerHandler {
    public static void handleBeforeInsert(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            acc.Active__c = false;
        }
    }
    public static void createTeamMembers(List<Account> newAccounts) {
        List<SQX_Team_Members__c> teamMembersToInsert = new List<SQX_Team_Members__c>();
        System.debug('Method has been Invoked');
        for (Account acc : newAccounts) {
            // Create Team Member 1
            SQX_Team_Members__c teamMember1 = new SQX_Team_Members__c(
                Account__c = acc.Id,
                Name = 'Team Member 1',
                Contact_Info__c = '',
                Member_Type__c = ''
            );
            teamMembersToInsert.add(teamMember1);
            
            // Create Team Member 2
            SQX_Team_Members__c teamMember2 = new SQX_Team_Members__c(
                Account__c = acc.Id,
                Name = 'Team Member 2',
                Contact_Info__c = '',
                Member_Type__c = ''
            );
            teamMembersToInsert.add(teamMember2);
        }
        insert teamMembersToInsert;
        system.debug('teamMembersToInsert = '+teamMembersToInsert);
    }
    public static void validateTeamMembers(List<Account> accList, Map<Id, Account> oldAccMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accList) {
            if (acc.Active__c && (oldAccMap.get(acc.Id).Active__c != acc.Active__c)) {
                accountIds.add(acc.Id);
            }
        }
        List<SQX_Team_Members__c> teamMembers = [SELECT Id, Name, Member_Type__c, Account__c 
                                                 FROM SQX_Team_Members__c 
                                                 WHERE Account__c IN :accountIds];
        system.debug('teamMembers = '+teamMembers);
        
        Map<Id, Account> accountMap = new Map<Id, Account>(accList);
        for (SQX_Team_Members__c teamMember : teamMembers) {
            Account ac = accountMap.get(teamMember.Account__c);
            // Check if the member type is HR or Admin
            if (teamMember.Member_Type__c != 'HR' && teamMember.Member_Type__c != 'Admin') {
                ac.addError('Cannot activate account without HR and Admin team members.');
            }
        }
    } 
    public static void handleActivation(List<Account> newAccounts, Map<Id, Account> oldAccMap) {
        
        Set<Id> adminIds = new Set<Id>();
        for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Account_Admin']) {
            adminIds.add(psa.AssigneeId);
        }
        
        // Iterate through the accounts being updated
        for (Account acc : newAccounts) {
            // Check if the account is being activated
            if (acc.Active__c && !oldAccMap.get(acc.Id).Active__c) {
                // Check if the user updating the account has the Account_Admin permission set
                if (!adminIds.contains(UserInfo.getUserId())) {
                    acc.addError('Only users with the Account_Admin permission set can activate accounts.');
                }
            }
        }
    }
}