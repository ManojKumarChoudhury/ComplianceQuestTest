@isTest
public class testCheckEverydaytask_Manoj {
    @testSetUp
    static void testData(){
        compliancequest__SQX_Part__c part = new compliancequest__SQX_Part__c(Name = 'Chip', compliancequest__Active__c = True, compliancequest__Part_Number__c = '1234');
        insert part;
        
        Product2 pro = new Product2(Name = 'prd1', ProductCode = '1234', IsActive = True);
        insert pro;
    }
	@isTest
    static void dailyRunTest(){
        List<compliancequest__SQX_Part__c> ptList = [Select Id, compliancequest__Active__c, compliancequest_SQX_Product__c, Name From compliancequest__SQX_Part__c ];
        List<Product2> prList = [Select Id, (Select Id, compliancequest__Active__c ,compliancequest_SQX_Product__c From compliancequest__SQX_Parts__r) From Product2];
        
        Test.startTest();
        CheckEverydaytask_Manoj job = new CheckEverydaytask_Manoj();
        System.enqueueJob(job);
        Test.stopTest();
        
        ptList = [Select Id, compliancequest__Active__c, compliancequest_SQX_Product__c, Name From compliancequest__SQX_Part__c ];
        System.assertEquals(True, ptList[0].compliancequest__Active__c, 'Part should be Active');
        System.assertNotEquals(null, ptList[0].compliancequest_SQX_Product__c, 'Product should be linked to the part');
    }
}