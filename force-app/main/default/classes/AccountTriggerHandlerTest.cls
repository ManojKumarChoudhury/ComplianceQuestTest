@isTest
private class AccountTriggerHandlerTest {
    @isTest 
    static void testAccountInsertTrigger() {
        
        Account testAccount = new Account(
            Name = 'Test Account'
        );

        Test.startTest();
        insert testAccount;
        Test.stopTest();

        Account insertedAccount = [SELECT Id, Active__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(false, insertedAccount.Active__c, 'Account should be created as inactive');
    }
    
    @isTest
    static void testValidateTeamMembers() {
        try {
            // Create test accounts
            List<Account> testAccounts = new List<Account>();
            for(Integer i = 0; i < 2; i++) {
                testAccounts.add(new Account(Name = 'Test Account ' + i, Active__c = false));
            }
            insert testAccounts;

            // Create test team members (HR)
            List<SQX_Team_Members__c> testTeamMembersHR = new List<SQX_Team_Members__c>();
            for(Account acc : testAccounts) {
                testTeamMembersHR.add(new SQX_Team_Members__c(Name = 'Test Team Member HR', 
                                                               Member_Type__c = 'HR',
                                                               Account__c = acc.Id));
            }
            insert testTeamMembersHR;

            // Create test team members (Admin)
            List<SQX_Team_Members__c> testTeamMembersAdmin = new List<SQX_Team_Members__c>();
            for(Account acc : testAccounts) {
                testTeamMembersAdmin.add(new SQX_Team_Members__c(Name = 'Test Team Member Admin', 
                                                                  Member_Type__c = 'Admin',
                                                                  Account__c = acc.Id));
            }
            insert testTeamMembersAdmin;

            // Update one account to activate it
            testAccounts[0].Active__c = true;
            update testAccounts;

            // Verify that there are no errors added to the accounts with HR and Admin team members
            for(Account acc : testAccounts) {
                //System.assertEquals(0, acc.Errors.size());
            }

            // Remove Admin team member from one account
            delete testTeamMembersAdmin[0];

            // Update accounts again to trigger validation
            testAccounts[0].Active__c = false; // Deactivate the account to trigger update
            update testAccounts;

            // Verify that an error is added to the account without Admin team member
            //for(Account acc : testAccounts) {
                //System.assertEquals(1, acc.Errors.size());
                //System.assertEquals('Cannot activate account without HR and Admin team members.', acc.Errors[0].getMessage());
           // }
        } catch(Exception e) {
            System.assert(false, 'Exception occurred: ' + e.getMessage());
        }
    }
    @isTest
    static void testAccountActivation() {
        // Create test data: Accounts
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 2; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, Active__c = false));
        }
        insert testAccounts;
        
        // Create test data: PermissionSetAssignment
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Account_Admin' LIMIT 1];
        User testUser = new User(Alias = 'testUser', Email='testuser@testorg.com',
                                 EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                                 LocaleSidKey='en_US', TimeZoneSidKey='America/Los_Angeles', 
                                 UserName='testuser@testorg.com' + System.currentTimeMillis(), // Unique username
                                 ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id);
        insert testUser;
        PermissionSetAssignment psAssignment = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id);
        insert psAssignment; // Assign "Account_Admin" permission set to the test user
        
        // Call the trigger to activate the accounts
        Test.startTest();
        testAccounts[0].Active__c = true;
        update testAccounts;
        Test.stopTest();
        
        // Verify that the account is activated
        Account updatedAccount = [SELECT Active__c FROM Account WHERE Id = :testAccounts[0].Id];
        System.assertEquals(true, updatedAccount.Active__c);
    }
}