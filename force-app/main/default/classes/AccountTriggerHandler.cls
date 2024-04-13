public class AccountTriggerHandler {
    
    /**
     * Handles logic before inserting new accounts.
     * Sets the 'Active__c' field to false for all new accounts.
     */
    public static void handleBeforeInsert(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            acc.Active__c = false;
        }
    }
    
    /**
     * Creates team members for new accounts.
     * Inserts two default team members ('Team Member 1' and 'Team Member 2') for each new account.
     */
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
    
    /**
     * Validates team members for accounts being updated to active.
     * Checks if each account has both HR and Admin team members before activation.
     */
    public static void validateTeamMembers(List<Account> accList, Map<Id, Account> oldAccMap) {
        Set<Id> accountIds = new Set<Id>();
        
        // Collect IDs of accounts that have been updated to active
        for (Account acc : accList) {
            if (acc.Active__c && (oldAccMap.get(acc.Id).Active__c != acc.Active__c)) {
                accountIds.add(acc.Id);
            }
        }
        
        // Query team members related to the accounts
        List<SQX_Team_Members__c> teamMembers = [SELECT Id, Name, Member_Type__c, Account__c 
                                                 FROM SQX_Team_Members__c 
                                                 WHERE Account__c IN :accountIds];
        
        // Map to store account IDs and their corresponding team members
        Map<Id, Set<String>> accountTeamMembers = new Map<Id, Set<String>>();
        
        // Populate the map with the member types for each account
        for (SQX_Team_Members__c teamMember : teamMembers) {
            if (!accountTeamMembers.containsKey(teamMember.Account__c)) {
                accountTeamMembers.put(teamMember.Account__c, new Set<String>());
            }
            accountTeamMembers.get(teamMember.Account__c).add(teamMember.Member_Type__c);
        }
        
        // Iterate through the accounts and check if they have both HR and Admin team members
        for (Account acc : accList) {
            if (accountIds.contains(acc.Id)) {
                Set<String> members = accountTeamMembers.get(acc.Id);
                if (!members.contains('HR') || !members.contains('Admin')) {
                    acc.addError('Cannot activate account without both HR and Admin team members.');
                }
            }
        }
    }
    
    /**
     * Handles activation of accounts.
     * Checks if users updating accounts to active have the Account_Admin permission set.
     */
    public static void handleActivation(List<Account> newAccounts, Map<Id, Account> oldAccMap) {
        // Retrieve IDs of users with the Account_Admin permission set
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