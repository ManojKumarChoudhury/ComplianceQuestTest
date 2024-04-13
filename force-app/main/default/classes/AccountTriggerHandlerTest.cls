@isTest
private class AccountTriggerHandlerTest {

    // Define common test data in @testSetup method
    @testSetup
    static void setupTestData() {
        // Create Test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Set member types for team members
        List<SQX_Team_Members__c> teamMembers = [SELECT Id, Name, Account__c, Member_Type__c FROM SQX_Team_Members__c WHERE Account__c = :testAccount.Id];
        teamMembers[0].Member_Type__c = 'HR';
        teamMembers[1].Member_Type__c = 'Admin';
        update teamMembers;
        
        // Create a user without the Account_Admin permission set
        User nonAdminUser = new User(Alias = 'nonadmin', Email='nonadmin@test.com', 
                                     EmailEncodingKey='UTF-8', LastName='Testing', 
                                     LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                                     ProfileId = UserInfo.getProfileId(), UserName='nonadminunique@test.com',
                                     TimeZoneSidKey='America/Los_Angeles');
        insert nonAdminUser;

        // Create a user with the Account_Admin permission set
        User adminUser = new User(Alias = 'admin', Email='admin@test.com', 
                                  EmailEncodingKey='UTF-8', LastName='Testing', 
                                  LanguageLocaleKey='en_US', LocaleSidKey='en_US', 
                                  ProfileId = UserInfo.getProfileId(), UserName='adminunique@test.com',
                                  TimeZoneSidKey='America/Los_Angeles');
        insert adminUser;
        
        // Assign the Account_Admin permission set asynchronously
        assignPermissionSet(adminUser.Id, 'Account_Admin');
    }

    // Test for validating the behavior of the account insertion trigger
    @isTest 
    static void testAccountInsertTrigger() {
        // Verify that account is created as inactive
        Account insertedAccount = [SELECT Id, Active__c FROM Account WHERE Name = 'Test Account'];
        System.assertEquals(false, insertedAccount.Active__c, 'Account should be created as inactive');
        
        // Verify that two team members are created for the account
        List<SQX_Team_Members__c> teamMembers = [SELECT Id, Name, Account__c FROM SQX_Team_Members__c WHERE Account__c = :insertedAccount.Id];
        System.assertEquals(2, teamMembers.size(), 'Two team members should be created for the account');
        System.assertEquals('Team Member 1', teamMembers[0].Name, 'First team member name should be "Team Member 1"');
        System.assertEquals('Team Member 2', teamMembers[1].Name, 'Second team member name should be "Team Member 2"');
    }

    // Test for validating the behavior of updating account status when team members are present
    @isTest 
    static void testValidateTeamMembers() {
        // Activate the account
        Account acc = [SELECT Id, Active__c FROM Account WHERE Name = 'Test Account'];
        acc.Active__c = true;
        update acc;
        
        // Verify that account is active
        Account updatedAcc = [SELECT Id, Active__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, updatedAcc.Active__c, 'Account should be active');
    }

    // Negative test for validating team members when required team members are missing
    @isTest 
    static void testNegValidateTeamMembers() {
        // Deactivate account if both HR and Admin team members are not present
        Account acc = [SELECT Id, Active__c FROM Account WHERE Name = 'Test Account'];
        SQX_Team_Members__c adminMember = [SELECT Id, Member_Type__c FROM SQX_Team_Members__c WHERE Account__c = :acc.Id AND Member_Type__c = 'Admin' LIMIT 1];
        adminMember.Member_Type__c = 'sales';
        update adminMember;

        // Verify that account remains inactive
        try {
            acc.Active__c = true;
            update acc;
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot activate account without both HR and Admin team members'));
        }
        
        Account updatedAcc = [SELECT Id, Active__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, updatedAcc.Active__c, 'Account should remain inactive');
    }

    // Negative test for handling account activation when a not assigned permission set user tries to activate the account
    @isTest 
    static void testHandleActivation_Negative() {
        // Verify that only users with Account_Admin permission set can activate accounts
        Account acc = [SELECT Id, Active__c FROM Account WHERE Name = 'Test Account'];
        
        User nonAdminUser = [SELECT Id FROM User WHERE Alias = 'nonadmin'];
        System.runAs(nonAdminUser) {
            try {
                acc.Active__c = true;
                update acc;
            } catch (Exception e) {
                System.assert(e.getMessage().contains('Only users with the Account_Admin permission set can activate accounts.'));
            }
        }
        
        // Verify that account remains inactive
        Account updatedAcc = [SELECT Id, Active__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, updatedAcc.Active__c, 'Account should remain inactive');
    }

    // Positive test for handling account activation
    @isTest 
    static void testHandleActivation_Positive() {
        // Verify that users with Account_Admin permission set can activate accounts
        Account acc = [SELECT Id, Active__c FROM Account WHERE Name = 'Test Account'];
        
        User adminUser = [SELECT Id FROM User WHERE Alias = 'admin'];
        
        // Assign permission set and activate account
        Test.startTest();
        assignPermissionSet(adminUser.Id, 'Account_Admin');
        Test.stopTest();
        
        System.runAs(adminUser) {
            acc.Active__c = true;
            update acc;
        }
        
        // Verify that account is active
        Account updatedAcc = [SELECT Id, Active__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, updatedAcc.Active__c, 'Account should be active');
    }
        
    // Asynchronous method to assign permission set
    @future
    public static void assignPermissionSet(Id userId, String permSetName) {
        // Query existing PermissionSetAssignment
        List<PermissionSetAssignment> existingAssignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = :permSetName LIMIT 1];
        
        // Check if there's an existing assignment
        if (existingAssignments.isEmpty()) {
            // If no existing assignment found, insert a new one
            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = :permSetName];
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
            insert psa;
        }
    }
}